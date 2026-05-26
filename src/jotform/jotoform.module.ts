import { Module } from "@nestjs/common";
import { JotformController } from "./jotoform.controller";
import { JotformService } from "./jotoform.service";
import { DatabaseService } from "../database";
import { NestjsFormDataModule } from "nestjs-form-data";
import { DatabaseModule } from "../database/database.module";
import { ClickupModule } from "../clickup/clickup.module";
import { CustomFieldsConstants } from "../clickup/customfields-constants";
import { ErrorLoggerModule } from "../error-logger/error-logger.module";
import { FormService } from "./form.service";
import { NCZFormService } from "./nczform.service";
import { CompanyService } from "../api/company/company.service";
import { UserService } from "../api/user/user.service";
import { CertificationService } from "../api/certification/certification.service";
import { EmailService } from "../email/email.service";
import { DocumentsModule } from "../documents/documents.module";
import { JotformDocumentService } from "./jotform-document.service";
import { EmailModule } from "../email/email.module";
import { UserModule } from "../api/user/user.module";

@Module({
  imports: [NestjsFormDataModule, DatabaseModule, ClickupModule, ErrorLoggerModule, DocumentsModule, EmailModule, UserModule],
  controllers: [JotformController],
  providers: [JotformService, FormService, NCZFormService, CompanyService, UserService, CertificationService, CustomFieldsConstants, JotformDocumentService],
  exports: [JotformService, FormService, NCZFormService],
})
export class JotformModule {}
