import { Module } from '@nestjs/common';
import { FirebaseAuthService } from './firebase-auth.service';
import { FirebaseAdminService } from './firebase-admin.service';

@Module({
  providers: [FirebaseAuthService, FirebaseAdminService],
  exports: [FirebaseAuthService, FirebaseAdminService],
})
export class FirebaseModule {}