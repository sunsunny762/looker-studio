import { BlobServiceClient, BlockBlobClient, ContainerSASPermissions, generateBlobSASQueryParameters, SASProtocol, StorageSharedKeyCredential } from '@azure/storage-blob';
import { Injectable, Logger } from '@nestjs/common';
//import { promises as fs } from 'fs';
import fs, { promises as fsp} from 'fs';
import path from 'path';
import * as handleBars from 'handlebars';
import { DatabaseService } from '../database';
import { AzConfig, FileUploadRequest, FileUploadResult, IDocument, IDocumentSave, IDocumentUpload, IPreviewPages } from './model';
import * as mssql from 'mssql';
import { IDbInputParamter } from '../database/model/db-input-parameter';
import { v4 as uuidv4 } from 'uuid';
import { ApplicationUser } from '../account/model';
//import { NotificationsService, SystemNotificationMessage } from '../shared';
import fetch from 'node-fetch';
import {format} from 'date-fns';
import { Jimp } from "jimp";
import * as sharp from 'sharp'

class IngressOptions {
    perProcessingPause: number|undefined;
}
class FileInfo {
    size: number;
    path: string;
    filename: string;
    mimetype: string;
}

@Injectable()
export class DocumentsService {
    private readonly logger = new Logger(DocumentsService.name);
    private _directory: string;
    private _archiveDirectory: string;
    private blobServiceClient: BlobServiceClient;

    constructor(private readonly databaseService: DatabaseService) {
        const accountName = process.env.STORAGE_ACCOUNT_NAME;
        const accountKey = process.env.STORAGE_ACCOUNT_KEY;

        const sharedKeyCredential = new StorageSharedKeyCredential(accountName, accountKey);
        const blobUrl = `https://${accountName}.blob.core.windows.net`;

        this.blobServiceClient = new BlobServiceClient(blobUrl, sharedKeyCredential);
    }
    
    public async initialise(directory: string): Promise<void> {
        this._directory = directory;
        await this.ensurePath(this._directory);
        await this.ensurePath(this._archiveDirectory);

        this.logger.log(`Monitoring for document ingress: ${this._directory}`);
        // Watch for files to import and process as and when detected
        const watcher = fs.watch(this._directory);
        watcher.on('change', (event, filename) => {
            if (event == "change" && typeof filename == "string") {
                this._ingressFile(this._directory, filename, { perProcessingPause: 5 });
            }
        });    
    }

    public async uploadFile(file: Express.Multer.File, request: FileUploadRequest, user?: ApplicationUser) : Promise<any> {
        this.logger.log('Uploading file');
        if(!file) {
            return undefined;
        }
        const prefix: string = request.parentEntityId && request.parentEntityType ? `${request.parentEntityType}-${request.parentEntityId}` : 'generic'
        const blobName: string = `${prefix}-${uuidv4().toLowerCase()}`;
        const container: string = request.container ? request.container : (request.customerId ? `customer-${request.customerId}` : 'unclassified');
        return await this._processFile({ ...file, filename: file?.path }, request, blobName, container, user?.uid);
    }

    public async uploadLocalFile(fileName: string, request: FileUploadRequest): Promise<any> {
        this.logger.log('Uploading Local file');

         // Extract the base64 string without the data URL prefix
        const filePath = './data/'+fileName;
        const fileBuffer = await fsp.readFile(filePath); //fs.readFileSync(filePath);

        const file: Express.Multer.File = {
            buffer: fileBuffer,
            mimetype: request.mimeType,
            originalname: fileName,
            fieldname: 'file',
            size: fileBuffer.length,
            path: filePath,
            encoding: '7bit',
            stream: undefined,
            destination: './data',
            filename: fileName,
        };

        return await this.uploadFile(file, request);
    }

    public async uploadBase64File(base64Data: string, request: FileUploadRequest): Promise<any> {
        this.logger.log('Uploading base64 file');
    
        if (!base64Data) {
            return undefined;
        }

         // Extract the base64 string without the data URL prefix
        const base64String = this._stripBase64Header(base64Data);
    
        const buffer = Buffer.from(base64String, 'base64');
        const mimeType = this._getMimeType(base64Data);
        const extension = mimeType ? this._getExtensionFromMimeType(mimeType) : 'jpg'; 
        const filename = `upload-${uuidv4()}.${extension}`;
        const filePath = './uploads/'+filename;
    
        await fsp.writeFile(filePath, buffer);
    
        const file: Express.Multer.File = {
            buffer,
            mimetype: mimeType,
            originalname: filename,
            fieldname: 'file',
            size: buffer.length,
            path: filePath,
            encoding: '7bit',
            stream: undefined,
            destination: './uploads',
            filename: filename,
        };

        return await this.uploadFile(file, request);
    }

