import { DatabaseService } from '../database/database.service'
import { FuelPriceService } from '../fuel-price/fuel-price.service'
import { ErrorLoggerService } from '../error-logger/error-logger.service';
import { EmailService } from '../email/email.service';
import * as dotenv from 'dotenv';
import * as path from 'path';
// To run: npx ts-node src/scripts/fuel-price-runner.ts
async function main() {

  const result = dotenv.config({ path: path.resolve(__dirname, '../../.env') });
  // Initialize services with proper connection
  const dbService = new DatabaseService();
  await dbService.initialise();
  if (dbService.isConnected === false) {
      console.error('Database connection failed.');
      return;
  }

  const service = new FuelPriceService(dbService);

  try {
    console.log('Fetching latest Excel URL...');
    const excelUrl = await service.getUKFuelExcelUrl();
    console.log('Excel URL:', excelUrl);

    console.log('Downloading and processing fuel price data...');
    const result = await service.downloadAndProcessUKData(excelUrl);
    console.log('Process result:', result);
  } catch (err) {
    console.error('Error:', (err as Error).message);
    process.exit(1);
  }
}

main();