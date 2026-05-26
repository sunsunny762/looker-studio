-- =============================================================
-- NPS Feature - 2026.05.06_rb
-- 1. Add isCertificationDocument flag to CertDocuments
-- 2. Create portal.NPS table
-- 3. Create stored procedures for NPS
-- 4. Update spCertificationDocument_Save to handle isCertificationDocument
-- 5. Update spCertification_Get to return npsSubmitted flag
-- =============================================================

-- 1. Add isCertificationDocument column to CertDocuments junction table
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'portal' AND TABLE_NAME = 'CertDocuments'
    AND COLUMN_NAME = 'isCertificationDocument'
)
BEGIN
    ALTER TABLE [portal].[CertDocuments]
    ADD [isCertificationDocument] BIT NOT NULL DEFAULT 0;
END
GO

-- 2. Create NPS table
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'portal' AND TABLE_NAME = 'NPS'
)
BEGIN
    CREATE TABLE [portal].[NPS] (
        [npsId]       INT IDENTITY(1,1) NOT NULL,
        [certId]      INT NOT NULL,
        [score]       INT NOT NULL,
        [reason]      NVARCHAR(MAX) NULL,
        [submittedAt] DATETIME NOT NULL CONSTRAINT [DF_NPS_submittedAt] DEFAULT (GETUTCDATE()),
        CONSTRAINT [PK_NPS] PRIMARY KEY CLUSTERED ([npsId]),
        CONSTRAINT [FK_NPS_Certification] FOREIGN KEY ([certId])
            REFERENCES [portal].[Certification] ([certId]),
        CONSTRAINT [UQ_NPS_certId] UNIQUE ([certId]),
        CONSTRAINT [CK_NPS_score] CHECK ([score] >= 0 AND [score] <= 10)
    );
END
GO

-- 3. spNPS_Save - insert NPS for a certification (one per cert enforced by UNIQUE constraint)
CREATE OR ALTER PROCEDURE [portal].[spNPS_Save]
    @certId  INT,
    @score   INT,
    @reason  NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM [portal].[NPS] WHERE [certId] = @certId)
    BEGIN
        RAISERROR('NPS already submitted for this certification.', 16, 1);
        RETURN;
    END

    INSERT INTO [portal].[NPS] ([certId], [score], [reason])
    VALUES (@certId, @score, @reason);

    SELECT SCOPE_IDENTITY() AS npsId;
END
GO