    /**
     * Upload file directly to public Azure Storage container without database entry
     * @param file - Express.Multer.File object
     * @param containerName - Target container name (should be public)
     * @param customFilename - Optional custom filename (will be appended with UUID)
     * @returns Object with url and blobName
     */
    public async uploadToPublicContainer(
        file: Express.Multer.File,
        containerName: string,
        customFilename?: string
    ): Promise<{ url: string; blobName: string; container: string }> {
        this.logger.log('Uploading file to public container without database entry');
        
        if (!file) {
            throw new Error('No file provided');
        }

        // Generate blob name with UUID
        const fileExtension = file.originalname.split('.').pop();
        const baseFilename = customFilename || file.originalname.replace(`.${fileExtension}`, '');
        const uuid = uuidv4().toLowerCase();
        const blobName = `${baseFilename}-${uuid}${fileExtension ? '.' + fileExtension : ''}`;

        try {
            const sharedKeyCredential = new StorageSharedKeyCredential(
                process.env.STORAGE_ACCOUNT_NAME ?? "",
                process.env.STORAGE_ACCOUNT_KEY ?? ""
            );
            const blobServiceClient = new BlobServiceClient(
                `https://${process.env.STORAGE_ACCOUNT_NAME}.blob.core.windows.net`,
                sharedKeyCredential
            );

            this.logger.log(`Uploading to container ${containerName}, blob ${blobName}`);
            const containerClient = blobServiceClient.getContainerClient(containerName);
            await containerClient.createIfNotExists();

            const blockBlobClient = containerClient.getBlockBlobClient(blobName);

            // Upload using buffer if available, otherwise file path
            if (file.buffer) {
                await blockBlobClient.uploadData(file.buffer, {
                    blobHTTPHeaders: {
                        blobContentType: file.mimetype
                    }
                });
            } else if (file.path) {
                await blockBlobClient.uploadFile(file.path, {
                    blobHTTPHeaders: {
                        blobContentType: file.mimetype
                    }
                });
            } else {
                throw new Error('File has no buffer or path');
            }

            // Generate public URL (if container is public, no SAS token needed)
            const publicUrl = `https://${process.env.STORAGE_ACCOUNT_NAME}.blob.core.windows.net/${containerName}/${blobName}`;

            this.logger.log(`File uploaded successfully: ${publicUrl}`);

            return {
                url: publicUrl,
                blobName: blobName,
                container: containerName
            };
        } catch (error) {
            this.logger.error('Error uploading to public container:', error);
            throw error;
        }
    }
    
    

    private _getMimeType(base64Data: string): string | undefined {
        const match = base64Data.match(/^data:(.+);base64,/);
        return match ? match[1] : undefined;
    }

    private _getExtensionFromMimeType(mimeType: string): string {
        switch (mimeType) {
            case 'image/jpeg': return 'jpg';
            case 'image/png': return 'png';
            case 'image/gif': return 'gif';
            default: return 'jpg';
        }
    }

    private _stripBase64Header(base64Data: string): string {
        return base64Data.replace(/^data:image\/\w+;base64,/, '');
    }
    

    private async _processFile(file: FileInfo|any, request: FileUploadRequest, blobName: string, container: string, userUid?: string): Promise<any> {
        this.logger.log(`Container ${container}, blob ${blobName}, file ${file.filename}`);
        const document = await this.save({
            ...request, 
            size: file.size,
            uid: userUid,
            mimeType: file.mimetype,
            blobName: blobName,
            container: container
        })
        if (!document) {
            return undefined;
        }
        if (request.replaceDocId) {
            if (request.versioningEnabled) {
                await this._deleteAndVersioning(request.replaceDocId, document.id, userUid);
            } else {
                await this.deleteDocument(request);
            }
        }
        if(request.compress && file.mimetype.startsWith('image') && file.size > (500 * 1024)) { // only if filesize if 500Kb
            let result = false;
            if(file.mimetype == 'image/png') {
               result = await this._resizeImageByJimp(file.filename, `${file.filename}-1`);
            } else if(file.mimetype == 'image/jpeg'){
                result = await this._resizeImageBySharp(file.filename, `${file.filename}-1`);
            }
            if(result) {
                fsp.unlink(file.filename);
                file.filename = `${file.filename}-1`;
            }
        }

        // Use buffer upload if buffer is present, otherwise fallback to file path
        let uploadResult;
        if (file.buffer) {
            uploadResult = await this._uploadBufferToBlobStorage({ ...document, fullName: file.filename }, file.buffer);
        } else {
            uploadResult = await this._uploadToBlobStorage({ ...document, fullName: file.filename });
        }
        if (uploadResult.error) {
            return uploadResult;
        }
        return document;
    }
    
