import { BadRequestException, Injectable } from '@nestjs/common';
import * as mssql from 'mssql';
import { DatabaseService } from '../../database';
import { DocumentsService } from '../../documents/documents.service';
import { FileUploadRequest } from '../../documents/model';
import * as XLSX from 'xlsx';
import { parse } from 'csv-parse/sync';

@Injectable()
export class SupplyChainService {
  constructor(
    private readonly databaseService: DatabaseService,
    private readonly documentsService: DocumentsService,
  ) { }

  public async getSupplyChainSuppliers(companyId?: number): Promise<any> {
    const query = await this.databaseService.execute('[portal].[spSupplier_Get]', [
      { name: 'companyId', type: mssql.TYPES.Int, value: companyId ?? null },
    ]);
    return query.results;
  }

  public async getSupplyChainDocuments(companyId?: number): Promise<any> {
    const query = await this.databaseService.execute('[portal].[spSupplyChainDocument_Get]', [
      { name: 'companyId', type: mssql.TYPES.Int, value: companyId ?? null },
    ]);
    return query.results;
  }

  public async addSupplyChainDocument(
    companyId: number,
    documentId: number,
    displayName: string,
  ): Promise<any> {
    const query = await this.databaseService.execute('[portal].[spSupplyChainDocument_Save]', [
      { name: 'companyId', type: mssql.TYPES.Int, value: companyId },
      { name: 'documentId', type: mssql.TYPES.Int, value: documentId },
      { name: 'displayName', type: mssql.TYPES.NVarChar, value: displayName },
    ]);
    const results = query.results;
    return results;
  }

  public async getDocumentUrl(documentId: number): Promise<any> {
    const query = await this.databaseService.execute('[documents].[spDocument_Get]', [
      { name: 'documentId', type: mssql.TYPES.Int, value: documentId },
    ]);
    const results = query.singleResult;
    if (results) {
      const res = await this.documentsService.getSASUrlforView(
        results.title,
        results.container,
        results.blobName,
      );
      return {
        documentId: documentId,
        displayName: results.title,
        mimeType: results.mimeType,
        url: res.url,
      };
    } else {
      return null;
    }
  }

  public async getDocumentDownload(documentId: number): Promise<any> {
    const query = await this.databaseService.execute('[documents].[spDocument_Get]', [
      { name: 'documentId', type: mssql.TYPES.Int, value: documentId },
    ]);

    const results = query.singleResult;

    if (results) {
      const buffer = await this.documentsService.downloadFile(results.blobName, results.container);

      return {
        buffer,
        title: results.title,
      };
    }

    return null;
  }

  public async uploadSupplyChainDocument(file: Express.Multer.File, body: any, uId: string | null): Promise<any> {
    try {
      const fileExtension = file.originalname.split('.').pop()?.toLowerCase();

      if (!['csv', 'xls', 'xlsx'].includes(fileExtension)) {
        throw new BadRequestException('Invalid file type. Only CSV, XLS, or XLSX are allowed.');
      }

      const baseTitle = body.title.includes(`.${fileExtension}`)
        ? body.title.replace(`.${fileExtension}`, '')
        : body.title;

      const title = `${baseTitle}.${fileExtension}`;

      const request: FileUploadRequest = {
        id: null,
        parentEntityId: body.companyId,
        parentEntityType: 'supply-chain',
        customerId: body.companyId,
        title: title,
        container: 'supply-chain-docs',
        mimeType: file.mimetype,
        size: file.size,
        blobName: file.originalname,
        singleInstance: false,
        canEmbed: false,
        modifiedDate: Date.now(),
      };

      const result = await this.documentsService.uploadBuffer(file, request);

      if (result && result.id) {
        await this.databaseService.execute('[portal].[spSupplyChainDocument_Save]', [
          { name: 'companyId', type: mssql.TYPES.Int, value: body.companyId },
          { name: 'documentId', type: mssql.TYPES.Int, value: result.id },
          { name: 'displayName', type: mssql.TYPES.NVarChar, value: title },
        ]);

        await this.databaseService.execute('[portal].[spSupplierStatusHistory_Save]', [
          { name: 'companyId', type: mssql.TYPES.Int, value: body.companyId },
          { name: 'eventType', type: mssql.TYPES.VarChar, value: 'uploaded' },
          { name: 'uId', type: mssql.TYPES.NVarChar, value: uId ?? null },
        ]);
      }

      return result;
    } catch (error) {
      if (error instanceof BadRequestException) throw error;

      console.error('File upload failed:', error);
      throw new BadRequestException('File upload failed. Please try again later.');
    }
  }

