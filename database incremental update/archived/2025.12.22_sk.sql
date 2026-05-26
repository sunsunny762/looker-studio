IF NOT EXISTS (
    SELECT * FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name = 'EmailNotification'
      AND s.name = 'email'
)
BEGIN
    CREATE TABLE email.EmailNotification (
        id INT IDENTITY(1,1) NOT NULL,
        fromEmail NVARCHAR(100) NULL,
        toEmail NVARCHAR(100) NOT NULL,
        messageId NVARCHAR(100) NULL,
        activeFrom DATETIME DEFAULT GETDATE() NULL,
        minimumSendDate DATETIME NULL,
        sentDate DATETIME NULL,
        sendAttemptCount INT DEFAULT 0 NULL,
        sendError NVARCHAR(MAX) NULL,
        status NVARCHAR(50) NULL,
        statusUpdatedDate DATETIME DEFAULT GETDATE() NULL,
        templateId INT NULL,
        templateData NVARCHAR(MAX) NULL,
        subject NVARCHAR(255) NULL
    );
END
GO

IF NOT EXISTS (
    SELECT * FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name = 'EmailTemplates'
      AND s.name = 'email'
)
BEGIN
    CREATE TABLE email.EmailTemplates (
        id INT IDENTITY(1,1) NOT NULL,
        templateId NVARCHAR(50) NOT NULL,
        name NVARCHAR(50) NOT NULL,
        description NVARCHAR(255) NULL,
        provider NVARCHAR(50) NULL
    );
END
GO


IF NOT EXISTS (
    SELECT * FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name = 'NczEmailTemplates'
      AND s.name = 'email'
)
BEGIN
    CREATE TABLE email.NczEmailTemplates (
        id INT IDENTITY(1,1) NOT NULL,
        name NVARCHAR(50) NOT NULL,
        subject NVARCHAR(255) NOT NULL,
        body NVARCHAR(MAX) NOT NULL,
        active BIT DEFAULT 1 NULL,
        createdDate DATETIME DEFAULT GETDATE() NULL,
        CONSTRAINT PK_NczEmailTemplates PRIMARY KEY (id)
    );
END
GO

/****** StoredProcedure [email].[spEmailNotification_Add] ******/