    private async _resizeImageBySharp(sourceFile: string, destFile: string) : Promise<boolean> {
        const scale = 1;
        return await new Promise(function(resolve, reject) {
            sharp(`${sourceFile}`)
            .metadata()
            .then((metadata) => {
                sharp(sourceFile)
                .resize({
                    width: Math.round(metadata.width * scale),
                    height: Math.round(metadata.height * scale)
                  })
                .toFile(`${destFile}`)
                .then((data: any) => {
                    resolve(true);
                })
                .catch((err) => {
                    console.log(err);
                    reject(false);
                })
            })
        })
    }

    private async _resizeImageByJimp(sourceFile: string, destFile: string) : Promise<boolean> {
        const scale = 0.8;
        return await new Promise(function(resolve, reject) { 
            Jimp.read(`${sourceFile}`)
            .then((image) => {
                image
                //.resize((image.bitmap?.width) || 512 , (image.bitmap?.height) || 512) // resize
                //.quality(60) // set Image quality
                .scale(scale)
                .write(`${destFile}` as `${string}.${string}`);
                setTimeout(function() {
                    resolve(true);
                }, 1000)
            })
            .catch((err) => {
                console.log(err);
                reject(false);
            });
        })
        
    }

    private async _deleteAndVersioning(replaceDocId: number, newDocId: number, uid?: string) {
        await this.databaseService.execute("[documents].[spDocument_Delete]", [
            { name: "id", type: mssql.TYPES.Int, value: replaceDocId }
        ]);

        await this.databaseService.execute("[documents].[spDocument_CreateVersion]", [
            { name: "documentId", type: mssql.TYPES.Int, value: newDocId },
            { name: "parentDocId", type: mssql.TYPES.Int, value: replaceDocId },
            { name: "uid", type: mssql.TYPES.NVarChar, value: uid },
        ]);
    }

    public async save(documentSaveRequest: IDocumentSave): Promise<IDocument> {
        let parameters: Array<IDbInputParamter> = [
            { name: "parentEntityId", type: mssql.TYPES.Int, value: documentSaveRequest.parentEntityId },
            { name: "parentEntityType", type: mssql.TYPES.NVarChar, value: documentSaveRequest.parentEntityType },
            { name: "customerId", type: mssql.TYPES.Int, value: documentSaveRequest.customerId },
            { name: "container", type: mssql.TYPES.NVarChar, value: documentSaveRequest.container },
            { name: "blobName", type: mssql.TYPES.NVarChar, value: documentSaveRequest.blobName },
            { name: "title", type: mssql.TYPES.NVarChar, value: documentSaveRequest.title },
            { name: "mimeType", type: mssql.TYPES.NVarChar, value: documentSaveRequest.mimeType },
            { name: "size", type: mssql.TYPES.Int, value: documentSaveRequest.size },
            { name: "uid", type: mssql.TYPES.NVarChar, value: documentSaveRequest.uid },
            { name: "singleInstance", type: mssql.TYPES.Bit, value: documentSaveRequest.singleInstance === 'true' || documentSaveRequest.singleInstance === true ? true : false },
            { name: "canEmbed", type: mssql.TYPES.Bit, value: documentSaveRequest.canEmbed === 'true' || documentSaveRequest.canEmbed === true ? true : false },
            { name: "ownerName", type: mssql.TYPES.NVarChar, value: documentSaveRequest.ownerName },
            { name: "reviewDate", type: mssql.TYPES.Int, value: documentSaveRequest.reviewDate },
            { name: "reference", type: mssql.TYPES.NVarChar, value: documentSaveRequest.reference },
        ];
        const response = await this.databaseService.execute("[documents].[spDocument_Save]", parameters);
        return response.singleResult;
    }

