import { Injectable, CanActivate, ExecutionContext, HttpException, HttpStatus } from '@nestjs/common';
import { TokenService } from '../token.service';

@Injectable()
export class TokenAuthGuard implements CanActivate {
    constructor(private readonly tokenService: TokenService) {}

    async canActivate(context: ExecutionContext): Promise<boolean> {
        const request = context.switchToHttp().getRequest();
        const authHeader = request.headers['authorization'];

        if (!authHeader) {
            throw new HttpException('Token is required', HttpStatus.UNAUTHORIZED);
        }

        const token = authHeader.startsWith('Bearer ')
            ? authHeader.slice(7).trim()
            : authHeader.trim();

        const validatedToken = await this.tokenService.validateToken(token, null);
        
        if (!validatedToken) {
            throw new HttpException('Invalid or not found token', HttpStatus.UNAUTHORIZED);
        }

        if (!validatedToken.isActive) {
            throw new HttpException('Token is not active', HttpStatus.UNAUTHORIZED);
        }

        if (validatedToken.isExpired) {
            throw new HttpException('Token has expired', HttpStatus.UNAUTHORIZED);
        }

        // Attach the validated token to the request for use in controllers
        request.validatedToken = validatedToken;

        return true;
    }
}
