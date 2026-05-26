import { Injectable } from '@nestjs/common';
// import { InternalServerErrorException } from '@nestjs/common';
// import { spawn } from 'child_process';
// import * as path from 'path';

@Injectable()
export class ReportAdminService {
    // async installPuppeteerBrowser(): Promise<{
    //     success: boolean;
    //     code: number;
    //     stdout: string;
    //     stderr: string;
    // }> {
    //     return new Promise((resolve, reject) => {
    //         const npmCmd = process.platform === 'win32' ? 'npm.cmd' : 'npm';

    //         const child = spawn(npmCmd, ['run', 'install:browser'], {
    //             cwd: this.projectRoot,
    //             env: process.env,
    //             shell: false
    //         });

    //         let stdout = '';
    //         let stderr = '';

    //         child.stdout.on('data', (data: Buffer | string) => {
    //             stdout += data.toString();
    //         });

    //         child.stderr.on('data', (data: Buffer | string) => {
    //             stderr += data.toString();
    //         });

    //         child.on('error', (error) => {
    //             reject(new InternalServerErrorException(error.message));
    //         });

    //         child.on('close', (code) => {
    //             resolve({
    //                 success: code === 0,
    //                 code: code ?? 1,
    //                 stdout,
    //                 stderr
    //             });
    //         });
    //     });
    // }

    // async installChromiumDependencies(): Promise<{
    //     success: boolean;
    //     code: number;
    //     stdout: string;
    //     stderr: string;
    //     command: string;
    // }> {
    //     return new Promise((resolve, reject) => {
    //         const command = `apt-get update && apt-get install -y ${this.chromiumDependencyPackages.join(' ')}`;
    //         const child = spawn('bash', ['-lc', command], {
    //             cwd: this.projectRoot,
    //             env: process.env,
    //             shell: false
    //         });

    //         let stdout = '';
    //         let stderr = '';

    //         child.stdout.on('data', (data: Buffer | string) => {
    //             stdout += data.toString();
    //         });

    //         child.stderr.on('data', (data: Buffer | string) => {
    //             stderr += data.toString();
    //         });

    //         child.on('error', (error) => {
    //             reject(new InternalServerErrorException(error.message));
    //         });

    //         child.on('close', (code) => {
    //             resolve({
    //                 success: code === 0,
    //                 code: code ?? 1,
    //                 stdout,
    //                 stderr,
    //                 command
    //             });
    //         });
    //     });
    // }

    // async testPuppeteerLaunch(): Promise<{
    //     success: boolean;
    //     version?: string;
    //     message: string;
    // }> {
    //     try {
    //         // eslint-disable-next-line @typescript-eslint/no-var-requires
    //         const puppeteer = require('puppeteer');
    //         const browser = await puppeteer.launch({
    //             headless: true,
    //             timeout: 60000,
    //             protocolTimeout: 60000,
    //             args: ['--no-sandbox', '--disable-dev-shm-usage']
    //         });

    //         const version = await browser.version();
    //         await browser.close();

    //         return {
    //             success: true,
    //             version,
    //             message: 'Browser launch test passed.'
    //         };
    //     } catch (error: any) {
    //         throw new InternalServerErrorException(
    //             error?.message || 'Browser launch test failed.'
    //         );
    //     }
    // }
}