    public async selectForEntity(parentEntityType: string, parentEntityId: number): Promise<any> {
        let parameters: Array<IDbInputParamter> = [
            { name: "parentEntityId", type: mssql.TYPES.Int, value: parentEntityId },
            { name: "parentEntityType", type: mssql.TYPES.NVarChar, value: parentEntityType },
        ];
        const response = await this.databaseService.execute("[documents].[spDocument_SelectForEntity]", parameters);
        let result = response.results;
        for (let item of result) {
            let url: undefined;
            if (item.container && item.blobName) {
                const sasUrl = await this.getSASUrl(item.container, item.blobName);
                url = sasUrl.url;
            }
            item.url = url;
        }
        return response.results;
    }

    public async selectByBlobName(blobName: string): Promise<any> {
        let parameters: Array<IDbInputParamter> = [
            { name: "blobName", type: mssql.TYPES.NVarChar, value: blobName },
        ];
        const response = await this.databaseService.execute("[documents].[spDocument_SelectByBlobName]", parameters);
        let result = response.singleResult;
        if (result.container && result.blobName) {
            const sasUrl = await this.getSASUrl(result.container, result.blobName);
            result.url = sasUrl.url;
        }
        return result;
    }

    public async versionHistory(documentId: number) {
        const response = await this.databaseService.execute("[documents].[spDocument_SelectVersions]", [
            { name: "documentId", type: mssql.TYPES.Int, value: documentId },
        ]);
        return response.results;
    }

    public async ensurePath(path: string): Promise<void> {
        try {
            const pathState = await fsp.stat(path);
            if (pathState.isDirectory()) {
                return;
            }
        } catch(e) {
            this.logger.error(e);
        }
        await fsp.mkdir(path, { recursive: true });
    }

    public async isFile(filename: string) : Promise<boolean> {
        try {
            const pathState = await fsp.stat(filename); 
            return pathState.isFile();
        } catch (error) {
            return false;
        }
    }

    private async _uploadToBlobStorage(document: IDocumentUpload): Promise<any> {
        try {
            const sharedKeyCredential = 
            new StorageSharedKeyCredential(process.env.STORAGE_ACCOUNT_NAME ?? "", process.env.STORAGE_ACCOUNT_KEY ?? "");
            const blobServiceClient = new BlobServiceClient(
                `https://${process.env.STORAGE_ACCOUNT_NAME}.blob.core.windows.net`,
                sharedKeyCredential
            );
            this.logger.log(`Processing file`, document.fullName);
            const containerClient = blobServiceClient.getContainerClient(document.container);
            await containerClient.createIfNotExists();

            const blockBlobClient = containerClient.getBlockBlobClient(document.blobName);
            const result = await blockBlobClient.uploadFile(document.fullName, {
                blobHTTPHeaders: {
                    blobContentType: document.mimeType
                }
            });
            
            return result;
        } catch (e) {
            this.logger.error(e);
            return { error: e };
        }
    }

    private async _uploadBufferToBlobStorage(document: IDocumentUpload, buffer: Buffer): Promise<any> {
        try {
            const sharedKeyCredential = 
                new StorageSharedKeyCredential(process.env.STORAGE_ACCOUNT_NAME ?? "", process.env.STORAGE_ACCOUNT_KEY ?? "");
            const blobServiceClient = new BlobServiceClient(
                `https://${process.env.STORAGE_ACCOUNT_NAME}.blob.core.windows.net`,
                sharedKeyCredential
            );
            this.logger.log(`Uploading buffer to container ${document.container}, blob ${document.blobName}`);
            const containerClient = blobServiceClient.getContainerClient(document.container);
            await containerClient.createIfNotExists();

            const blockBlobClient = containerClient.getBlockBlobClient(document.blobName);
            const result = await blockBlobClient.uploadData(buffer, {
                blobHTTPHeaders: {
                    blobContentType: document.mimeType
                }
            });

            return result;
        } catch (e) {
            this.logger.error(e);
            return { error: e };
        }
    }