  public async importDataSupplyChainDocument(
    file: Express.Multer.File,
    body: any,
    uId: string | null
  ): Promise<any> {
    try {
      const fileExtension = file.originalname.split('.').pop()?.toLowerCase();
      const requiredColumns = ['Company Name', 'Person Name'];
      let records: any[] = [];

      if (fileExtension === 'csv') {
        const content = file.buffer.toString('utf-8');
        records = parse(content, { columns: true, skip_empty_lines: true });
      } else if (['xls', 'xlsx'].includes(fileExtension)) {
        const workbook = XLSX.read(file.buffer, { type: 'buffer' });
        const sheetName = workbook.SheetNames[0];
        const worksheet = workbook.Sheets[sheetName];
        records = XLSX.utils.sheet_to_json(worksheet);
      } else {
        throw new BadRequestException('Invalid file type. Only CSV, XLS, or XLSX are allowed.');
      }

      if (!records || records.length === 0) {
        throw new BadRequestException('No records found in the file.');
      }

      const columns = Object.keys(records[0] || {});
      const missingColumns = requiredColumns.filter((c) => !columns.includes(c));
      if (missingColumns.length > 0) {
        throw new BadRequestException(`Missing required columns: ${missingColumns.join(', ')}`);
      }

      for (const [index, record] of records.entries()) {
        const companyName = String(record['Company Name'] || '').trim();
        const personName = String(record['Person Name'] || '').trim();

        if (!companyName || !personName) {
          throw new BadRequestException(
            `Row ${index + 1}: Missing required data (Company Name, Person Name)`,
          );
        }

      }

      const results: any[] = [];
      for (const record of records) {
        const companyName = this.toSafeString(record['Company Name']);
        const name = this.toSafeString(record['Person Name']);
        const email = this.toSafeString(record['Person Email']) ?? '';
        const phone = this.toSafeString(record['Person Phone']) ?? '';
        const industry = this.toSafeString(record['Industry']);
        const spend = this.toSafeString(record['Spend']);
        const isMissing = this.getSupplierMissingFlag(email, phone);

        const query = await this.databaseService.execute('[portal].[spSupplier_Save]', [
          { name: 'supplierId', type: mssql.TYPES.Int,      value: null },
          { name: 'companyId',  type: mssql.TYPES.Int,      value: body.companyId },
          { name: 'companyName',type: mssql.TYPES.NVarChar, value: companyName },
          { name: 'name',       type: mssql.TYPES.NVarChar, value: name },
          { name: 'email',      type: mssql.TYPES.NVarChar, value: email },
          { name: 'phone',      type: mssql.TYPES.NVarChar, value: phone },
          { name: 'industry',   type: mssql.TYPES.NVarChar, value: industry },
          { name: 'spend',      type: mssql.TYPES.NVarChar, value: spend },
          { name: 'certId',     type: mssql.TYPES.Int,      value: body.certId ? parseInt(body.certId) : null },
          { name: 'isMissing',  type: mssql.TYPES.Bit,      value: isMissing },
        ]);

        const result = query.results?.[0] || {};
        results.push({
          companyName,
          name,
          email,
          phone,
          industry,
          spend,
          isMissing,
          action: result.Action || 'Unknown',
          supplierId: result.supplierId || null,
        });
      }

      await this.databaseService.execute('[portal].[spSupplierStatusHistory_Save]', [
        { name: 'companyId', type: mssql.TYPES.Int, value: body.companyId },
        { name: 'eventType', type: mssql.TYPES.VarChar, value: 'imported' },
        { name: 'uId', type: mssql.TYPES.NVarChar, value: uId ?? null },
      ]);

      return {
        message: 'All supplier data imported successfully.',
        totalRecords: records.length,
        processed: results.length,
        results,
      };
    } catch (error) {
      console.error('Import Supplier Data Error:', error);
      if (error instanceof BadRequestException) throw error;
      throw new BadRequestException('File upload failed. Please try again later.');
    }
  }

  public async deleteSupplyChainDocument(
    companyId: number,
    documentId: number,
    deleteFile: boolean = false,
  ): Promise<any> {
    const query = await this.databaseService.execute('[portal].[spSupplyChainDocument_Delete]', [
      { name: 'companyId', type: mssql.TYPES.Int, value: companyId },
      { name: 'documentId', type: mssql.TYPES.Int, value: documentId },
    ]);
    const results = query.results;

    if (deleteFile && results.length > 0) {
      return this.documentsService.deleteDocument(results[0]);
    }
  }

  public async deleteSupplier(supplierId: number): Promise<any> {
    const query = await this.databaseService.execute('[portal].[spSupplier_Delete]', [
      { name: 'supplierId', type: mssql.TYPES.Int, value: supplierId },
    ]);
    const results = query.results;
    return results;
  }

  public async saveSupplier(body: any): Promise<any> {
    const supplierId = body.supplierId ? parseInt(body.supplierId, 10) : null;
    const companyId = body.companyId ? parseInt(body.companyId, 10) : null;
    const email = this.toSafeString(body.email) ?? '';
    const phone = this.toSafeString(body.phone) ?? '';
    const isMissing = this.getSupplierMissingFlag(email, phone);

    const query = await this.databaseService.execute('[portal].[spSupplier_Save]', [
      { name: 'supplierId', type: mssql.TYPES.Int,      value: supplierId },
      { name: 'companyId',  type: mssql.TYPES.Int,      value: companyId },
      { name: 'companyName',type: mssql.TYPES.NVarChar, value: this.toSafeString(body.companyName) },
      { name: 'name',       type: mssql.TYPES.NVarChar, value: this.toSafeString(body.name) ?? '' },
      { name: 'email',      type: mssql.TYPES.NVarChar, value: email },
      { name: 'phone',      type: mssql.TYPES.NVarChar, value: phone },
      { name: 'industry',   type: mssql.TYPES.NVarChar, value: this.toSafeString(body.industry) },
      { name: 'spend',      type: mssql.TYPES.NVarChar, value: this.toSafeString(body.spend) },
      { name: 'certId',     type: mssql.TYPES.Int,      value: body.certId ? parseInt(body.certId, 10) : null },
      { name: 'isMissing',  type: mssql.TYPES.Bit,      value: isMissing },
    ]);

    return query.results;
  }

  private toSafeString(value: any): string | null {
    if (value === null || value === undefined || value === '') return null;

    let str = String(value).trim();

    if (str.startsWith('#')) return null;
    if (str.toLowerCase() === 'nan') return null;
    if (str.toLowerCase() === 'undefined') return null;

    return str;
  }

  private getSupplierMissingFlag(email: string, phone: string): number {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    const phoneRegex = /^[0-9+\-() ]{7,20}$/;

    if (!email || !phone) return 1;
    if (!emailRegex.test(email)) return 1;
    if (!phoneRegex.test(phone)) return 1;

    return 0;
  }
}