IF NOT EXISTS (
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[email].[spEmailNotification_Add]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC sys.sp_executesql
        N'CREATE PROCEDURE [email].[spEmailNotification_Add] AS';
END
GO

ALTER PROCEDURE [email].[spEmailNotification_Add]
    @toEmail NVARCHAR(255),
    @templateId NVARCHAR(50),
    @templateData NVARCHAR(MAX),
    @subject NVARCHAR(255) = NULL,
    @fromEmail NVARCHAR(255) = NULL,
    @minimumSendDate DATETIME = NULL,
    @status NVARCHAR(50) = 'pending'
AS
BEGIN
    SET NOCOUNT ON;

    SET @minimumSendDate = ISNULL(@minimumSendDate, SYSUTCDATETIME());

    DECLARE @Inserted TABLE (id INT);

    INSERT INTO email.EmailNotification (
        subject,
        fromEmail,
        toEmail,
        templateId,
        templateData,
        minimumSendDate,
        status,
        statusUpdatedDate
    )
    OUTPUT INSERTED.id INTO @Inserted
    VALUES (
        @subject,
        @fromEmail,
        @toEmail,
        @templateId,
        @templateData,
        @minimumSendDate,
        @status,
        SYSUTCDATETIME()
    );

    SELECT *
    FROM email.EmailNotification
    WHERE id = (SELECT TOP 1 id FROM @Inserted);
END
GO


IF NOT EXISTS (
    SELECT * FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[email].[spEmailNotification_Select]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC sp_executesql
        N'CREATE PROCEDURE [email].[spEmailNotification_Select] AS';
END
GO

ALTER PROCEDURE [email].[spEmailNotification_Select]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        id, toEmail, fromEmail,
        templateId, templateData,
        sendAttemptCount
    FROM email.EmailNotification
    WHERE status = 'pending'
      AND (minimumSendDate IS NULL OR minimumSendDate <= SYSUTCDATETIME())
    ORDER BY COALESCE(minimumSendDate, SYSUTCDATETIME()), id;
END
GO


IF NOT EXISTS (
    SELECT * FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[email].[spEmailNotification_Update]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC sp_executesql
        N'CREATE PROCEDURE [email].[spEmailNotification_Update] AS';
END
GO

ALTER PROCEDURE [email].[spEmailNotification_Update]
    @id INT = NULL,
    @messageId NVARCHAR(100) = NULL,
    @status NVARCHAR(50),
    @sendAttemptCount INT = NULL,
    @error NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @now DATETIME = SYSUTCDATETIME();

    IF @id IS NULL AND @messageId IS NOT NULL
    BEGIN
        SELECT TOP 1 @id = id
        FROM email.EmailNotification
        WHERE messageId = @messageId
        ORDER BY id DESC;
    END

    IF @id IS NULL RETURN;

    UPDATE email.EmailNotification
    SET
        messageId = COALESCE(@messageId, messageId),
        status = @status,
        sendAttemptCount = COALESCE(@sendAttemptCount, sendAttemptCount),
        sendError = @error,
        statusUpdatedDate = @now,
        sentDate = CASE
            WHEN sentDate IS NULL AND @status IN ('sent', 'delivered')
            THEN @now ELSE sentDate
        END
    WHERE id = @id;
END
GO


IF NOT EXISTS (
    SELECT * FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[email].[spEmailNotification_UpdateByMessageId]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC sp_executesql
        N'CREATE PROCEDURE [email].[spEmailNotification_UpdateByMessageId] AS';
END
GO

ALTER PROCEDURE [email].[spEmailNotification_UpdateByMessageId]
    @messageId NVARCHAR(255),
    @status NVARCHAR(50),
    @error NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @now DATETIME = SYSUTCDATETIME();

    UPDATE email.EmailNotification
    SET
        status = @status,
        sendError = @error,
        statusUpdatedDate = @now,
        sentDate = CASE
            WHEN sentDate IS NULL AND @status IN ('sent', 'delivered')
            THEN @now ELSE sentDate
        END
    WHERE messageId = @messageId;
END
GO



IF NOT EXISTS (
    SELECT * FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[email].[spEmailTemplate_GetById]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC sp_executesql
        N'CREATE PROCEDURE [email].[spEmailTemplate_GetById] AS';
END
GO

ALTER PROCEDURE [email].[spEmailTemplate_GetById]
    @id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        et.id, et.templateId, et.name, et.provider,
        nt.subject, nt.body
    FROM email.EmailTemplates et
    LEFT JOIN email.NczEmailTemplates nt
        ON et.provider = 'ncz'
       AND CAST(nt.id AS NVARCHAR(50)) = et.templateId
       AND nt.active = 1
    WHERE et.id = @id;
END
GO


IF NOT EXISTS (
    SELECT * FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[email].[spEmailTemplate_GetByName]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC sp_executesql
        N'CREATE PROCEDURE [email].[spEmailTemplate_GetByName] AS';
END
GO

ALTER PROCEDURE [email].[spEmailTemplate_GetByName]
    @name NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        et.id, et.templateId, et.name,
        et.description, et.provider,
        nt.subject, nt.body
    FROM email.EmailTemplates et
    INNER JOIN email.NczEmailTemplates nt
        ON CAST(nt.id AS NVARCHAR(50)) = et.templateId
    WHERE et.name = @name
      AND et.provider = 'ncz'
      AND nt.active = 1;
END
GO

/****** StoredProcedure [email].[spNczEmailTemplate_Get] ******/
IF NOT EXISTS (
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[email].[spNczEmailTemplate_Get]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC dbo.sp_executesql
        @statement = N'CREATE PROCEDURE [email].[spNczEmailTemplate_Get] AS';
END
GO

ALTER PROCEDURE [email].[spNczEmailTemplate_Get]
(
    @id INT
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        id,
        subject,
        body
    FROM email.NczEmailTemplates
    WHERE id = @id
      AND active = 1;
END
GO

/****** StoredProcedure [portal].[spUser_Delete] ******/
IF NOT EXISTS (
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[portal].[spUser_Delete]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC dbo.sp_executesql
        @statement = N'CREATE PROCEDURE [portal].[spUser_Delete] AS';
END
GO

ALTER PROCEDURE [portal].[spUser_Delete]
(
    @userId INT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @email NVARCHAR(255);

    SELECT @email = email
    FROM portal.Users
    WHERE userId = @userId;

    UPDATE portal.Users
    SET
        isDeleted = 1,
        dateUpdated = CURRENT_TIMESTAMP
    WHERE userId = @userId;

    SELECT @email AS email;
END
GO

/****** Insert Email Templates into email.NczEmailTemplates ******/

-- =========================
-- RESET_PASSWORD
-- =========================
IF NOT EXISTS (
    SELECT 1
    FROM email.NczEmailTemplates
    WHERE name = 'RESET_PASSWORD'
)
BEGIN
    INSERT INTO email.NczEmailTemplates (
        name,
        subject,
        body,
        active,
        createdDate
    )
    VALUES (
        'RESET_PASSWORD',
        'Reset your password for Neutral Carbon Zone',
        N'<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8" />
  <title>Reset your password for Neutral Carbon Zone</title>
</head>

<body style="margin:0; padding:0; background-color:#1e3a2f; font-family: Arial, Helvetica, sans-serif;">

<table width="100%" cellpadding="0" cellspacing="0"
  background="https://ncz-staging.firebaseapp.com/assets/images/backgrounds/email-backgroud.png"
  style="
    background-color:#1e3a2f;
    background-image:url(''https://ncz-staging.firebaseapp.com/assets/images/backgrounds/email-backgroud.png'');
    background-repeat:no-repeat;
    background-position:center;
    background-size:cover;
  "
>
<tr>
<td align="center">

<table width="100%" cellpadding="0" cellspacing="0">
  <tr>
    <td height="60" style="line-height:60px; font-size:0;">&nbsp;</td>
  </tr>
</table>

<table width="420" cellpadding="0" cellspacing="0"
  style="background:#ffffff; border-radius:10px; overflow:hidden; box-shadow:0 6px 24px rgba(0,0,0,0.15);">

  <tr>
    <td align="center" style="padding:24px 24px 12px;">
      <img src="https://ncz-staging.firebaseapp.com/assets/images/logos/brand-logo-email.png"
           alt="NCZ" width="100" style="display:block;" />
    </td>
  </tr>

  <tr>
    <td style="padding:20px 32px; color:#333333;">
      <p>Hello <strong>{{fullName}}</strong>,</p>

      <p>
        Follow this link to reset your NCZ portal password for your
        <strong>{{email}}</strong> account.
      </p>

      <p style="text-align:center;">
        <a href="{{resetLink}}"
           style="background:#27436b; color:#ffffff; text-decoration:none;
                  padding:14px 26px; border-radius:6px; display:inline-block;">
          Click here to reset your password
        </a>
      </p>

      <p>If you didn’t ask to reset your password, you can ignore this email.</p>

      <p>Thanks,<br /><strong>Your NCZ team</strong></p>
    </td>
  </tr>

</table>

<table width="420">
  <tr>
    <td style="padding:16px; text-align:center; font-size:11px; color:#ffffff;">
      © NCZ Portal. All rights reserved.
    </td>
  </tr>
</table>

</td>
</tr>
</table>
</body>
</html>',
        1,
        SYSUTCDATETIME()
    );
END
GO

-- =========================
-- VERIFY_EMAIL Reset your password for Neutral Carbon Zone
-- =========================
IF NOT EXISTS (
    SELECT 1
    FROM email.NczEmailTemplates
    WHERE name = 'VERIFY_EMAIL'
)
BEGIN
    INSERT INTO email.NczEmailTemplates (
        name,
        subject,
        body,
        active,
        createdDate
    )
    VALUES (
        'VERIFY_EMAIL',
        'Verify your email and set password for Neutral Carbon Zone',
        N'<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8" />
  <title>Verify your email and set password for Neutral Carbon Zone</title>
</head>

<body style="margin:0; padding:0; background-color:#1e3a2f; font-family: Arial, Helvetica, sans-serif;">

<table width="100%" cellpadding="0" cellspacing="0"
  background="https://ncz-staging.firebaseapp.com/assets/images/backgrounds/email-backgroud.png"
  style="
    background-color:#1e3a2f;
    background-image:url(''https://ncz-staging.firebaseapp.com/assets/images/backgrounds/email-backgroud.png'');
    background-repeat:no-repeat;
    background-position:center;
    background-size:cover;
  "
>
<tr>
<td align="center">

<table width="100%" cellpadding="0" cellspacing="0">
  <tr>
    <td height="60" style="line-height:60px; font-size:0;">&nbsp;</td>
  </tr>
</table>

<table width="420" cellpadding="0" cellspacing="0"
  style="background:#ffffff; border-radius:10px; overflow:hidden; box-shadow:0 6px 24px rgba(0,0,0,0.15);">

  <tr>
    <td align="center" style="padding:24px 24px 12px;">
      <img src="https://ncz-staging.firebaseapp.com/assets/images/logos/brand-logo-email.png"
           alt="NCZ" width="100" style="display:block;" />
    </td>
  </tr>

  <tr>
    <td style="padding:20px 32px; color:#333333;">
      <p>Hello <strong>{{fullName}}</strong>,</p>

      <p>
        Thank you for creating an account. Please confirm your email address to
        activate your NCZ portal access.
      </p>

      <p style="text-align:center;">
        <a href="{{verificationLink}}"
           style="background:#27436b; color:#ffffff; text-decoration:none;
                  padding:14px 26px; border-radius:6px; display:inline-block;">
          Click here to verify your email address
        </a>
      </p>

      <p>If you didn’t create this account, you can safely ignore this email.</p>

      <p>Thanks,<br /><strong>Your NCZ team</strong></p>
    </td>
  </tr>

</table>

<table width="420">
  <tr>
    <td style="padding:16px; text-align:center; font-size:11px; color:#ffffff;">
      © NCZ Portal. All rights reserved.
    </td>
  </tr>
</table>

</td>
</tr>
</table>
</body>
</html>',
        1,
        SYSUTCDATETIME()
    );
END
GO

/****** Insert Email Templates into email.EmailTemplates ******/

-- =========================
-- RESET_PASSWORD_NCZ
-- =========================
IF NOT EXISTS (
    SELECT 1
    FROM email.EmailTemplates
    WHERE name = 'RESET_PASSWORD_NCZ'
      AND provider = 'ncz'
)
BEGIN
    INSERT INTO email.EmailTemplates (
        templateId,
        name,
        description,
        provider
    )
    VALUES (
        '1',
        'RESET_PASSWORD_NCZ',
        'Password reset email template',
        'ncz'
    );
END
GO

-- =========================
-- VERIFY_EMAIL_NCZ
-- =========================
IF NOT EXISTS (
    SELECT 1
    FROM email.EmailTemplates
    WHERE name = 'VERIFY_EMAIL_NCZ'
      AND provider = 'ncz'
)
BEGIN
    INSERT INTO email.EmailTemplates (
        templateId,
        name,
        description,
        provider
    )
    VALUES (
        '2',
        'VERIFY_EMAIL_NCZ',
        'Email verification template for new users',
        'ncz'
    );
END
GO

-- =========================
-- RESET_PASSWORD_SG (SendGrid)
-- =========================
IF NOT EXISTS (
    SELECT 1
    FROM email.EmailTemplates
    WHERE name = 'RESET_PASSWORD_SG'
      AND provider = 'sendgrid'
)
BEGIN
    INSERT INTO email.EmailTemplates (
        templateId,
        name,
        description,
        provider
    )
    VALUES (
        'd-a5a825e6a76a44f1a926f419e0753ebf',
        'RESET_PASSWORD_SG',
        'Password reset email template (SendGrid)',
        'sendgrid'
    );
END
GO