    public getSASToken(containerName: string, blobName?: string, expireAfter?: number, permissions?: string): string {
        const accountname = process.env.STORAGE_ACCOUNT_NAME;
        const key = process.env.STORAGE_ACCOUNT_KEY;
        if (!accountname || !key) { return "" }

        const cerds = new StorageSharedKeyCredential(accountname, key);
        var startDate = new Date();
        var expiryDate = new Date();
        startDate.setTime(startDate.getTime() - 5 * 60 * 1000);  // minus 5 mins
        expiryDate.setTime(expiryDate.getTime() + (expireAfter ?? 5) * 60 * 1000); // default 5m
        const containerSAS = generateBlobSASQueryParameters({
            expiresOn: expiryDate,
            permissions: ContainerSASPermissions.parse(permissions ?? "r"),
            protocol: SASProtocol.Https,
            containerName: containerName,
            blobName: blobName ?? undefined,
            startsOn: startDate,
        }, cerds).toString();

        return containerSAS
    }

    public getSASTokenforDownload(downloadFilename : string, containerName: string, blobName?: string, expireAfter?: number, permissions?: string): string {
        const accountname = process.env.STORAGE_ACCOUNT_NAME;
        const key = process.env.STORAGE_ACCOUNT_KEY;
        if (!accountname || !key) { return "" }

        const cerds = new StorageSharedKeyCredential(accountname, key);
        var startDate = new Date();
        var expiryDate = new Date();
        startDate.setTime(startDate.getTime() - 5 * 60 * 1000);  // minus 5 mins
        expiryDate.setTime(expiryDate.getTime() + (expireAfter ?? 5) * 60 * 1000); // default 5m
        const containerSAS = generateBlobSASQueryParameters({
            expiresOn: expiryDate,
            permissions: ContainerSASPermissions.parse(permissions ?? "r"),
            protocol: SASProtocol.Https,
            containerName: containerName,
            blobName: blobName ?? undefined,
            startsOn: startDate,
            contentDisposition: `attachment; filename="${downloadFilename}"`,
        }, cerds).toString();

        return containerSAS
    }

    public getSASTokenforView(filename : string, containerName: string, blobName?: string, expireAfter?: number, permissions?: string): string {
        const accountname = process.env.STORAGE_ACCOUNT_NAME;
        const key = process.env.STORAGE_ACCOUNT_KEY;
        if (!accountname || !key) { return "" }

        const cerds = new StorageSharedKeyCredential(accountname, key);
        var startDate = new Date();
        var expiryDate = new Date();
        startDate.setTime(startDate.getTime() - 5 * 60 * 1000);  // minus 5 mins
        expiryDate.setTime(expiryDate.getTime() + (expireAfter ?? 5) * 60 * 1000); // default 5m
        const containerSAS = generateBlobSASQueryParameters({
            expiresOn: expiryDate,
            permissions: ContainerSASPermissions.parse(permissions ?? "r"),
            protocol: SASProtocol.Https,
            containerName: containerName,
            blobName: blobName ?? undefined,
            startsOn: startDate,
            contentDisposition: `inline; filename="${filename}"`,
        }, cerds).toString();

        return containerSAS
    }

    public async getSASUrl(containerName: string, blobName: string, expireAfter?: number, permissions?: string) : Promise<any> {
        const sasToken = this.getSASToken(containerName, blobName, expireAfter, permissions);
        const sasUrl = `https://${process.env.STORAGE_ACCOUNT_NAME}.blob.core.windows.net/${containerName}/${blobName}?${sasToken}` 
        return { url: sasUrl };
    }

    public async getSASUrlforDownload(downloadFilename : string, containerName: string, blobName: string, expireAfter?: number, permissions?: string) : Promise<any> {
        const sasToken = this.getSASTokenforDownload(downloadFilename, containerName, blobName, expireAfter, permissions);
        const sasUrl = `https://${process.env.STORAGE_ACCOUNT_NAME}.blob.core.windows.net/${containerName}/${blobName}?${sasToken}` 
        return { url: sasUrl };
    }

    public async getSASUrlforView(Filename : string, containerName: string, blobName: string, expireAfter?: number, permissions?: string) : Promise<any> {
        const sasToken = this.getSASTokenforView(Filename, containerName, blobName, expireAfter, permissions);
        const sasUrl = `https://${process.env.STORAGE_ACCOUNT_NAME}.blob.core.windows.net/${containerName}/${blobName}?${sasToken}` 
        return { url: sasUrl };
    }

    public async downloadFile(blobName: string, containerName: string): Promise<Buffer> {
        const containerClient = this.blobServiceClient.getContainerClient(containerName);
        const blobClient = containerClient.getBlobClient(blobName);
        const downloadBlockBlobResponse = await blobClient.download();

        return await this.streamToBuffer(downloadBlockBlobResponse.readableStreamBody);
    }

