export class Question {
    public readonly id: number;
    public readonly reference: string;
    public readonly displayText: string;
    public readonly questionTypeId: number;
    public readonly inputTypeId: number;
    public readonly formId: number;
    public readonly emissionActivityId: number;
    public readonly dataType: string;
    public readonly properties: string;
    public readonly emissionActivities: string;
}

export class QuestionResponse {
    public readonly responseId: number;
    public readonly questionId: number;
    public readonly questionKey: string;
    public readonly questionTypeId: number; // Question is MBD, ConversionFactor, DataUnit, OptInPreference etc
    public readonly responseData: string;
    public readonly responseDataType: string;
    public readonly questionInputType: string;
    public readonly properties: string;
    public readonly emissionActivities: string;
}

export class ConversionInfo {
    public readonly conversionType: string;
    public readonly country: string;
    public readonly currency: string;
}

export class ConversionOutput {
    public readonly outputValue: number;
    public readonly dataUnit?: string;
    public readonly conversionFactor?: number;
}