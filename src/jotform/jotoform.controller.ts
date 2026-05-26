import { Body, Controller, Get, Param, Post, Query, Req, Res } from "@nestjs/common";
import { Response } from "express";
import { JotformService } from "./jotoform.service";
import { JotformDocumentService } from "./jotform-document.service";
import { FormDataRequest } from "nestjs-form-data";

@Controller("jotform")
export class JotformController {
  constructor(
    private readonly jotformService: JotformService,
    private readonly jotformDocumentService: JotformDocumentService,
  ) {}

  @Get("/forms")
  getIssues(@Req() req: any) {
    return this.jotformService.selectForms();
  }

  @Post("/certification/response")
  @FormDataRequest()
  saveResponse(@Req() req: any, @Body() body: any) {
    return this.jotformService.saveResponse(body);
  }

  @Post("/customerprofile/response") // NOT IN USE
  @FormDataRequest()
  customerProfile(@Req() req: any, @Body() body: any) {
    return this.jotformService.customerProfile(body);
  }

  @Post("/events/response") 
  @FormDataRequest()
  events(@Req() req: any, @Body() body: any) {
    return this.jotformService.events(body);
  }

  @Get('file/:submissionId')
  async getFile(
    @Param('submissionId') submissionId: string,
    @Query('fileName') fileName: string,
    @Res() res: Response,
  ) {
    const buffer = await this.jotformDocumentService.getFile(submissionId, fileName);
    const mime = require('mime-types').lookup(fileName) || 'application/octet-stream';
    res.set('Content-Type', mime);
    res.set('Content-Disposition', `inline; filename="${fileName}"`);
    res.set('Content-Length', String(buffer.length));
    res.end(buffer);
  }

  @Post('ingest/:certsubmissionId')
  async ingestDocuments(@Param('certsubmissionId') certsubmissionId: string) {
    return this.jotformDocumentService.ingestDocuments(certsubmissionId);
  }
}