-- 4. spNPS_GetByCert - check if NPS has been submitted for a given certId
CREATE OR ALTER PROCEDURE [portal].[spNPS_GetByCert]
    @certId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        n.[npsId],
        n.[certId],
        n.[score],
        n.[reason],
        n.[submittedAt],
        CAST(CASE WHEN n.[npsId] IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS [submitted]
    FROM [portal].[NPS] n
    WHERE n.[certId] = @certId;
END
GO

-- 5. spNPS_GetYTD - aggregate NPS scores for current calendar year
CREATE OR ALTER PROCEDURE [portal].[spNPS_GetYTD]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @year INT = YEAR(GETUTCDATE());

    SELECT
        COUNT(*)                                                                             AS [totalResponses],
        SUM(CASE WHEN [score] >= 9 THEN 1 ELSE 0 END)                                       AS [promoters],
        SUM(CASE WHEN [score] >= 7 AND [score] <= 8 THEN 1 ELSE 0 END)                      AS [passives],
        SUM(CASE WHEN [score] <= 6 THEN 1 ELSE 0 END)                                       AS [detractors],
        CAST(
            CASE WHEN COUNT(*) = 0 THEN NULL
            ELSE ROUND(
                (CAST(SUM(CASE WHEN [score] >= 9 THEN 1 ELSE 0 END) AS FLOAT)
                - CAST(SUM(CASE WHEN [score] <= 6 THEN 1 ELSE 0 END) AS FLOAT))
                / CAST(COUNT(*) AS FLOAT) * 100
            , 1)
            END
        AS FLOAT)                                                                            AS [npsScore],
        @year                                                                                AS [year]
    FROM [portal].[NPS]
    WHERE YEAR([submittedAt]) = @year;
END
GO

-- 6. spNPS_GetAll - return all NPS responses with company/cert/user context for the grid
CREATE OR ALTER PROCEDURE [portal].[spNPS_GetAll]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        n.[npsId],
        n.[certId],
        n.[score],
        n.[reason],
        n.[submittedAt],
        c.[companyId],
        co.[companyName],
        c.[certYear],
        p.[progName]
    FROM [portal].[NPS] n
    INNER JOIN [portal].[Certification] c ON c.[certId] = n.[certId]
    INNER JOIN [portal].[Company] co ON co.[companyId] = c.[companyId]
    INNER JOIN [portal].[Programme] p ON p.[progId] = c.[progId]
    ORDER BY n.[submittedAt] DESC;
END
GO

-- 7. Backup and update spCertificationDocument_Save to accept isCertificationDocument flag
--    When isCertificationDocument = 1, all other docs for the cert are reset to 0
IF NOT EXISTS (
    SELECT 1 FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[portal].[spCertificationDocument_Save_06May2026_RB]')
    AND type = 'P'
)
BEGIN
    EXEC sp_rename N'[portal].[spCertificationDocument_Save]', N'spCertificationDocument_Save_06May2026_RB', N'OBJECT';
END
GO

CREATE OR ALTER PROCEDURE [portal].[spCertificationDocument_Save]
    @certId                  INT,
    @documentId              INT,
    @displayName             NVARCHAR(100) = NULL,
    @isCertificationDocument BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    -- Enforce single certification document per cert
    IF @isCertificationDocument = 1
    BEGIN
        UPDATE [portal].[CertDocuments]
        SET [isCertificationDocument] = 0
        WHERE [certId] = @certId;
    END

    DECLARE @isDeleted INT;
    SELECT @isDeleted = isDeleted
    FROM [portal].[CertDocuments]
    WHERE certId = @certId AND documentId = @documentId;

    IF @isDeleted IS NULL -- Add New
    BEGIN
        INSERT INTO [portal].[CertDocuments] (certId, documentId, displayName, isCertificationDocument)
        VALUES (@certId, @documentId, @displayName, @isCertificationDocument);
    END
    ELSE -- Update
    BEGIN
        UPDATE [portal].[CertDocuments]
        SET displayName             = ISNULL(@displayName, displayName),
            isDeleted               = 0,
            isCertificationDocument = @isCertificationDocument
        WHERE certId = @certId AND documentId = @documentId;
    END
END
GO

-- 8. Backup and update spCertificationDocument_Get to return isCertificationDocument and npsSubmitted flags
IF NOT EXISTS (
    SELECT 1 FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[portal].[spCertificationDocument_Get_06May2026_RB]')
    AND type = 'P'
)
BEGIN
    EXEC sp_rename N'[portal].[spCertificationDocument_Get]', N'spCertificationDocument_Get_06May2026_RB', N'OBJECT';
END
GO

CREATE OR ALTER PROCEDURE [portal].[spCertificationDocument_Get]
    @certId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CASE d.parentEntityType
            WHEN 'certification'      THEN cd.displayName
            WHEN 'certification-prog' THEN pd.displayName
            ELSE d.title
        END                                                                         AS displayName,
        d.title,
        d.id                                                                        AS documentId,
        d.parentEntityType,
        cd.certId,
        c.progId,
        cd.isCertificationDocument,
        CAST(CASE WHEN n.npsId IS NOT NULL THEN 1 ELSE 0 END AS BIT)               AS npsSubmitted
    FROM [Documents].[Document] AS d
    INNER JOIN [portal].[CertDocuments]      AS cd ON d.id = cd.documentId AND cd.isDeleted = 0
    INNER JOIN [portal].[Certification]      AS c  ON c.certId = cd.certId
    LEFT  JOIN [portal].[ProgrammeDocuments] AS pd ON cd.documentId = pd.documentId AND c.progId = pd.progId
    LEFT  JOIN [portal].[NPS]               AS n  ON n.certId = cd.certId
    WHERE d.activeTo IS NULL
      AND cd.certId = @certId
      AND (CASE WHEN pd.documentId IS NOT NULL THEN pd.isDeleted ELSE 0 END) = 0;
END
GO


