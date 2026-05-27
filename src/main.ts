import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import * as dotenv from "dotenv";
import { FirebaseService } from './firebase.service';
import { SchedulerService } from './scheduler';
import { UtilitiesService } from './utilities/utilities.service';
import { DatabaseService } from './database';
import { GlobalExceptionFilter } from './error-logger/global-exception.filter';
import { ErrorLoggerService } from './error-logger/error-logger.service';
import { NestExpressApplication } from '@nestjs/platform-express';
import { join } from 'path';

dotenv.config();
const port = process.env.PORT || 3000;

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule, { rawBody: true });

  app.enableCors({
    exposedHeaders: ['Content-Disposition'],
  });

  // // Serve static files from tools assets directory
  // app.useStaticAssets(join(__dirname, 'api', 'tools', 'assets'), {
  //   prefix: '/tools/assets/',
  // });

  // Unhandled Exceptions
  const errorLoggerService = app.get(ErrorLoggerService);
  app.useGlobalFilters(new GlobalExceptionFilter(errorLoggerService));

  await app.listen(port);

  // Explicit service initialisation hooks
  app.get(UtilitiesService).initialise();

  await app.get(DatabaseService).initialise();

  const fullScheduler = (!process.env.DISABLE_SCHEDULER || process.env.DISABLE_SCHEDULER!='1');
  app.get(SchedulerService).initialise(fullScheduler);

  console.log(`Application is running on: ${await app.getUrl()}`);

  // Unhandled Exceptions
  process.on('uncaughtException', (error) => {
    console.error('Uncaught Exception ', error);
  });
  
  process.on('unhandledRejection', (reason: any) => {
    console.error('Unhandled Rejection ', reason);
  });
}
bootstrap();
