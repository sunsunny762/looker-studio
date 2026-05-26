import * as XLSX from 'xlsx';
import * as mssql from "mssql";
import { DatabaseService } from '../database/database.service';
import { Injectable } from '@nestjs/common';

@Injectable()
export class FuelPriceService {
    constructor(
        private readonly databaseService: DatabaseService,
    ) {}

    public async processUpdateUKFuelPrices() {
        try {
            console.log('FuelPriceService - Fetching latest Excel URL...');
            const excelUrl = await this.getUKFuelExcelUrl();
            console.log('Excel URL:', excelUrl);

            console.log('Downloading and processing fuel price data...');
            const result = await this.downloadAndProcessUKData(excelUrl);
            console.log('FuelPriceService - data processing ompleted');
        } catch (err) {
            console.error('processUpdateUKFuelPrices', err.toString());
            return 0
        }
    }

    async downloadAndProcessUKData(excelUrl: string): Promise<any> {
        try {
            // Download the Excel file using fetch
            const response = await fetch(excelUrl);
            if (!response.ok) throw new Error('Failed to download Excel file');
            const arrayBuffer = await response.arrayBuffer();
            const buffer = Buffer.from(arrayBuffer);

            const workbook = XLSX.read(buffer, { type: 'buffer' });

            // Find the "data" sheet
            const sheet = workbook.Sheets['Data'];
            if (!sheet) throw new Error('Sheet "data" not found');

            // Convert to JSON
            const rows = XLSX.utils.sheet_to_json<any>(sheet, {
                defval: null,
                header: 8, // Get rows as arrays
                range: 7   // Start from row 8 (0-based index)
            });
            const [header, ...dataRows] = rows;
            // Get last 10 rows, filter out empty/null rows
            const last10 = rows.slice(-10).filter((row: any) => {
                // Remove rows where all values are null or undefined
                return Object.values(row).every(v => v !== null && v !== undefined && v !== '');
            });

            // Extract only specific columns
            const selectedColumns = last10.map((row: any) => {
                const values = Object.values(row);
                return {
                    weekDate: this.excelDateToJSDate(Number(values[0])), // 0: Date
                    petrolPrice: values[1],                              // 1: ULSP: Pump price (p/litre)
                    dieselPrice: values[6],                              // 6: ULSD: Pump price (p/litre)
                };
            });

            // selectedColumns is your array of objects to save
            const json = JSON.stringify(selectedColumns);

            // Save into DB using stored procedure
            await this.databaseService.execute("[Emissions].[spFuelPrice_Save]", [
                { name: "json", type: mssql.TYPES.NVarChar, value: json },
                { name: "country", type: mssql.TYPES.NVarChar, value: "United Kingdom" }
            ]);

            //console.log(selectedColumns);
            return selectedColumns;
        } catch (error) {
            console.error("downloadAndProcessUKData", error.toString());
            //this.errorLogger.log(error, 'FuelPriceService.downloadAndProcessUKData');
            throw error;
        }
    }

    async getUKFuelExcelUrl(): Promise<string> {
        try {
            if (!process.env.FUEL_PRICE_UK_URL) throw new Error('FUEL_PRICE_UK_URL is not set in environment variables.');

            const response = await fetch(process.env.FUEL_PRICE_UK_URL);
            const html = await response.text();

            // Look for anchor tag with Excel download
            const match = html.match(
                /<a[^>]+href="([^"]+\.xlsx)"[^>]*>([^<]*Weekly road fuel prices \(Excel\)[^<]*)<\/a>/i
            );

            if (!match || !match[1]) {
                throw new Error('Could not find Excel link with text "Weekly road fuel prices (Excel)"');
            }

            const href = match[1];
            return href.startsWith('http') ? href : `https://www.gov.uk${href}`;
        } catch (error) {
            console.error("getUKFuelExcelUrl", error.toString());
            //this.errorLogger.log(error, 'FuelPriceService.getUKFuelExcelUrl');
            throw error;
        }
    }

    excelDateToJSDate(serial: number): Date {
        // Excel incorrectly treats 1900 as a leap year, so subtract 1 for dates after 28 Feb 1900
        const utc_days = Math.floor(serial - 25569);
        const utc_value = utc_days * 86400; // seconds in a day
        return new Date(utc_value * 1000);
    }
}