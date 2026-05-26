-- ============================================================
-- Public Forms Feature
-- Creates: PublicForms, PublicFormSubmissions tables,
--          stored procedures, and application permissions
-- Date: 2026-03-20
-- ============================================================

-- ----------------------------
-- Table structure for PublicForms
-- ----------------------------

-- ----------------------------
-- Table structure for PublicForms
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[PublicForms]') AND type IN ('U'))
	DROP TABLE [portal].[PublicForms]
GO

CREATE TABLE [portal].[PublicForms] (
  [pformId] int  IDENTITY(1,1) NOT NULL,
  [displayName] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS  NULL,
  [displayOrder] smallint DEFAULT 0 NULL,
  [dimFormId] int  NULL,
  [isActive] bit DEFAULT 0 NULL,
  [displayQuestionIds] nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS  NULL
)
GO

ALTER TABLE [portal].[PublicForms] SET (LOCK_ESCALATION = TABLE)
GO

EXEC sp_addextendedproperty
'MS_Description', N'Dimension.Form.Id',
'SCHEMA', N'portal',
'TABLE', N'PublicForms',
'COLUMN', N'dimFormId'
GO

EXEC sp_addextendedproperty
'MS_Description', N'To show responses of given questionIds in grid',
'SCHEMA', N'portal',
'TABLE', N'PublicForms',
'COLUMN', N'displayQuestionIds'
GO


-- ----------------------------
-- Records of PublicForms
-- ----------------------------
BEGIN TRANSACTION
GO

SET IDENTITY_INSERT [portal].[PublicForms] ON
GO

INSERT INTO [portal].[PublicForms] ([pformId], [displayName], [displayOrder], [dimFormId], [isActive], [displayQuestionIds]) 
VALUES (N'1', N'Pricing Proposal', N'1', N'34', N'1', N'910,907'), 
(N'2', N'NCZ Partner Directory', N'2', N'35', N'1', N'945,944'), 
(N'3', N'Platinum Supplier', N'3', N'36', N'1', N'972,968')
GO

SET IDENTITY_INSERT [portal].[PublicForms] OFF
GO

COMMIT
GO


-- ----------------------------
-- Table structure for PublicFormSubmissions
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[PublicFormSubmissions]') AND type IN ('U'))
	DROP TABLE [portal].[PublicFormSubmissions]
GO

CREATE TABLE [portal].[PublicFormSubmissions] (
  [psubmissionId] int  IDENTITY(1,1) NOT NULL,
  [certId] int  NULL,
  [submissionId] bigint  NULL,
  [dateSubmitted] datetime2(7)  NULL,
  [notes] nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL,
  [isDeleted] bit DEFAULT 0 NULL,
  [dimFormId] int  NULL,
  [properties] nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT NULL NULL
)
GO

ALTER TABLE [portal].[PublicFormSubmissions] SET (LOCK_ESCALATION = TABLE)
GO

EXEC sp_addextendedproperty
'MS_Description', N'FormSubmissions.submissionId',
'SCHEMA', N'portal',
'TABLE', N'PublicFormSubmissions',
'COLUMN', N'submissionId'
GO

EXEC sp_addextendedproperty
'MS_Description', N'Dimension.Form.id',
'SCHEMA', N'portal',
'TABLE', N'PublicFormSubmissions',
'COLUMN', N'dimFormId'
GO



-- ----------------------------
-- procedure structure for spPublicForm_Get
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spPublicForm_Get]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spPublicForm_Get]
GO

CREATE PROCEDURE [portal].[spPublicForm_Get]
    @pformId    INT  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        pf.[pformId],
        pf.[dimFormId],
        pf.[displayName],
        pf.[displayOrder],
        pf.[isActive],
        COUNT(pfs.[psubmissionId]) AS [submissionCnt]
    FROM [portal].[PublicForms] pf
    LEFT JOIN [portal].[PublicFormSubmissions] pfs
        ON pfs.[dimFormId] = pf.[dimFormId]
        AND (pfs.[isDeleted] = 0 OR pfs.[isDeleted] IS NULL)
    WHERE ((@pformId     IS NULL and pf.[isActive] = 1) OR pf.[pformId]  = @pformId)
    GROUP BY
        pf.[pformId],
        pf.[dimFormId],
        pf.[displayName],
        pf.[displayOrder],
        pf.[isActive]
    ORDER BY pf.[displayOrder], pf.[displayName];
END
GO


