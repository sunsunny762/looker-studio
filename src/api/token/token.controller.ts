import { Body, Controller, Get, HttpException, HttpStatus, Param, Post, Put, Query, Req } from '@nestjs/common';
import { TokenService } from './token.service';

@Controller('token')
export class TokenController {
  constructor(
    private readonly tokenService: TokenService,
  ) {}

  @Get()
  async getTokens(
    @Query('dimFormId') dimFormId: string,
    @Query('tokenType') tokenType: string,
    @Query('activeOnly') activeOnly: string,
  ): Promise<any> {
    try {
      if (!dimFormId) throw new HttpException('dimFormId is required', HttpStatus.BAD_REQUEST);
      return await this.tokenService.getTokens(
        parseInt(dimFormId, 10),
        tokenType || null,
        activeOnly !== 'false',
      );
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to fetch tokens',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Get('validate/:tokenKey/:tokenType')
  async validateToken(@Param('tokenKey') tokenKey: string, @Param('tokenType') tokenType: string, @Req() req: any) {
    try {
      const token = await this.tokenService.validateToken(tokenKey, tokenType);
      
      if (!token) {
        throw new HttpException('Invalid token', HttpStatus.NOT_FOUND);
      }

      return token;
      // return {
      //   success: true,
      //   data: token,
      // };
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to validate token',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Post()
  async createToken(
    @Body() body: {
      certId?: number; locationId?: number; dimFormId?: number; activeTo?: Date;
      isActive?: boolean, tokenType?: string, properties?: string
    },
    @Req() req: any,
  ) {
    try {
      const token = await this.tokenService.createToken(
        body.certId,
        body.locationId,
        body.dimFormId,
        body.activeTo,
        body.isActive,
        body.tokenType,
        body.properties
      );

      return {
        success: true,
        data: token,
      };
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to create token',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Put(':tokenId')
  async updateToken(
    @Param('tokenId') tokenId: number,
    @Body() body: {
      certId?: number; locationId?: number; dimFormId?: number; activeTo?: Date;
      isActive?: boolean, tokenType?: string, properties?: string
    },
    @Req() req: any,
  ) {
    try {
      const token = await this.tokenService.updateToken(
        tokenId,
        body.certId,
        body.locationId,
        body.dimFormId,
        body.activeTo,
        body.isActive,
        body.tokenType,
        body.properties
      );

      return {
        success: true,
        data: token,
      };
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to update token',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}
