import { Injectable, OnModuleInit } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { ApplicationUser, DecodedUserToken } from './account/model';

@Injectable()
export class FirebaseService {
    private app?: admin.app.App;
    private db?: admin.firestore.Firestore;

    public async initialise(): Promise<void> {
        const dbPath = process.env.DATABASE_URL;
        const firebaseCert = require('../firebase/default.json');
        this.app = admin.initializeApp({
            credential: admin.credential.cert(firebaseCert),
            databaseURL: dbPath
        }, 'app');
        this.db = this.app?.firestore();
    }

    public async getDocumentRef(collection: string, id: string): Promise<any> {
        return this.db?.collection(collection).doc(id);
    }

    public async backupDocument(sourceCollection: string, targetCollection: string, targetId: string): Promise<void> {
        const sourceDocumentRef = this.db?.collection(sourceCollection).doc(targetId);
        const f = await sourceDocumentRef?.get();
        if (f?.exists) {
            const data = f.data();
            const backupdoc = this.db?.collection(targetCollection).doc(targetId);                
            const result = await backupdoc?.set(data!, { merge: true });
        }
    }

    public async verifyIdToken(token?: string): Promise<DecodedUserToken | undefined> {
        if (!token) {
            return undefined;
        }
        try {
            return await this.app?.auth().verifyIdToken(token);
        } catch(e) {
            console.log('Exception', e);
            return undefined;
        }
    }

    public async getUser(uid: string): Promise<ApplicationUser | undefined> {
        if (!uid) {
            return undefined;
        }
        return await this.app?.auth().getUser(uid);
    }

    public decodedUserTokenAsUser(decodedToken?: DecodedUserToken): ApplicationUser | undefined {
        return decodedToken
            ? { 
                uid: decodedToken.uid, 
                displayName: decodedToken.name,
                email: decodedToken.email,
                phoneNumber: decodedToken.phone_number,
                emailVerified: decodedToken.email_verified===true ? true : false,
                disabled: false,
              }
            : undefined;
    }
}