-- ----------------------------
-- procedure structure for spPublicFormSubmission_Delete
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spPublicFormSubmission_Delete]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spPublicFormSubmission_Delete]
GO

CREATE PROCEDURE [portal].[spPublicFormSubmission_Delete]
    @psubmissionId INT,
    @deleteNotes nvarchar(100) = null
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [portal].[PublicFormSubmissions]
    SET [isDeleted] = 1,
        notes = @deleteNotes
    WHERE [psubmissionId] = @psubmissionId;
END
GO


-- ----------------------------
-- procedure structure for spPublicFormSubmission_Get
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spPublicFormSubmission_Get]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spPublicFormSubmission_Get]
GO

CREATE PROCEDURE [portal].[spPublicFormSubmission_Get]
    @dimFormId      INT,
    @psubmissionId  INT       = NULL,
    @dateFrom       DATETIME2 = NULL,
    @dateTo         DATETIME2 = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        pfs.[psubmissionId],
        pfs.[dimFormId],
        df.sourceId as formId,
        pfs.[submissionId],
        pfs.[certId],
        pfs.[dateSubmitted],
        pfs.[notes],
        pfs.[properties],
        pf.[displayName],
        STRING_AGG(
            CASE 
                WHEN q.questionLabel IS NOT NULL 
                THEN CONCAT(q.questionLabel, ':', ISNULL(sr.responseData, ''))
            END,
            ', '
        ) AS details
    FROM [portal].[PublicFormSubmissions] pfs
    INNER JOIN [portal].[PublicForms] pf ON pf.[dimFormId] = pfs.[dimFormId]
    INNER JOIN Dimension.Form as df on df.id = pf.dimFormId
    OUTER APPLY STRING_SPLIT(pf.displayQuestionIds, ',') qs
    LEFT JOIN portal.FormQuestions as q on (q.formId = df.sourceId and q.questionId = TRY_CAST(qs.value AS INT) )
    LEFT JOIN portal.FormSubmissionResponses as sr on (sr.questionId = q.questionId and sr.submissionId = pfs.submissionId)
    WHERE (pfs.[isDeleted] = 0 OR pfs.[isDeleted] IS NULL)
      AND pfs.[dimFormId]       = @dimFormId
      AND (@psubmissionId IS NULL OR pfs.[psubmissionId] = @psubmissionId)
      AND (@dateFrom      IS NULL OR CAST(pfs.[dateSubmitted] AS DATE) >= CAST(@dateFrom AS DATE))
      AND (@dateTo        IS NULL OR CAST(pfs.[dateSubmitted] AS DATE) <= CAST(@dateTo   AS DATE))
    GROUP BY
      pfs.[psubmissionId],
      pfs.[dimFormId],
      df.sourceId,
      pfs.[submissionId],
      pfs.[certId],
      pfs.[dateSubmitted],
      pfs.[notes],
      pfs.[properties],
      pf.[displayName]
    ORDER BY pfs.[dateSubmitted] DESC;
END
GO


-- ----------------------------
-- procedure structure for spPublicFormSubmission_Save
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spPublicFormSubmission_Save]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spPublicFormSubmission_Save]
GO

CREATE PROCEDURE [portal].[spPublicFormSubmission_Save]
    @dimFormId    INT,
    @submissionId BIGINT        = NULL,    -- NCZ Forms submissionId
    @certId       INT           = NULL,
    @notes        NVARCHAR(100) = NULL,
    @properties   NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [portal].[PublicFormSubmissions]
        ([dimFormId], [submissionId], [certId], [dateSubmitted], [notes], [isDeleted], [properties])
    VALUES
        (@dimFormId, @submissionId, @certId, GETDATE(), @notes, 0, @properties);

    SELECT SCOPE_IDENTITY() AS [psubmissionId];
END
GO


-- ----------------------------
-- procedure structure for spToken_Get
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spToken_Get]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spToken_Get]
GO

CREATE PROCEDURE [portal].[spToken_Get]
    @dimFormId  INT,
    @tokenType  NVARCHAR(10) = NULL,
    @activeOnly BIT          = 1
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        [tokenId],
        [tokenKey],
        [dimFormId],
        [tokenType],
        [isActive],
        [activeTo],
        [properties]
    FROM [portal].[Tokens]
    WHERE [dimFormId] = @dimFormId
      AND (@tokenType  IS NULL OR [tokenType]  = @tokenType)
      AND (@activeOnly = 0     OR [isActive]   = 1)
      AND (@activeOnly = 0     OR [activeTo] IS NULL OR [activeTo] > GETDATE())
    ORDER BY [tokenId] DESC;
