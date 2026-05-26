import { Injectable } from '@nestjs/common';
import { FirebaseAdminService } from './firebase-admin.service';
// import * as firebase from 'firebase/app';
// import * as firebaseAuth from 'firebase/auth';
// const serviceAccount = require('../../firebase/default.json');
@Injectable()
export class FirebaseAuthService {
  //private auth: firebase.FirebaseApp;

  constructor(private firebaseAdminService: FirebaseAdminService
  ) {
    // // Check if Firebase is already initialized
    // if (!firebase.getApps().length) {
    //   // Initialize Firebase SDK
    //   this.auth = firebase.initializeApp({
    //     apiKey: serviceAccount.apiKey,
    //     authDomain: serviceAccount.authDomain,
    //     projectId: serviceAccount.project_id,
    //   });
    // } else {
    //   this.auth = firebase.getApp();
    // }
  }

  // Create a new user account
  async createUser(email: string, password: string, fullName: string) {
    try {
      const userRecord = await this.firebaseAdminService.getAuth().createUser({
        email,
        password,
        displayName: fullName,
        emailVerified: false,
        disabled: false,
      });
      return userRecord;
    } catch (error) {
      throw new Error(`Error creating user: ${error.message}`);
    }
  }

  // Send email verification link
  async sendEmailVerification(email: string) { // 07May2025: Firebase client sdk will not run at server, so need to change
    try {
      const actionCodeSettings = {
        url: `${process.env.FRONTEND_URL}/verify-email`,
        handleCodeInApp: true,
      };

      const verificationLink =
        await this.firebaseAdminService
          .getAuth()
          .generateEmailVerificationLink(email, actionCodeSettings as any);

      const updatedLink = verificationLink.replace(
        'https://portal.nczgroup.com',
        process.env.FRONTEND_URL
      );

      return updatedLink;
    } catch (error) {
      throw new Error(`Error sending verification email: ${error.message}`);
    }
  }

  // Verify email with the link, (Only clientSide will work)
  // async verifyEmail(oobCode: string) {
  //   try {
  //     const auth = firebaseAuth.getAuth(this.auth);
  //     await firebaseAuth.applyActionCode(auth, oobCode);
  //     return auth.currentUser; //{ success: true, message: 'Email verified successfully' };
  //   } catch (error) {
  //     throw new Error(`Error verifying email: ${error.message}`);
  //   }
  // }

  // Change user password
  async changePassword(uid: string, newPassword: string) {
    try {
      await this.firebaseAdminService.getAuth().updateUser(uid, {
        password: newPassword,
      });
      return { success: true, message: 'Password updated successfully' };
    } catch (error) {
      throw new Error(`Error changing password: ${error.message}`);
    }
  }

  // Send password reset email using Admin SDK
  async sendPasswordResetEmail(email: string) {
    try {
      const actionCodeSettings = {
        url: `${process.env.FRONTEND_URL}/reset-password`,
        handleCodeInApp: true,
      };

      const link = await this.firebaseAdminService
        .getAuth()
        .generatePasswordResetLink(email, actionCodeSettings as any);

      const updatedLink = link.replace(
        'https://portal.nczgroup.com',
        process.env.FRONTEND_URL
      );

      return updatedLink;
    } catch (error) {
      throw new Error(`Error sending password reset email: ${error.message}`);
    }
  }

  // Change user's email
  async changeEmail(uid: string, newEmail: string) {
    try {
      await this.firebaseAdminService.getAuth().updateUser(uid, {
        email: newEmail,
        emailVerified: false,
      });
      return { success: true, message: 'Email updated successfully' };
    } catch (error) {
      throw new Error(`Error changing email: ${error.message}`);
    }
  }

  // Enable user account
  async enableUser(uid: string) {
    try {
      await this.firebaseAdminService.getAuth().updateUser(uid, {
        disabled: false,
      });
      return { success: true, message: 'User account enabled successfully' };
    } catch (error) {
      throw new Error(`Error enabling user account: ${error.message}`);
    }
  }

  // Disable user account
  async disableUser(uid: string) {
    try {
      await this.firebaseAdminService.getAuth().updateUser(uid, {
        disabled: true,
      });
      return { success: true, message: 'User account disabled successfully' };
    } catch (error) {
      throw new Error(`Error disabling user account: ${error.message}`);
    }
  }

  async getUserClaims(uid: string): Promise<Record<string, any>> {
    try {
      const userRecord = await this.firebaseAdminService.getAuth().getUser(uid);
      const claims = userRecord.customClaims || {};
      return claims;
    } catch (error) {
      throw new Error(`Error fetching user claims: ${error.message}`);
    }
  }

  // Helper method retained as no-op on server
  private async signInForOperation(email: string) {
    // No-op on server; client-side flows are not applicable here.
  }

  /**
   * Sets custom claims for a given user.
   * These claims will be included in the user's ID token
   * after they refresh or reauthenticate.
   * @param uid Firebase Auth UID of the user
   * @param claims A lightweight object containing role/permissions/etc.
   */
  async setUserClaims(uid: string, claims: Record<string, any>): Promise<{ success: boolean }> {
    try {
      await this.firebaseAdminService.getAuth().setCustomUserClaims(uid, claims);
      return { success: true };
    } catch (error) {
      throw new Error(`Error setting user claims: ${error.message}`);
    }
  }

  async getUserCompanyId(req): Promise<number | null> {
        const userId = req.user?.uid;
        if (!userId) throw new Error('Missing user ID');
        const claims = await this.getUserClaims(userId);
        const cId = claims?.cId;

        const uCompanyId =
            cId !== undefined && cId !== null && !isNaN(parseInt(cId))
                ? parseInt(cId)
                : null;

        return uCompanyId;
    }

  async deleteUserByEmail(email: string) {
    try {
      const auth = this.firebaseAdminService.getAuth();

      const userRecord = await auth.getUserByEmail(email);

      await auth.deleteUser(userRecord.uid);

      return {
        success: true,
        message: 'User deleted successfully',
        uid: userRecord.uid,
      };
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        throw new Error('User not found');
      }
      throw new Error(`Error deleting user: ${error.message}`);
    }
  }

}