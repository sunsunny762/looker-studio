import {
  Catch,
  ExceptionFilter,
  ArgumentsHost,
  HttpException,
  Injectable,
} from '@nestjs/common';
import { Response } from 'express';
import { ErrorLoggerService } from './error-logger.service';

@Injectable()
@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  constructor(private readonly errorLoggerService: ErrorLoggerService) {}

  async catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest();

    const status =
      exception instanceof HttpException ? exception.getStatus() : 500;

    const errorMessage =
      exception instanceof Error
        ? exception.message
        : 'Internal server error';

    const errorStack = exception instanceof Error ? exception.stack : null;

    // Log error to file and database
    this.errorLoggerService.writeLogToDB(request.url, {
      message: errorMessage,
      stack: errorStack,
    });

    // Send response to client
    response.status(status).json({
      statusCode: status,
      timestamp: new Date().toISOString(),
      path: request.url,
      message: errorMessage,
    });
  }
}
