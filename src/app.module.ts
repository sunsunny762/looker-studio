import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { AppController } from './app.controller';
import { PreauthMiddleWare } from './auth/preauth.middleware';
import { FirebaseService } from './firebase.service';
import { UtilitiesService } from './utilities/utilities.service';
import { AccountController } from './account/account.controller';
import { AccountService } from './account/account.service';
import { SchedulerService } from './scheduler/scheduler.service';
import { DatabaseService } from './database/database.service';
import { ServerBasicAuthMiddleWare } from './auth/server-basic-auth.middleware';
import { JotformModule } from './jotform/jotoform.module';
import { ClickupModule } from './clickup/clickup.module';
import { DatabaseModule } from './database/database.module';
import { CurrencyModule } from './currency/currency.module';
import { SchedulerModule } from './scheduler/scheduler.module';
import { ErrorLoggerModule } from './error-logger/error-logger.module';
import { ErrorLoggerService } from './error-logger/error-logger.service';
import { EmailService } from './email/email.service';
import { PowerbiModule } from './powerbi/powerbi.module';
import { PowerbiService } from './powerbi/powerbi.service';
import { DocumentsService } from './documents/documents.service';
import { DocumentsModule } from './documents/documents.module';
import { CompanyModule } from './api/company/company.module';
import { CertificationModule } from './api/certification/certification.module';
import { ReportModule } from './api/report/report.module';
import { DropdownItemsModule } from './api/dropdownitems/dropdownitems.module';
import { UserModule } from './api/user/user.module';
import { LocationModule } from './api/location/location.module';
import { SubmissionModule } from './api/submission/submission.module';
import { FuelPriceModule } from './fuel-price/fuel-price.module';
import { SupplyChainModule } from './api/supply-chain/supply-chain.module';
import { NczformsModule } from './api/nczforms/nczforms.module';
import { NczformsController } from './api/nczforms/nczforms.controller';
import { NczformsService } from './api/nczforms/nczforms.service';
import { FirebaseAuthService } from './firebase/firebase-auth.service';
import { FirebaseAdminService } from './firebase/firebase-admin.service';
import { FirebaseModule } from './firebase/firebase.module';
//import { ToolsModule } from './api/tools/tools.module';
import { EmailModule } from './email/email.module';
import { TokenModule } from './api/token/token.module';
import { ReportDataModule } from './reportData/reportData.module';
import { NotificationsModule } from './notifications/notifications.module';
import { PublicFormsModule } from './api/public-forms/public-forms.module';
import { CartModule } from './api/cart/cart.module';
import { WebinarModule } from './api/webinar/webinar.module';
import { EmailUnsubscriptionModule } from './api/email-unsubscription/email-unsubscription.module';
import { NpsModule } from './api/nps/nps.module';
import { LoginNotificationModule } from './api/login-notification/login-notification.module';

