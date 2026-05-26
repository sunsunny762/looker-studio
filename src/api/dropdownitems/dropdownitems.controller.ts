import { Body, Controller, Get, Param, Post, Put, Delete, Req, HttpException, HttpStatus } from '@nestjs/common';
import { DropdownItemsService } from './dropdownitems.service';
import { FirebaseAuthService } from '../../firebase/firebase-auth.service';

@Controller('dropdownitems')
export class DropdownItemsController {

    constructor(private readonly dropdownItemsService: DropdownItemsService, private readonly firebaseAuthService: FirebaseAuthService) { }

    @Get('/company/:companyId')
    async getSelectedCompanyDropdown(@Param('companyId') companyId: string): Promise<any> {
        return await this.dropdownItemsService.getCompanyDropdown(parseInt(companyId));
    }
    @Get('/company')
    async getCompanyDropdown(): Promise<any> {
        return await this.dropdownItemsService.getCompanyDropdown(null);
    }
    @Get('/country')
    async getCoountryDropdown(): Promise<any> {
        return await this.dropdownItemsService.getCountryDropdown();
    }
    @Get('/currency')
    async getCurrencyDropdown(): Promise<any> {
        return await this.dropdownItemsService.getCurrencyDropdown();
    }
    @Get('/prog/:progId')
    async getSelectedProgDropdown(@Param('progId') progId: string): Promise<any> {
        return await this.dropdownItemsService.getProgDropdown(parseInt(progId));
    }
    @Get('/prog')
    async getProgDropdown(): Promise<any> {
        return await this.dropdownItemsService.getProgDropdown(null);
    }
    @Get('/emission-profile/:emissionProfileId?')
    async getEmissionProfileDropdown(@Param('emissionProfileId') emissionProfileId: string): Promise<any> {
        return await this.dropdownItemsService.getEmissionProfileDropdown(emissionProfileId ? parseInt(emissionProfileId) : null);
    }

    @Get('/role/:companyId/:roleId')
    async getSelectedRoleDropdown(@Param('companyId') companyId: string, @Param('roleId') roleId: string): Promise<any> {
        return await this.dropdownItemsService.getRoleDropdown(parseInt(companyId), parseInt(roleId));
    }
    @Get('/role/:companyId/')
    async getRoleDropdown(@Param('companyId') companyId: string): Promise<any> {
        return await this.dropdownItemsService.getRoleDropdown(parseInt(companyId), null);
    }

    @Get('/location/:certId/')
    async getLocationDropdown(@Param('certId') certId: string, @Req() req: any): Promise<any> {
        const uCompanyId = await this.firebaseAuthService.getUserCompanyId(req);
        return await this.dropdownItemsService.getLocationDropdown(parseInt(certId), uCompanyId);
    }

    @Get('/location/cmp/:certId/') // For Company Profile submission only
    async getLocationDropdownForCMP(@Param('certId') certId: string, @Req() req: any): Promise<any> {
        const uCompanyId = await this.firebaseAuthService.getUserCompanyId(req);
        return await this.dropdownItemsService.getLocationDropdown(parseInt(certId), uCompanyId, 1);
    }

    @Get('/form/:certId')
    async getFormDropdown(@Param('certId') certId: string): Promise<any> {
        return await this.dropdownItemsService.getFormDropdown(parseInt(certId));
    }
   
    @Get('/:groupId/:itemId')
    async getSelectedDropdownItemsbyGroup(@Param('groupId') groupId: string, @Param('itemId') itemId: string): Promise<any> {
        return await this.dropdownItemsService.getDropdownItems(parseInt(groupId), parseInt(itemId));
    }
    @Get('/:groupId')
    async getDropdownItemsbyGroup(@Param('groupId') groupId: string): Promise<any> {
        return await this.dropdownItemsService.getDropdownItems(parseInt(groupId), null);
    }

    @Post()
    async addDropdownItems(@Req() req: any, @Body() body: any): Promise<any> {
        try{
            const { groupId, itemValue } = body;
            return await this.dropdownItemsService.addDropdownItems(groupId, itemValue);
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Put('/:itemId')
    async updateDropdownItems(@Param('itemId') paramItemId: string, @Body() body: any): Promise<any> {
        if(paramItemId != body.itemId) return null;
        try{
            const { itemId, groupId, itemValue } = body;
            return await this.dropdownItemsService.updateDropdownItems(itemId, groupId, itemValue);
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Delete('/:itemId') 
    async deleteDropdownItems(@Param('itemId') itemId: string): Promise<any> {
        try {
            return await this.dropdownItemsService.deleteDropdownItems(parseInt(itemId));
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
}
