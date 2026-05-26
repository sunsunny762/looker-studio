import { Body, Controller, Get, Param, Post, Put, Delete, Req, HttpException, HttpStatus, Query, UploadedFile, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { CompanyService } from './company.service';
import { JotformService } from '../../jotform/jotoform.service';
import { DocumentsService } from '../../documents/documents.service';

@Controller('companies')
export class CompanyController {

    constructor(private readonly companyService: CompanyService,
        private readonly jotformService: JotformService,
        private readonly documentsService: DocumentsService
    ) { }

    @Get()
    async getCompanies(@Req() req: any, @Body() body: any): Promise<any> {
        try {
            return await this.companyService.getCompanies(null, null);
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Get('/ncz-directory') // keep above @Get('/:companyId') as :companyId is string and 'ncz-directory' will be considered a companyId
    async getNCZDirectory(@Query('dirItemId') dirItemId?: string, @Query('showAll') showAll?: string): Promise<any> {
        try {
            return await this.companyService.getNCZDirectory(dirItemId ? parseInt(dirItemId) : null, showAll === '1');
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Put('/ncz-directory/:dirItemId')
    async updateNCZDirectory(@Param('dirItemId') paramDirItemId: string, @Body() body: any): Promise<any> {
        if (paramDirItemId != body.dirItemId) return null;
        try {
            const {
                dirItemId, companyName, certTaskId, customerReference, isVisible, isArchive, co2PerRevenue
            } = body;

            return await this.companyService.updateNCZDirectory(dirItemId, companyName, certTaskId, customerReference, isVisible, isArchive, co2PerRevenue);
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Get('/:companyId')
    async getCompany(@Param('companyId') companyId: string): Promise<any> {
        try {
            return await this.companyService.getCompanies(parseInt(companyId), null);
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    
    // @Get('/customer-directory/:companyId')
    // async getCustomerDirectory(@Param('companyId') companyId: string): Promise<any> {
    //     try {
    //         return await this.companyService.getCustomerDirectory(parseInt(companyId));
    //     } catch (error)
    //     {
    //         throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
    //     }
    // }

    @Post()
    async addCompany(@Req() req: any, @Body() body: any): Promise<any> {
        try {
            const {
                companyName, email, registrationNumber, phone, address,
                industryType, industryTypeOther, industryTypeStr, website, contactName, jobTitle, status,
                locationCnt, companyTaskId, personTaskId, createCompanyTask, createPersonTask,
                description
            } = body;

            let newCompanyTaskId = companyTaskId;
            let newPersonTaskId = personTaskId;

            const buildDate = Date.now();

            if (createCompanyTask) {
                const companyTaskData = {
                    BAQ_CompanyName: companyName,
                    BAQ_CompanyDescription: '',
                    BAQ_CompanyIndustry: industryTypeStr,
                    BAQ_CompanyWebsite: website,
                    BAQ_Phone: phone || '',
                };


                const companyTaskResponse = await this.jotformService._createCompanyTask(
                    'Company',
                    companyTaskData,
                    buildDate
                );

                if (companyTaskResponse?.id) {
                    newCompanyTaskId = companyTaskResponse.id;
                }
            }

            if (createPersonTask) {

                const personTaskData = {
                    BAQ_YourName: contactName,
                    BAQ_Email: email,
                    BAQ_Phone: phone || '',
                    BAQ_CompanyName: companyName,
                    BAQ_JobTitle: jobTitle,
                };

                const personTaskResponse = await this.jotformService._createPersonTask(
                    'People',
                    personTaskData,
                    newCompanyTaskId ?? '',
                    buildDate
                );

                if (personTaskResponse?.id) {
                    newPersonTaskId = personTaskResponse.id;
                }
            }

            return await this.companyService.addCompany(
                companyName, email, registrationNumber, phone, address,
                industryType, industryTypeOther, website, contactName,
                jobTitle, status, locationCnt, newCompanyTaskId, newPersonTaskId,
                description
            );

        } catch (error) {
            console.error('addCompany error:', error);
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Put('/:companyId')
    async updateCompany(@Param('companyId') paramCompanyId: string, @Body() body: any): Promise<any> {
        if (paramCompanyId != body.companyId) return null;
        try {
            const {
                companyId, companyName, email, registrationNumber, phone, address,
                industryType, industryTypeOther, website, contactName, jobTitle, status,locationCnt,
                companyTaskId, personTaskId,
                description
            } = body;

            return await this.companyService.updateCompany(companyId, companyName, email, registrationNumber, phone, address,
                   industryType, industryTypeOther, website, contactName, jobTitle, status, locationCnt, companyTaskId, personTaskId,
                   description);
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Delete('/:companyId') 
    async deleteCompany(@Param('companyId') companyId: string): Promise<any> {
        try {
            return await this.companyService.deleteCompany(parseInt(companyId));
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    
    @Post('/ncz-directory-form')
    async addNCZDirectoryForm(@Req() req: any, @Body() body: any): Promise<any> {
       try {
            const {
            companyId, salesName, salesEmail, salesPhone,
            esgName, esgEmail, esgPhone, website,
            linkedinPage, facebookPage, instagramPage, emissionOffset,
            companyDescription, offersDiscounts,
            certId
            } = body;

            return await this.companyService.addDirectoryForm(
            companyId, salesName, salesEmail, salesPhone,
            esgName, esgEmail, esgPhone, website,
            linkedinPage, facebookPage, instagramPage, emissionOffset,
            companyDescription, offersDiscounts,
            certId
            );
        } catch (error) {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // @Post('/upload-logo')
    // @UseInterceptors(FileInterceptor('file'))
    // async uploadLogo(@UploadedFile() file: Express.Multer.File): Promise<any> {
    //     try {
    //         const result = await this.documentsService.uploadToPublicContainer(
    //             file,
    //             'company-logo'
    //         );
    //         return { url: result.url };
    //     } catch (error) {
    //         throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
    //     }
    // }
}
