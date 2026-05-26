export class FileUploadRequest {
    id: any;
    parentEntityId: any;
    parentEntityType: string;
    customerId: any;
    container: string;
    blobName: string;
    title: string;
    singleInstance: boolean;
    canEmbed: boolean;
    modifiedDate: number;
    mimeType: string;
    activeTo?: number;
    userAccountId?: number;
    size?: number;
    replaceDocId?: number;
    versioningEnabled?: boolean;
    compress?: boolean;
}
