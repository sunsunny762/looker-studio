import { Injectable } from '@nestjs/common';
import fetch from 'node-fetch';
import * as mssql from 'mssql';
import { DatabaseService } from '../database';

@Injectable()
export class CurrencyService {

    public APP_ID = process.env.OPEN_CURRENCY_APP_ID;
    public API_URL = `https://openexchangerates.org/api/latest.json?app_id=${this.APP_ID}`;
    
    constructor(private readonly databaseService: DatabaseService) { }
   
    public async processCurrencyRate() {
        const result = await this.getAllRates();
        const currencyRates = Object.entries(result?.rates).map(([currency, rate]) => ({
            currency,
            rate
          })
        );

        const query = await this.databaseService.execute("[Currency].[spCurrency_AddRate]", [
            { name: "currency_JSON", type: mssql.TYPES.NVarChar, value: currencyRates ? JSON.stringify(currencyRates) : '' },
          ]
        );
        return query.results;
    }

    public async getAllRates() {
        const options = {
            method: 'GET'
        };
        try {
            const response = await fetch(this.API_URL, options);
            const result = await response.json();
            return result;
        } catch (e) {
            console.log("getAllRates Error:", e);
        }
    }

}