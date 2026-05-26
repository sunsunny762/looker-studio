// src/firebaseuser/firebaseuser.service.ts
import { Injectable } from '@nestjs/common';
import { FirebaseAuthService } from '../../firebase/firebase-auth.service';

@Injectable()
export class FirebaseUserService {
  constructor(private readonly firebaseAuthService: FirebaseAuthService) {}

  // async getUserByEmail(email: string) {
  //     return this.firebaseAuthService.getUserByEmail(email);
  // }
  async createUser(email: string, password: string, fullName: string) {
    return await this.firebaseAuthService.createUser(email, password, fullName);
  }

  async sendEmailVerification(email: string) {
    return this.firebaseAuthService.sendEmailVerification(email);
  }

  async deleteUserByEmail(email: string) {
    return this.firebaseAuthService.deleteUserByEmail(email);
  }

  // async verifyEmail(actionCode: string) {
  //   return this.firebaseAuthService.verifyEmail(actionCode);
  // }

  async changePassword(uId: string, newPassword: string) {
    return this.firebaseAuthService.changePassword(uId, newPassword);
  }

  async sendPasswordResetEmail(email: string) {
    return this.firebaseAuthService.sendPasswordResetEmail(email);
  }

  async changeEmail(uid: string, newEmail: string) {
    return this.firebaseAuthService.changeEmail(uid, newEmail);
  }

  async enableUser(uid: string) {
    return this.firebaseAuthService.enableUser(uid);
  }

  async disableUser(uid: string) {
    return this.firebaseAuthService.disableUser(uid);
  }
}