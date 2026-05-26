import { Injectable } from '@nestjs/common';
import { promises as fs } from 'fs';

@Injectable()
export class UtilitiesService {
  private _dataPath: string = `./data`;

  public get now(): number {
    return Math.floor((new Date()).getTime()/1000);
  }

  public async initialise(dataPath?: string): Promise<void> {
    if (dataPath) {
      this._dataPath = dataPath;
    }
    await this.ensurePath(this._dataPath);
  }
    public yieldObjectPath(obj: any, keys: Array<string>): any {
        if (!obj) {
          return undefined;
        }
        let currentPath = obj;
        for (const k of keys) {
          currentPath = currentPath[k];
          if (!currentPath) {
            return undefined;
          }
        }
        return currentPath;
    }
    public coalesceKey(obj: any, keyName?: string): any {
        return (obj && keyName)
          ? obj[keyName]
          : undefined;
    }
    public coalesceValues(values: Array<any>): any {
        for (const o of values) {
            if (o==0 || o) {
                return o;
            }
        }
        return undefined;
    }
    public async ensurePath(path: string): Promise<void> {
      try {
          const pathState = await fs.stat(path);
          if (pathState.isDirectory()) {
              return;
          }
      } catch(e) {

      }
      await fs.mkdir(path, { recursive: true });
    }
    public async saveToFile(content: string, filename: string): Promise<void> {
      await fs.writeFile(filename, content, 'ascii');
    }
    public async fileToString(filename: string): Promise<string> {
      return await fs.readFile(filename, 'utf8');
    }
    public async fileExists(filename: string): Promise<boolean> {
      try {
        const stat = await fs.stat(filename);
        return true;
      } catch(e) {
        return false;
      }
    }
    public async appendJsonToFile(filename: string, data: any): Promise<void> {
      const filepath = `${this._dataPath}/${filename}`;
      let readData = [];
      if (await this.fileExists(filepath)) {
        readData = JSON.parse(await this.fileToString(filepath));
      }
      readData.push(data);
      await this.saveToFile(JSON.stringify(readData), filepath);
    }
}
