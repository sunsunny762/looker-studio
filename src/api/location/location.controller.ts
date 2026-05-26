import { Body, Controller, Get, Param, Post, Put, Delete, Req, HttpException, HttpStatus, UploadedFile, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { LocationService } from './location.service';
import { DocumentsService } from '../../documents/documents.service';

@Controller('locations')
export class LocationController {

    constructor(
        private readonly locationService: LocationService,
        private readonly documentsService: DocumentsService,
    ) {}

    @Get('/company/:companyId')
    async getLocations(@Param('companyId') companyId: string): Promise<any> {
        try {
            return await this.locationService.getLocations(parseInt(companyId), null);
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Get('/:locationId')
    async getLocation(@Param('locationId') locationId: string): Promise<any> {
        try {
            return await this.locationService.getLocations(null, parseInt(locationId));
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Post('/upload-logo')
    @UseInterceptors(FileInterceptor('file'))
    async uploadLogo(@UploadedFile() file: Express.Multer.File): Promise<any> {
        try {
            const result = await this.documentsService.uploadToPublicContainer(
                file,
                'company-logo'
            );
            return { url: result.url };
        } catch (error) {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Post()
    async addLocation(@Req() req: any, @Body() body: any): Promise<any> {
        try {
            const {
                locationName,
                companyId,
                currency,
                countryId,
                logo,
            } = body;

            return await this.locationService.addLocation(locationName, companyId, currency, countryId, logo);
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Put('/:locationId')
    async updateLocation(@Param('locationId') paramLocationId: string, @Body() body: any): Promise<any> {
        if (paramLocationId != body.locationId) return null;
        try {
            const {
                locationId,
                locationName,
                currency,
                countryId,
                logo,
            } = body;

            return await this.locationService.updateLocation(locationId, locationName, currency, countryId, logo);
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Delete('/:locationId') 
    async deleteLocation(@Param('locationId') locationId: string): Promise<any> {
        try {
            return await this.locationService.deleteLocation(parseInt(locationId));
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
}