    private async streamToBuffer(readableStream: NodeJS.ReadableStream): Promise<Buffer> {
        return new Promise((resolve, reject) => {
        const chunks: Buffer[] = [];
        readableStream.on('data', (data) => chunks.push(data instanceof Buffer ? data : Buffer.from(data)));
        readableStream.on('end', () => resolve(Buffer.concat(chunks)));
        readableStream.on('error', reject);
        });
    }

    public async isBlobExist(containerName: string, blobName: string): Promise<boolean> {
        const accountname = process.env.STORAGE_ACCOUNT_NAME;
        const key = process.env.STORAGE_ACCOUNT_KEY;
        if (!accountname || !key) { return false }

        const cerds = new StorageSharedKeyCredential(accountname, key);
        const blobServiceClient = new BlobServiceClient(
            `https://${accountname}.blob.core.windows.net`,
            cerds
        );

        const containerClient = blobServiceClient.getContainerClient(containerName);
        const blobClient = containerClient.listBlobsFlat();
        return true
    }

    public async generateHtml(templateFilename: string, data: any): Promise<string> {
        return this.createFromTemplate(templateFilename, data)
    }

    public async createFromTemplate(templateName: string, data: any): Promise<string> {
        this.buildHandlebarsHelper()
        const templateFilename = `./html/${templateName}.html`;
        const source = await this.fileToString(templateFilename);
        const template = handleBars.compile(source);
        return template(data);
    }

    public async fileToString(filename: string): Promise<string> {
        return await fsp.readFile(filename, 'utf8');
    }

    public async deleteDocument(document: any): Promise<boolean> {
        const response = await this.databaseService.execute("[documents].[spDocument_Delete]", [
            { name: "id", type: mssql.TYPES.Int, value: document.replaceDocId || document.id }
        ]);

        //Delete file from storage.
        await this.deleteFileAsync(document)
        return true;
    }

    public async deleteFileAsync(document: IDocumentUpload): Promise<any> {
        try {
            const sharedKeyCredential = 
            new StorageSharedKeyCredential(process.env.STORAGE_ACCOUNT_NAME ?? "", process.env.STORAGE_ACCOUNT_KEY ?? "");
            const blobServiceClient = new BlobServiceClient(
                `https://${process.env.STORAGE_ACCOUNT_NAME}.blob.core.windows.net`,
                sharedKeyCredential
            );
            const containerClient = blobServiceClient.getContainerClient(document.container);
            await containerClient.createIfNotExists();

            const blockBlobClient = containerClient.getBlockBlobClient(document.blobName);
            const result = await blockBlobClient.deleteIfExists({ deleteSnapshots: "include" });
            return result;
        } catch (e) {
            this.logger.error(e);
            console.log("Error in deleting file :" + document.id + e);
            return undefined;
        }
    }

    private async _ingressFile(directory: string, filename: string, options: IngressOptions): Promise<any> {
        if (options.perProcessingPause) {
            await this._sleep(options.perProcessingPause*1000);
        }
        const sourceFilename = path.join(directory, filename);
        const blobName: string = `${uuidv4().toLowerCase()}`;
        const container: string = 'imported';
        return await this._processFile({ filename: sourceFilename }, undefined, blobName, container);
    }

    private async _sleep(ms: number): Promise<any> {
        return new Promise((resolve) => {
            setTimeout(resolve, ms);
        });
    }    

    // private _notifyClient(messageKey: string, type: string, data:any): void {
    //     const msg = SystemNotificationMessage.create(messageKey, 'documents', type, data)
    //     this.notificationsService.sendNotification(process.env.MQTT_CLIENT_TOPIC, msg)
    // }

