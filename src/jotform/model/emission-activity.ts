export class EmissionActivity {
    public entityId: number;
    public entityTypeId: number;
    public submissionId: number;
    public emissionActivityId: number;
    public userInput: number;
    public month: number;
    public year: number;
    public optedIn?: boolean;
    public conversionFactor: number;
    public managementBasedDecision?: boolean
    public reportingFrequencyId?: number
    public dataUnit?: string
    public questionId?: number
    
    constructor(entityId: number, entityTypeId: number, submissionId: number, emissionActivityId: number, userInput: number, month: number,
        conversionFactor: number, reportingFrequencyId: number, dataUnit: string, optedIn?: boolean, managementBasedDecision?: boolean, questionId?: number) {
        this.entityId = entityId;
        this.entityTypeId = entityTypeId;
        this.submissionId = submissionId;
        this.emissionActivityId = emissionActivityId;
        this.userInput = userInput;
        this.month = month;
        this.conversionFactor = conversionFactor;
        this.optedIn = optedIn;
        this.managementBasedDecision = managementBasedDecision;
        this.reportingFrequencyId = reportingFrequencyId;
        this.dataUnit = dataUnit;
        this.questionId = questionId;
    }

    public async processEmissionctivity() {
        
    }
}