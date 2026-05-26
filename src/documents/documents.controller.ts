import { Controller, Get, Param, Post, Req, Res, StreamableFile, UploadedFile, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { createReadStream, promises as fs  } from 'fs';
import { } from 'fs';
import { DocumentsService } from './documents.service';

@Controller('documents')
export class DocumentsController {
    constructor(private readonly documentService: DocumentsService) {}

    @Post('upload')
    @UseInterceptors(FileInterceptor('file', { dest: './uploads' }))
    uploadFile(@UploadedFile() file: Express.Multer.File, @Req() req: any) {
        return this.documentService.uploadFile(file, req.body, req.user);
    }

    @Post('upload-public')
    @UseInterceptors(FileInterceptor('file', { dest: './uploads' }))
    uploadToPublic(@UploadedFile() file: Express.Multer.File, @Req() req: any) {
        const { container, customFilename } = req.body;
        return this.documentService.uploadToPublicContainer(file, container, customFilename);
    }

    @Get('/entity/:parentEntityType/:parentEntityId')
    selectForEntity(@Param('parentEntityType') parentEntityType: string, @Param('parentEntityId') parentEntityId: number) {
      return this.documentService.selectForEntity(parentEntityType, parentEntityId);
    }

    // @Get('/site/:siteId/:documentType')
    // selectForSite(@Param('siteId') siteId: string, @Param('documentType') documentType: string) {
    //   return this.documentService.selectSiteDocuments(siteId, documentType);
    // }

    // @Get('/sitelink/:siteId/:documentType')
    // createSiteLink(@Param('siteId') siteId: string, @Param('documentType') documentType: string) {
    //   return this.documentService.createSiteDocumentLink(siteId, documentType);
    // }

    @Get('/:blobName')
    select(@Param('blobName') blobName: string) {
      return this.documentService.selectByBlobName(blobName);
    }

    @Post('/download')
    async download(@Req() req: any, @Res({ passthrough: true }) res: any) : Promise<StreamableFile> {
        const filename = req.body.filename;
        if(!filename) { return undefined; }
        if(!await this.documentService.isFile(filename)) { return undefined }

        const file = createReadStream(filename);
        if(req.body.contentType) {
            res.set({
                'Content-Type': req.body.contentType
            });
        }
        return new StreamableFile(file);
    }
    
  
    @Get('/sastoken/:container/:blobName')
    getSASToken(@Param('container') container: string, @Param('blobName') blobName: string) {
      return this.documentService.getSASToken(container, blobName);
    }

    @Get('/sasurl/:container/:blobName')
    getSASUrl(@Param('container') container: string, @Param('blobName') blobName: string) {
      return this.documentService.getSASUrl(container, blobName);
    }

    @Post('/delete')
    deleteDocument(@Req() req: any) {
      return this.documentService.deleteDocument(req.body);
    }

    @Get('/versionhistory/:documentId')
    versionHistory(@Param('documentId') documentId: number) {
      return this.documentService.versionHistory(documentId);
    }

    @Post('/search')
    search(@Req() req: any) {
      return this.documentService.search(req);
    }

}
