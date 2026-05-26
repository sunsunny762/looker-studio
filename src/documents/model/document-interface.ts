export interface IDocument {
  id?: number,
  parentEntityId: number,
  parentEntityType: string,
  title?: string,
  mimeType: string,
  container: string,
  customerId?: number,
  canEmbed: boolean | string,
  blobName: string,
  size?: number,
  uid?: string,
}

export interface IDocumentUpload extends IDocument {
  fullName: string
}

export interface IDocumentSave extends IDocument {
  singleInstance?: boolean | string,
  ownerName?: string,
  reviewDate?: number,
  reference?: string
}

export interface IPreviewPages {
  pageNumber: number,
  width: number,
  height: number,
  prevName: string,
  words: Array<IBoundingBox>
}

export interface IBoundingBox {
  bbox: Array<number>
}
