/*
 Navicat Premium Data Transfer

 Source Server         : NCZ [Dev]
 Source Server Type    : SQL Server
 Source Server Version : 12009114 (12.00.9114)
 Source Host           : ncz.database.windows.net:1433
 Source Catalog        : nczdev
 Source Schema         : portal

 Target Server Type    : SQL Server
 Target Server Version : 12009114 (12.00.9114)
 File Encoding         : 65001

 Date: 10/03/2026 09:00:00
*/

-- ============================================================
-- Add headCount column to portal.Certification
-- ============================================================
ALTER TABLE [portal].[Certification] ADD [headCount] INT NULL
GO

-- ============================================================
-- Create portal.CertificationHeadCount table
-- ============================================================
IF NOT EXISTS (
    SELECT 1 FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'portal' AND t.name = 'CertificationHeadCount'
)
BEGIN
    CREATE TABLE [portal].[CertificationHeadCount] (
        [id]         [int] IDENTITY(1,1) NOT NULL,
        [certId]     [int] NOT NULL,
        [locationId] [int] NOT NULL,
        [headCount]  [int] NULL,
        [revenue]    [decimal](18, 0) NULL,
        CONSTRAINT [PK_CertificationHeadCount] PRIMARY KEY CLUSTERED ([id] ASC),
        CONSTRAINT [UQ_CertificationHeadCount_CertLoc] UNIQUE ([certId], [locationId])
    )
END
GO



-- ============================================================
-- SP: spCertificationHeadCount_Get
--   Returns two result sets:
--     #1 - Certification-level headCount and revenue
--     #2 - Per-location headCount and revenue for the company
-- ============================================================
IF EXISTS (
    SELECT * FROM sys.all_objects
    WHERE object_id = OBJECT_ID(N'[portal].[spCertificationHeadCount_Get]')
    AND type IN ('P', 'PC', 'RF', 'X')
)
    DROP PROCEDURE [portal].[spCertificationHeadCount_Get]
GO

CREATE PROCEDURE [portal].[spCertificationHeadCount_Get]
    @certId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Result Set 1: Certification-level totals
    SELECT
        c.certId,
        c.headCount,
        c.revenue
    FROM [portal].[Certification] c
    WHERE c.certId = @certId;

    -- Result Set 2: All active locations for the company with any existing per-location data
    SELECT
        l.locationId,
        l.locationName,
        hc.headCount,
        hc.revenue
    FROM [portal].[Location] l
    INNER JOIN [portal].[Certification] cert
        ON cert.companyId = l.companyId
        AND cert.certId = @certId
    LEFT JOIN [portal].[CertificationHeadCount] hc
        ON hc.certId = @certId
        AND hc.locationId = l.locationId
    WHERE l.isDeleted = 0
    ORDER BY l.locationName;
END
GO


-- ============================================================
-- SP: spCertificationHeadCount_Save
--   When @locationId IS NULL  -> updates Certification-level headCount + revenue
--   When @locationId IS NOT NULL -> upserts a per-location row
-- ============================================================
IF EXISTS (
    SELECT * FROM sys.all_objects
    WHERE object_id = OBJECT_ID(N'[portal].[spCertificationHeadCount_Save]')
    AND type IN ('P', 'PC', 'RF', 'X')
)
    DROP PROCEDURE [portal].[spCertificationHeadCount_Save]
GO

CREATE PROCEDURE [portal].[spCertificationHeadCount_Save]
    @certId       INT,
    @headCount    INT            = NULL,
    @revenue      DECIMAL(18, 0) = NULL,
    @locationId   INT            = NULL,
    @locHeadCount INT            = NULL,
    @locRevenue   DECIMAL(18, 0) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @locationId IS NULL
    BEGIN
        -- Update certification-level totals
        UPDATE [portal].[Certification]
        SET
            headCount = @headCount,
            revenue   = @revenue
        WHERE certId = @certId;
    END
    ELSE
    BEGIN
        -- Upsert per-location row
        MERGE [portal].[CertificationHeadCount] AS target
        USING (SELECT @certId AS certId, @locationId AS locationId) AS source
        ON (target.certId = source.certId AND target.locationId = source.locationId)
        WHEN MATCHED THEN
            UPDATE SET headCount = @locHeadCount, revenue = @locRevenue
        WHEN NOT MATCHED THEN
            INSERT (certId, locationId, headCount, revenue)
            VALUES (@certId, @locationId, @locHeadCount, @locRevenue);
    END
END
GO