    buildHandlebarsHelper(){
          handleBars.registerHelper("getQuestionsAsSections", function(questions){
            let sectionedQuestions = [];
            let uniqueValues = [];
            let sectionQuestions = [];
            let currentSection:any;

            questions.forEach((question:any)=>{
                if(!uniqueValues.includes(question["taskDefinitionQuestionSectionId"])){
                    uniqueValues.push(question["taskDefinitionQuestionSectionId"])
                }
            });
            
            uniqueValues.forEach((section:any)=>{
                questions.forEach((question:any)=>{
                    if(question.taskDefinitionQuestionSectionId == section){
                        currentSection = {sectionTitle:question.displayedTitle, subText:question.subText}
                        sectionQuestions.push(question)
                    }
                });
                sectionedQuestions.push(
                    {
                        sectionTitle: currentSection.sectionTitle,
                        subText: currentSection.subText,
                        sectionQuestions:sectionQuestions
                    }
                )
                sectionQuestions = []
                currentSection = null
            });
            return sectionedQuestions;
          })

          handleBars.registerHelper('equals', function(val1, val2, options) {
            if(val1 === val2) {
              return options.fn(this);
            } else {
              return options.inverse(this);
            }
          });

          handleBars.registerHelper('formatDate', function (date) {
            const formattedDate = format(new Date(date), 'EEE MMMM d yyyy HH:mm');
            return formattedDate;
          });
    }

    public async search(request: any): Promise<Array<any>> {
        const url = this.buildURL();
        const response = await fetch(url, {
            ...request.body.options,
            body: JSON.stringify(request.body.options.body),
            headers: {
                "Content-Type": "application/json",
                "api-key": process.env.SEARCH_SERVICE_API_KEY,
            }
        });
        const searchResult = await response.json();
        const documents = await this.mapAdditionalInformation(searchResult);

        const prevDocs: Array<any> = [];
        //Map the result based on search term exist on the page of the document.
        documents?.map((e: any) => {
            const sr = searchResult?.value?.find(x => x.docId == e.id);
            const previewPages = this.getPreviewPages(sr["@search.highlights"]?.content, sr.metadata);
            const prevContainer = `${e.container}-prevs`;
            previewPages.forEach(pPage => {
                const sasToken = this.getSASToken(prevContainer, `${pPage.prevName}`)
                const highlights = pPage.words.map((W) => {
                    return W.bbox;
                });
                const viewbox = this.getViewBox(highlights, pPage)
                prevDocs.push({
                    ...e,
                    hasPreview: this.canHavePreview(e.mimeType) ? 1 : 0,
                    pageNumber: pPage.pageNumber,
                    viewbox: viewbox,
                    highlights: highlights,
                    // docUrl: `https://${process.env.STORAGE_ACCOUNT_NAME}.blob.core.windows.net/${docContainer}/${e.id}`,
                    prevUrl: this.canHavePreview(e.mimeType)
                        ? `https://${process.env.STORAGE_ACCOUNT_NAME}.blob.core.windows.net/${prevContainer}/${pPage.prevName}?${sasToken}`
                        : ''
                });
            });
        });
        return prevDocs ?? [];
    }

    private async mapAdditionalInformation(searchResult: any): Promise<any[]> {
        const docIds = searchResult?.value?.map((x: any) => x.docId)?.join(',');
        const response = await this.databaseService.execute("[documents].[spDocument_SelectByIds]", [
            { name: "ids", type: mssql.TYPES.NVarChar, value: docIds },
        ]);
        return response.results;
    }

    private getViewBox(highlights: Array<any>, pPage: IPreviewPages): string {
        if (highlights.length > 0) {
            const highlight = highlights[0];
            let windowHight = 100; // portrait
            if (pPage.width > pPage.height) { // landscape
                windowHight = 1000;
            }
            let shiftUp = 0;
            if (highlight.y > windowHight) {
                shiftUp = (highlight.y - windowHight) + highlight.h;
            }
            return `0 ${shiftUp} ${pPage.width} ${pPage.height}`
        }
        return `0 0 ${pPage.width} ${pPage.height}`
    }

    private getPreviewPages(highlights: string[], metadataJson: string): IPreviewPages[] {
        const pages: IPreviewPages[] = [];
        try {
            const highlightWords = highlights?.length > 0 ? this.getHighlightWords(highlights) : [];
            const metadata = JSON.parse(metadataJson);
            for(let i=0; i< metadata.length; i++) {
                const page = metadata[i];
                const words: any = [];
                page.lines?.forEach((line: any) => {
                    highlightWords.forEach((word: any) => {
                        const matchWord = line.words?.find((x: any) => x.text.toLowerCase() == word.toLowerCase())
                        // If we want to highlight result from partial search
                        // const matchWord = line.words?.find((x: any) => x.text.toLowerCase().includes(word.toLowerCase()))
                        if (matchWord) {
                            words.push({
                                bbox: matchWord.bbox
                            });
                        }
                    });
                });
                if (words.length > 0) {
                    pages.push({
                        pageNumber: page.pageNumber,
                        width: page.width,
                        height: page.height,
                        prevName: page.imageUri,
                        words: words
                    });
                    break; //Remove this if we want to show each page from a multipage file having keyword on it
                }
            }
            if (pages.length === 0) {
                //Add first page as default if there is no highlighting words found. (mainly when search by filename)
                const firstPage = metadata?.length > 0 ? metadata[0] : undefined;
                pages.push({
                    pageNumber: 1,
                    width: firstPage ? firstPage.width : 1500,
                    height: firstPage ? firstPage.height : 2000,
                    prevName: firstPage ? firstPage.imageUri : '',
                    words: []
                })
            }
        } catch (e) {
            console.log('Error in getting preview pages');
        }
        
        return pages;
    }

