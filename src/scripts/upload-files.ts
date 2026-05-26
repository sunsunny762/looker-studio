import { DocumentsService } from '../documents/documents.service';
import { DatabaseService } from '../database';
import { FileUploadRequest } from '../documents/model';
import * as dotenv from 'dotenv';
import * as path from 'path';
import * as mime from 'mime-types';

// Created to upload certification documents to cloud storage and database
// To run: npx ts-node src/scripts/upload-files.ts
async function uploadFiles() {
    try {
        const result = dotenv.config({ path: path.resolve(__dirname, '../../.env') });
        // Initialize services with proper connection
        const dbService = new DatabaseService();
        await dbService.initialise();
        if (dbService.isConnected === false) {
            console.error('Database connection failed.');
            return;
        }
        const docService = new DocumentsService(dbService);

        // Add debug logging
        console.debug('Database service initialized:', dbService);

        // File details to upload
        const files = [
                        {
                            fileName: 'S1. Journey Silver Award - social template.png',
                            parentEntityId: 2,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'S1. Journey Silver Award Announcement Guide.pdf',
                            parentEntityId: 2,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'S2. Completed Silver Award - digital badge.png',
                            parentEntityId: 2,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'S2. Completed Silver Award Marketing Guide.pdf',
                            parentEntityId: 2,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'S2. Completed Silver-award-ALL-white.png',
                            parentEntityId: 2,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'S2. Completed Silver-award-black.png',
                            parentEntityId: 2,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'S2. Completed Silver-award-white.png',
                            parentEntityId: 2,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'S3. CN-silver-black.png',
                            parentEntityId: 2,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'S3. CN-silver-digital-badge.png',
                            parentEntityId: 2,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'S3. CN-silver-white.png',
                            parentEntityId: 2,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },

                        {
                            fileName: 'G1. Journey Gold Certification Announcement Guide.pdf',
                            parentEntityId: 3,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'G1. Journey Gold Certification- social template.png',
                            parentEntityId: 3,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'G2. Completed - Gold Certification Marketing Guide.pdf',
                            parentEntityId: 3,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'G2. Completed Gold Certification - digital badge.png',
                            parentEntityId: 3,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'G2. Completed Gold Certification - social template.png',
                            parentEntityId: 3,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'G2. Completed-Certified Gold-ALL-white-NCZ.png',
                            parentEntityId: 3,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'G2. Completed-Certified-Gold-NCZ.png',
                            parentEntityId: 3,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'G2. Completed-Certified-Gold-white-NCZ.png',
                            parentEntityId: 3,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'G3. CN Gold Certification - digital badge.png',
                            parentEntityId: 3,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'G3. CN Gold Certification - social template.png',
                            parentEntityId: 3,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'G3. CN Gold Certification Marketing Guide.pdf',
                            parentEntityId: 3,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'G3. CN-gold-black.png',
                            parentEntityId: 3,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'G3. CN-gold-white.png',
                            parentEntityId: 3,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },

                        {
                            fileName: 'P1. Journey Platinum Certification Announcement Guide.pdf',
                            parentEntityId: 4,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'P1. Journey Platinum Certification- social template.png',
                            parentEntityId: 4,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'P2. Completed - Platinum Certification Marketing Guide.pdf',
                            parentEntityId: 4,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'P2. Completed Platinum Certification - digital badge.png',
                            parentEntityId: 4,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'P2. Completed Platinum Certification - social template.png',
                            parentEntityId: 4,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'P2. Completed Platinum-dark-font-transparent1.png',
                            parentEntityId: 4,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'P2. Completed Platinum-with-white-font-transparent.png',
                            parentEntityId: 4,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'P3. CN Platinum Certification - digital badge.png',
                            parentEntityId: 4,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'P3. CN Platinum Certification - social template.png',
                            parentEntityId: 4,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'P3. CN Platinum Certification Marketing Guide.pdf',
                            parentEntityId: 4,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'P3. CN-platinum-black.png',
                            parentEntityId: 4,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'P3. CN-platinum-white.png',
                            parentEntityId: 4,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },

                        {
                            fileName: 'NCZ Brand Guideline.pdf',
                            parentEntityId: 2,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'NCZ Brand Guideline.pdf',
                            parentEntityId: 3,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        },
                        {
                            fileName: 'NCZ Brand Guideline.pdf',
                            parentEntityId: 4,
                            parentEntityType: 'certification-prog',
                            customerId: 0
                        }
        ];

        console.log('Starting file upload process...');

        for (const file of files) {
            try {
                const mimeType = mime.lookup(file.fileName) || 'application/octet-stream';
                
                const request: FileUploadRequest = {
                    id: null, // or undefined/null if allowed, or generate as needed
                    parentEntityId: file.parentEntityId,
                    parentEntityType: file.parentEntityType,
                    customerId: file.customerId,
                    mimeType: mimeType,
                    title: path.basename(file.fileName),
                    container: 'certification-docs',
                    blobName: file.fileName, // or generate as needed
                    singleInstance: false, // or set as appropriate
                    canEmbed: false, // or set as appropriate
                    modifiedDate: Date.now() // or set as appropriate
                };

                // Add debug logging
                console.debug('Upload request:', JSON.stringify(request, null, 2));
                
                console.log(`Uploading ${file.fileName}...`);
                const result = await docService.uploadLocalFile(file.fileName, request);
                // Add breakpoint here to inspect result
                
                if (result) {
                    console.log(`Successfully uploaded ${file.fileName}`);
                    console.log('Document ID:', result.id);
                } else {
                    console.log(`Failed to upload ${file.fileName}`);
                }
            } catch (error) {
                console.error(`Error uploading ${file.fileName}:`, error);
                // Add breakpoint here to inspect error
            }
        }
    } catch (error) {
        console.error('Failed to initialize services:', error);
    } finally {
        // Cleanup database connection
        // const dbService = new DatabaseService();
        // await dbService.disconnect();
    }
}

// Run the upload process
uploadFiles().catch(console.error);