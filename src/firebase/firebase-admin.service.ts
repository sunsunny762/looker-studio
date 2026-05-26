import { Injectable, OnModuleInit } from '@nestjs/common';
import * as admin from 'firebase-admin';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class FirebaseAdminService implements OnModuleInit {
  onModuleInit() {
    if (!admin.apps.length) {
      const serviceAccountPath = path.resolve(__dirname, '../../firebase/default.json');
      if (!fs.existsSync(serviceAccountPath)) {
        console.warn('Firebase Admin credentials not found. Firebase Admin initialization skipped.');
        return;
      }

      try {
        const serviceAccount = require(serviceAccountPath);
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount as admin.ServiceAccount),
        });
        console.log('Firebase Admin initialized successfully');
      } catch (error) {
        console.error('Firebase Admin initialization error:', error);
        throw error;
      }
    }
  }

  getAuth() {
    if (!admin.apps.length) {
      throw new Error('Firebase Admin is not initialized.');
    }
    return admin.auth();
  }
}