    private getHighlightWords(highlights: string[]): string[] {
        const regexp = new RegExp('<em>(.+?)<\/em>', 'g');
        const allUniqueWords: string[] = [];
        highlights.forEach((highlight: string) => {
            const matches = highlight.match(regexp) ?? []
            const words = matches.map(word => (
                word.replace('<em>', '').replace('</em>', '').toLowerCase()
            ));
            const uniqueWords = this.removeDuplicates(words);
            allUniqueWords.push(...uniqueWords);
        })

        return this.removeDuplicates(allUniqueWords);
    }

    private getPreviewURL(mimeType: string): string {
        const baseAddress = process.env.FRONT_END_BASE_ADDRESS;
        let path;
        switch (mimeType) {
            case "application/vnd.openxmlformats-officedocument.wordprocessingml.document":
                path = "word.png";
                break;
            case "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet":
                path = "excel.png"
                break;
            case "application/vnd.ms-excel":
                path = "csv.png"
                break;
            case "text/csv":
                path = "csv.png";
                break;
            case "application/pdf":
                path = "pdf.png";
                break;
            case "application/zip":
                path = "zip.png";
                break;
            default:
                path = "file.png"
        }
        return baseAddress + "assets/previews/" + path;
    }

    private removeDuplicates(array: any) {
        return array.filter((a: any, b: any) => array.indexOf(a) === b)
    };

    private canHavePreview(mimeType: string): boolean {
        return (mimeType == "application/pdf" || mimeType.includes("image"))
    }

    private parseConfig(config: AzConfig): string {
        const root = `${config.protocol}://${config.serviceName}.${config.serviceDomain}/`;
        const path = `${config.servicePath}?api-version=${config.apiVer}`;
        return (root + path);
    }
      
    private buildURL(): string {
        //TODO: Maybe this can be fetched from DB to make it more configurable
        const config: AzConfig = {
            protocol: "https",
            serviceName: process.env.SEARCH_SERVICE_NAME,
            serviceDomain: "search.windows.net",
            servicePath: `indexes/${process.env.SEARCH_INDEX_NAME}/docs/search`,
            apiVer:  process.env.SEARCH_SERVICE_API_VER,
            apiKey: process.env.SEARCH_SERVICE_API_KEY,
            method: "POST"
        }
        return this.parseConfig(config)
    };

    public async uploadBufferAtPath(buffer: Buffer, blobName: string, container: string, mimeType: string): Promise<void> {
        const containerClient = this.blobServiceClient.getContainerClient(container);
        await containerClient.createIfNotExists();
        const blockBlobClient = containerClient.getBlockBlobClient(blobName);
        await blockBlobClient.uploadData(buffer, {
            blobHTTPHeaders: { blobContentType: mimeType },
        });
    }

    public async uploadBuffer(
        file: Express.Multer.File,
        request: FileUploadRequest
    ): Promise<any> {
        // Generate blobName and container as in uploadFile
        const prefix: string = request.parentEntityId && request.parentEntityType ? `${request.parentEntityType}-${request.parentEntityId}` : 'generic';
        const blobName: string = `${prefix}-${uuidv4().toLowerCase()}`;
        const container: string = request.container ? request.container : (request.customerId ? `customer-${request.customerId}` : 'unclassified');

        // We'll use undefined for userUid here
        const processedDocument = await this._processFile(
            { ...file, filename: file?.path },
            request,
            blobName,
            container,
            undefined
        );

        await this._uploadBufferToBlobStorage({ ...request, blobName, container, fullName: file.originalname }, file.buffer);

        return processedDocument;
    }
}