@Module({
  imports: [
    JotformModule,
    ClickupModule,
    CurrencyModule,
    DatabaseModule,
    SchedulerModule,
    ErrorLoggerModule,
    PowerbiModule,
    ReportDataModule,
    DocumentsModule,
    CompanyModule,
    LocationModule,
    CertificationModule,
    ReportModule,
    DropdownItemsModule,
    UserModule,
    SubmissionModule,
    FuelPriceModule,
    SupplyChainModule,
    FirebaseModule,
    NczformsModule,
    EmailModule,
    //ToolsModule,
    TokenModule,
    NotificationsModule,
    PublicFormsModule,
    CartModule,
    WebinarModule,
    EmailUnsubscriptionModule,
    NpsModule,
    LoginNotificationModule,],
  controllers: [AppController, AccountController, NczformsController],
  providers: [
    UtilitiesService,
    AccountService,
    SchedulerService,
    DatabaseService,
    ErrorLoggerService,
    EmailService,
    PowerbiService,
    DocumentsService,
    FirebaseService, NczformsService,
    FirebaseAdminService,
    FirebaseAuthService
  ],
  exports: [FirebaseAdminService, FirebaseAuthService],
})
export class AppModule implements NestModule {
  preAuthExcludes = [
    '/',
    '/keepalive',
    '/jotform/certification/response',
    '/jotform/customerprofile/response',
    '/jotform/events/response',
    '/clickup/taskDelete/Webhook',
    '/clickup/taskMoved/Webhook',
    '/clickup/taskCreated/Webhook',
    '/users/verify-email',
    '/users/send-verification',
    '/users/set-password',
    '/users/reset-password',
    '/token/validate/(.*)',
    '/public/submissions/details/:certsubmissionId',
    '/public/submissions/blueaward',
    '/public/submissions/chw',
    '/public/submissions/nczdirectory-supplier',
    '/public/submissions',
    '/public/form-submissions',
    '/public/nczforms/submission',
    '/public/nczforms/submission/:submissionId',
    '/public/nczforms/:formId/config',
    '/public/nczforms/dimform/:dimFormId',
    '/public/nczforms/countries/search',
    '/public/nczforms/currencies/search',
    '/public/nczforms/documents/upload',
    '/public/nczforms/documents/upload-multiple',
    '/public/nczforms/documents/download/:documentId',
    '/public/nczforms/documents/:documentId',
    '/public/nczforms/documents/submission/:certSubmissionId/question/:questionId',
    '/public/blueawards/download/:documentId',
    '/public/blueawards/:certSubmissionId',
    '/report/looker-studio/blue-award/merged-download',
    '/report/install-browser',
    '/report/install-browser-deps',
    '/report/check-browser',
    '/test/broadcast-blue-award/:count',
    // Public cart endpoints (guest checkout + Stripe webhook)
    '/public/cart/validate-coupon',
    '/public/cart/checkout-session',
    '/public/cart/session/:sessionId/verify',
    '/cart/validate-coupon',
    '/cart/checkout-session',
    '/cart/config/:cartConfigId',
    '/cart/session/:sessionId/verify',
    '/cart/webhook/stripe',
    '/webinars/public/booking-form/(.*)',
    '/webinars/public/resolve-wid/(.*)',
    '/webinars/public/bookings',
    '/email-unsubscriptions',
    '/email-unsubscriptions/check',
    '/email-unsubscriptions/resubscribe',
  ];
  serverAuthExcludes = [
    ...this.preAuthExcludes,
    '/companies',
    '/companies/ncz-directory',
    '/companies/ncz-directory/:dirItemId',
    '/companies/upload-logo',
    '/companies/:companyId',
    //'/companies/customer-directory/:companyId',
    '/certifications',
    '/certifications/:certId',
    '/certifications/blueawards/:certSubmissionId/status',
    '/certifications/blueawards/:certSubmissionId',
    '/certifications/blueawards/:certSubmissionId/documents',
    '/certifications/blueawards/documents/upload',
    '/certifications/blueawards/:certSubmissionId/documents/deleteFile/:documentId',
    '/certifications/blueawards/count',
    '/certifications/blueawards',
    //'/certifications/submissions/:certId',
    '/certifications/documents/:certId',
    '/certifications/documents/download/:documentId',
    '/certifications/documents/view/:documentId',
    '/certifications/documents/upload',
    '/certifications/documents/add',
    '/certifications/documents/deleteFile/:certId/:documentId',
    '/certifications/documents/delete/:certId/:documentId',
    '/certifications/documents/standard/:progId/:certId',
    '/certifications/company/:companyId',
    '/certifications/chw-tokens/:certId',
    '/certifications/headcount/:certId',
    '/report/week-status-report',
    '/report/week-status-report/:companyId',
    '/report/supplier-week-status-report',
    '/report/supplier-week-status-report/:companyId',
    '/report/certification-all-status-report',
    '/report/certification-all-status-report/:companyId',
    '/report/report-issued-week-status-report',
    '/report/report-issued-week-status-report/:companyId',
    '/report/certification-report-data',
    '/report/report-issued-data',
    '/report/supplier-report-data',
    '/report/blue-award/send-email',
    '/report/looker-studio/blue-award/merged-download',
    '/supply-chain/documents/:companyId',
    '/supply-chain/suppliers/:companyId',
    '/supply-chain/suppliers',
    '/supply-chain/documents',
    '/supply-chain/suppliers/delete/:supplierId',
    '/supply-chain/suppliers/save',
    '/supply-chain/documents/download/:documentId',
    '/supply-chain/documents/view/:documentId',
    '/supply-chain/documents/upload',
    '/supply-chain/documents/import-data',
    '/supply-chain/documents/add',
    '/supply-chain/documents/deleteFile/:companyId/:documentId',
    '/supply-chain/documents/delete/:companyId/:documentId',
    '/supply-chain/documents/process/:companyId/:documentId',
    '/locations',
    '/locations/upload-logo',
    '/locations/:locId',
    '/locations/company/:companyId',
    '/dropdownitems/:groupId',
    '/dropdownitems/:groupId/:certId',
    '/dropdownitems/company',
    '/dropdownitems/company/:companyId',
    '/dropdownitems/prog',
    '/dropdownitems/prog/:progId',
    '/dropdownitems/role/:companyId',
    '/dropdownitems/role/:companyId/:roleId',
    '/dropdownitems/form/:progId',
    '/dropdownitems/country',
    '/dropdownitems/currency',
    '/dropdownitems/location/:certId',
    '/dropdownitems/location/cmp/:certId', // For Company Profile submission only
    '/dropdownitems/emission-profile/:emissionProfileId?',
    '/submissions',
    '/submissions/:certId',
    '/submissions/replace-cmp', // Special handling for Company Profile replacement
    '/submissions/tiles/:certId/:locId?',
    '/submissions/documents/:certId',
    '/submissions/documents/download/:documentKey',
    '/submissions/documents/download-zip',
    '/submissions/all-forms/:certId',
    '/submissions/other-submission-tiles/:certId',
    '/submissions/progform/:certId/:progformId/:locId?',
    '/submissions/other-progform/:certId/:progformId',
    '/submissions/chw/:certId',
    '/submissions/details/:certsubmissionId',
    '/submissions/emission-detail/:certsubmissionId/:emissionProfileId',
    '/submissions/jotform/:certsubmissionId',
    '/jotform/file/:submissionId',
    '/jotform/ingest/:certsubmissionId',
    '/users',
    '/users/:userId',
    '/users/check-email',
    '/nczforms/submission',
    '/nczforms/submission/:submissionId',
    '/nczforms/submissions/user/:userId',
    '/nczforms/submissions/form/:formId',
    '/nczforms/submission/:submissionId/draft',
    '/nczforms/submission/:submissionId/submit',
    '/nczforms/:formId/config',
    '/nczforms/documents/upload',
    '/nczforms/documents/upload-multiple',
    '/nczforms/documents/submission/:certSubmissionId/question/:questionId',
    '/nczforms/documents/download/:documentId',
    '/nczforms/documents/:documentId',
    '/nczforms/airports/search',
    '/nczforms/countries/search',
    '/nczforms/currencies/search',
    '/public-forms',
    '/public-forms/:dimFormId/download-zip',
    '/public-forms/:dimFormId/submissions',
    '/public-forms/:dimFormId/submissions/:psubmissionId',
    '/account/me',
    '/token',
    '/token/:tokenId',
    '/tools',
    '/tools/:toolId',
    '/tools/:toolId/execute',
    // Authenticated cart endpoints (Firebase auth via portal)
    '/cart/payment/submission/:submissionId',
  ];
  configure(consumer: MiddlewareConsumer) {
    consumer
      .apply(PreauthMiddleWare)
      .exclude(...this.preAuthExcludes)
      .forRoutes('*');

    consumer
      .apply(ServerBasicAuthMiddleWare)
      .exclude(...this.serverAuthExcludes)
      .forRoutes('*');
  }
}
