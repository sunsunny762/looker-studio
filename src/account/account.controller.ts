import { Controller, Get, Req } from '@nestjs/common';
import { AccountService } from './account.service';

@Controller('account')
export class AccountController {
    constructor(private readonly accountService: AccountService) {}

    @Get('/me')
    async getMe(@Req() req: any): Promise<string> {
      return await this.accountService.me(req.user);
    }
  
}
