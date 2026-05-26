export class QueryResponse {
    public recordsets: any[][] = [];        // All result sets
    public results: Array<any> = [];
    public rowsAffected: number = 0;
    public columns: any;

    constructor(data: any) {
        this.recordsets = data.recordsets || [];
        this.results = data.recordset||[];
        this.rowsAffected = data.rowsAffected||0;
        this.columns = data.recordset?.columns || {}
    }

    public get singleResult(): any {
        let result = this.results ? this.results[0] : {}
        if (result && this.columns) {
            for (let k in result) {
                result[k] = this._rationaliseOutputParameter(k, result[k], this.columns);
            }
        }
        return result;
    }

    private _rationaliseOutputParameter(key: string, value: any, columnDefinitions: any): any {
        if (value===undefined||value===null||!columnDefinitions||!key) {
            return value;
        }
        const definition = columnDefinitions[key];
        if (definition && definition.type.name === "BigInt") {
            return parseInt(value);
        }
        if (definition?.type?.name === "Bit") {
            return value === true || value === 1;
        }
        return value;
    }
}