import { Injectable, Logger } from '@nestjs/common';
import mssql, { ConnectionPool, Request, Table, VarChar } from 'mssql';
import { IDbInputParamter } from './model/db-input-parameter';
import { QueryResponse } from './model/query-response';

@Injectable()
export class DatabaseService {
    private readonly logger = new Logger(DatabaseService.name);
    private databaseConfig: mssql.config;
    private dbConnectionPool: ConnectionPool;
    public isConnected = false;
    private reconnecting = false;
    private readonly maxRetries = 3;
    private readonly retryDelay = 2000; // 2 seconds

    public async initialise(): Promise<void> {
        this.logger.log("Starting database services");
        this.databaseConfig = ({
            user: process.env.DB_USERNAME,
            password: process.env.DB_PASSWORD,
            server: process.env.DB_HOST || "localhost",
            database: process.env.DB_DATABASE || "default",
            port: 1433,
            requestTimeout: 600000,
            connectionTimeout: 30000,
            pool: {
                max: 10,
                min: 2,
                idleTimeoutMillis: 30000,
                acquireTimeoutMillis: 30000,
            },
            options: {
                encrypt: true,
                trustServerCertificate: false,
                enableArithAbort: true,
                instanceName: undefined
            }
        });

        await this.connectWithRetry();
        this.setupConnectionPoolListeners();
    }

    private setupConnectionPoolListeners(): void {
        if (!this.dbConnectionPool) return;

        this.dbConnectionPool.on('error', (err) => {
            this.logger.error('Connection pool error:', err);
            this.isConnected = false;
        });
    }

    private async connectWithRetry(attempt: number = 1): Promise<void> {
        this.logger.log(`Attempting database connection (attempt ${attempt}/${this.maxRetries})`);
        
        if (!this.dbConnectionPool) {
            this.dbConnectionPool = new ConnectionPool(this.databaseConfig);
        }

        try {
            await this.dbConnectionPool.connect();
            this.isConnected = true;
            this.reconnecting = false;
            this.logger.log("Connection pool ready");
        } catch (error) {
            this.logger.error(`Database connection failed (attempt ${attempt}/${this.maxRetries}):`, error.message);
            this.isConnected = false;

            if (attempt < this.maxRetries) {
                this.logger.log(`Retrying in ${this.retryDelay}ms...`);
                await this.sleep(this.retryDelay);
                return this.connectWithRetry(attempt + 1);
            } else {
                this.logger.error('Max connection retries reached. Database connection failed.');
                throw error;
            }
        }
    }

    private async ensureConnection(): Promise<void> {
        if (this.isConnected && this.dbConnectionPool?.connected) {
            return;
        }

        if (this.reconnecting) {
            // Wait for ongoing reconnection
            const maxWait = 30000; // 30 seconds
            const startTime = Date.now();
            while (this.reconnecting && (Date.now() - startTime) < maxWait) {
                await this.sleep(100);
            }
            if (this.isConnected) return;
        }

        this.reconnecting = true;
        this.logger.warn('Connection lost, attempting to reconnect...');
        
        try {
            if (this.dbConnectionPool) {
                try {
                    await this.dbConnectionPool.close();
                } catch (e) {
                    // Ignore close errors
                }
                this.dbConnectionPool = null;
            }
            await this.connectWithRetry();
        } catch (error) {
            this.reconnecting = false;
            throw error;
        }
    }

    private sleep(ms: number): Promise<void> {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    public async query(queryString: string): Promise<QueryResponse> {
        await this.ensureConnection();
        let request: Request = this.dbConnectionPool.request();
        try {
            const result = new QueryResponse(await request.query(queryString));
            return result;
        } catch (e) {
            this.logger.error(`Query execution failed: ${e.message}`);
            // Check if it's a connection error and retry once
            if (this.isConnectionError(e)) {
                this.logger.warn('Detected connection error, retrying query...');
                this.isConnected = false;
                await this.ensureConnection();
                request = this.dbConnectionPool.request();
                const result = new QueryResponse(await request.query(queryString));
                return result;
            }
            throw (e);
        }
    }

    public async execute(procedureName: string, parameters?: Array<IDbInputParamter>): Promise<QueryResponse> {
        await this.ensureConnection();
        let request: Request = this.dbConnectionPool.request();
        try {
            if (parameters) {
                for (const p of parameters) {
                    request.input(p.name, p.type, p.value);
                }
            }
            const result = new QueryResponse(await request.execute(procedureName));
            return result;
        } catch (e) {
            this.logger.error(`Stored procedure execution failed [${procedureName}]: ${e.message}`);
            // Check if it's a connection error and retry once
            if (this.isConnectionError(e)) {
                this.logger.warn('Detected connection error, retrying stored procedure...');
                this.isConnected = false;
                await this.ensureConnection();
                request = this.dbConnectionPool.request();
                if (parameters) {
                    for (const p of parameters) {
                        request.input(p.name, p.type, p.value);
                    }
                }
                const result = new QueryResponse(await request.execute(procedureName));
                return result;
            }
            throw (e);
        }
    }

    private isConnectionError(error: any): boolean {
        const connectionErrorCodes = ['ESOCKET', 'ETIMEOUT', 'ECONNRESET', 'ENOTOPEN'];
        const connectionErrorMessages = [
            'connection is closed',
            'connection has been closed',
            'could not connect',
            'failed to connect',
            'connection lost',
            'connection timeout'
        ];
        
        if (error.code && connectionErrorCodes.includes(error.code)) {
            return true;
        }
        
        if (error.message) {
            const msg = error.message.toLowerCase();
            return connectionErrorMessages.some(errMsg => msg.includes(errMsg));
        }
        
        return false;
    }

    //Need to pass Table Parameter in store procedure.
    public GetTaskPersonCustomerDBTableParameters() : mssql.Table {
        const table = new Table('TaskPersonCustomer'); // Table-valued parameter
        table.columns.add('taskId', VarChar);
        table.columns.add('parentId', VarChar);
        return table;     
    }
}
