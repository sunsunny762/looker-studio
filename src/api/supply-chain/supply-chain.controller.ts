import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  HttpException,
  HttpStatus,
  Res,
  UploadedFile,
  UseInterceptors,
  Delete,
  BadRequestException,
  Req,
} from '@nestjs/common';
import { Response } from 'express';
import { FileInterceptor } from '@nestjs/platform-express';
import { SupplyChainService } from './supply-chain.service';

@Controller('supply-chain')
export class SupplyChainController {
  constructor(private readonly supplyChainService: SupplyChainService) { }

  @Get('/documents/:companyId?') // notice the '?' makes it optional
  async getSupplyChainDocument(@Param('companyId') companyId?: string): Promise<any> {
    const id = companyId ? parseInt(companyId) : undefined;
    return this.supplyChainService.getSupplyChainDocuments(id);
  }
 
  @Get('/suppliers/:companyId?')
  async getSupplyChainSupplier(@Param('companyId') companyId?: string): Promise<any> {
    const id = companyId ? parseInt(companyId) : undefined;
    return this.supplyChainService.getSupplyChainSuppliers(id);
  }

  @Delete('/suppliers/delete/:supplierId')
  async deleteSupplier(@Param('supplierId') supplierId: number): Promise<any> {
    try {
      return await this.supplyChainService.deleteSupplier(supplierId);
    } catch (error) {
      throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  @Get('documents/download/:documentId')
  async downloadFile(@Param('documentId') documentId: number, @Res() res: Response) {
    const fileResult = await this.supplyChainService.getDocumentDownload(documentId);

    if (!fileResult || !fileResult.buffer) {
      return res.status(404).send('File not found');
    }

    let filename = fileResult.title || 'document';
    filename = filename.replace(/[<>:"/\\|?*\x00-\x1F]/g, '').trim();

    if (!filename.endsWith('.xlsx')) {
      filename += '.xlsx';
    }

    res.set({
      'Content-Disposition': `attachment; filename="${encodeURIComponent(filename)}"`,
      'Content-Type': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    });

    res.send(fileResult.buffer);
  }

  @Get('/documents/view/:documentId')
  async getDocumentViewUrl(@Param('documentId') documentId: number): Promise<any> {
    return await this.supplyChainService.getDocumentUrl(documentId);
  }

  @Post('/documents/upload')
  @UseInterceptors(
    FileInterceptor('file', {
      fileFilter: (req, file, cb) => {
        if (!file.originalname.match(/\.(xlsx|xls)$/)) {
          return cb(new BadRequestException('Only Excel files are allowed!'), false);
        }
        cb(null, true);
      },
    }),
  )
  async uploadSupplyChainDocument(@UploadedFile() file: Express.Multer.File, @Body() body: any, @Req() req: any) {
    const uId = req.user?.uid ?? null;
    const result = await this.supplyChainService.uploadSupplyChainDocument(file, body, uId);
    return result;
  }

  @Post('/documents/import-data')
  @UseInterceptors(
    FileInterceptor('file', {
      // Optional: filter only Excel files
      fileFilter: (req, file, cb) => {
        if (!file.originalname.match(/\.(xlsx|xls)$/)) {
          return cb(new BadRequestException('Only Excel files are allowed!'), false);
        }
        cb(null, true);
      },
    }),
  )
  async importDataSupplyChainDocument(
    @UploadedFile() file: Express.Multer.File,
    @Body() body: any,
    @Req() req: any
  ) {
    const uId = req.user?.uid ?? null;
    const result = await this.supplyChainService.importDataSupplyChainDocument(file, body, uId);
    return result;
  }

  @Post('/documents/add')
  async addSupplyChainDocument(@Body() body: any): Promise<any> {
    try {
      for (const documentId of body.documentIds) {
        await this.supplyChainService.addSupplyChainDocument(body.certId, documentId, null);
      }
    } catch (error) {
      throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  @Delete('/documents/deleteFile/:companyId/:documentId') // To delete Certification specific Document and its file
  async deleteCertificationDocumentFile(
    @Param('companyId') companyId: number,
    @Param('documentId') documentId: number,
  ): Promise<any> {
    try {
      return await this.supplyChainService.deleteSupplyChainDocument(companyId, documentId, true);
    } catch (error) {
      throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }
  @Delete('/documents/delete/:certId/:documentId') // To delete Certification Document attached from ProgDocuments
  async deleteCertificationDocument(
    @Param('companyId') companyId: number,
    @Param('documentId') documentId: number,
  ): Promise<any> {
    try {
      return await this.supplyChainService.deleteSupplyChainDocument(companyId, documentId, false);
    } catch (error) {
      throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }
}