END
GO


-- ----------------------------
-- procedure structure for spToken_Validate
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spToken_Validate]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spToken_Validate]
GO

CREATE PROCEDURE [portal].[spToken_Validate]
    @tokenType NVARCHAR(10),
    @tokenKey NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        tokenId,
        tokenKey,
        tokenType,
        certId,
        locationId,
        dimFormId,
        CASE 
            WHEN activeTo IS NULL THEN 0           -- not expired (no expiry)
            WHEN activeTo >= GETDATE() THEN 0      -- not expired
            ELSE 1                                 -- expired
        END AS isExpired,
        isActive, properties
    FROM [portal].[Tokens]
    WHERE ( @tokenType IS NULL OR tokenType = @tokenType ) and tokenKey = @tokenKey;
END
GO

-- ----------------------------
-- Application Feature + Option for "public-forms" (NCZUser only)
-- ----------------------------

-- Feature
IF NOT EXISTS (SELECT 1 FROM [portal].[ApplicationFeature] WHERE [name] = N'public-forms')
BEGIN
    INSERT INTO [portal].[ApplicationFeature] ([applicationId], [name], [description], [displayName])
    VALUES (1, N'public-forms', NULL, N'Public Forms');
END
GO

DECLARE @featureId INT = (SELECT [id] FROM [portal].[ApplicationFeature] WHERE [name] = N'public-forms');

-- Feature Options
IF NOT EXISTS (SELECT 1 FROM [portal].[ApplicationFeatureOption] WHERE [applicationFeatureId] = @featureId AND [name] = N'availableFromMainMenu')
BEGIN
    INSERT INTO [portal].[ApplicationFeatureOption] ([applicationFeatureId], [name], [description], [displayName])
    VALUES (@featureId, N'availableFromMainMenu', N'Public Forms', N'Public Forms');
END

IF NOT EXISTS (SELECT 1 FROM [portal].[ApplicationFeatureOption] WHERE [applicationFeatureId] = @featureId AND [name] = N'view')
BEGIN
    INSERT INTO [portal].[ApplicationFeatureOption] ([applicationFeatureId], [name], [description], [displayName])
    VALUES (@featureId, N'view', N'View Public Forms', N'View');
END

IF NOT EXISTS (SELECT 1 FROM [portal].[ApplicationFeatureOption] WHERE [applicationFeatureId] = @featureId AND [name] = N'add')
BEGIN
    INSERT INTO [portal].[ApplicationFeatureOption] ([applicationFeatureId], [name], [description], [displayName])
    VALUES (@featureId, N'add', N'Add Public Form', N'Add');
END

IF NOT EXISTS (SELECT 1 FROM [portal].[ApplicationFeatureOption] WHERE [applicationFeatureId] = @featureId AND [name] = N'edit')
BEGIN
    INSERT INTO [portal].[ApplicationFeatureOption] ([applicationFeatureId], [name], [description], [displayName])
    VALUES (@featureId, N'edit', N'Edit Public Form', N'Edit');
END

IF NOT EXISTS (SELECT 1 FROM [portal].[ApplicationFeatureOption] WHERE [applicationFeatureId] = @featureId AND [name] = N'delete')
BEGIN
    INSERT INTO [portal].[ApplicationFeatureOption] ([applicationFeatureId], [name], [description], [displayName])
    VALUES (@featureId, N'delete', N'Delete Public Form', N'Delete');
END
GO

-- ----------------------------
-- Grant all public-forms permissions to the NCZ Admin role
-- (Adjust @nczAdminRoleId to match your actual NCZ admin role id)
-- ----------------------------

    INSERT INTO [portal].[ApplicationRoleOption] ([applicationRoleId], [applicationFeatureOptionId], [available],[assignable])
    SELECT
        1, fo.[id], 1, 0
    FROM [portal].[ApplicationFeatureOption] fo
    INNER JOIN [portal].[ApplicationFeature] f ON f.[id] = fo.[applicationFeatureId]
    WHERE f.[name] = N'public-forms'
      AND f.id = 16;

INSERT INTO [portal].[ApplicationRoleOption] ([applicationRoleId], [applicationFeatureOptionId], [available],[assignable])
    SELECT
        4, fo.[id], 1, 0
    FROM [portal].[ApplicationFeatureOption] fo
    INNER JOIN [portal].[ApplicationFeature] f ON f.[id] = fo.[applicationFeatureId]
    WHERE f.[name] = N'public-forms'
      AND f.id = 16;
