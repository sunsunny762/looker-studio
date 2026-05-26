-- =============================================================
-- NPS userId - 2026.05.07_rb
-- 1. Add userId column to portal.NPS table
-- 2. Update spNPS_Save to accept @userId parameter
-- 3. Update spNPS_GetAll to return userName via JOIN on portal.Users
-- =============================================================

-- 1. Add userId column to NPS table
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'portal' AND TABLE_NAME = 'NPS'
    AND COLUMN_NAME = 'userId'
)
BEGIN
    ALTER TABLE [portal].[NPS]
    ADD [userId] INT NULL;
END
GO

-- 2. spNPS_Save - accept optional @userId and store it
CREATE OR ALTER PROCEDURE [portal].[spNPS_Save]
    @certId  INT,
    @score   INT,
    @reason  NVARCHAR(MAX) = NULL,
    @userId  INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM [portal].[NPS] WHERE [certId] = @certId)
    BEGIN
        RAISERROR('NPS already submitted for this certification.', 16, 1);
        RETURN;
    END

    INSERT INTO [portal].[NPS] ([certId], [score], [reason], [userId])
    VALUES (@certId, @score, @reason, @userId);

    SELECT SCOPE_IDENTITY() AS npsId;
END
GO

-- 3. spNPS_GetAll - return userName via LEFT JOIN on portal.Users
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
        c.[refNumber],
        p.[progName],
        n.[userId],
        u.[fullName]  AS [userName]
    FROM [portal].[NPS] n
    INNER JOIN [portal].[Certification] c  ON c.[certId]     = n.[certId]
    INNER JOIN [portal].[Company] co       ON co.[companyId] = c.[companyId]
    INNER JOIN [portal].[Programme] p      ON p.[progId]     = c.[progId]
    LEFT  JOIN [portal].[Users] u          ON u.[userId]     = n.[userId]
    ORDER BY n.[submittedAt] DESC;
END
GO

CREATE OR ALTER PROCEDURE [portal].[spNPS_GetYTD]
AS
BEGIN
    SET NOCOUNT ON;

    -- Financial year: 01 Apr → 31 Mar
    -- If today is before 01-Apr, the FY started last calendar year
    DECLARE @fyStart DATE = DATEFROMPARTS(
                                CASE WHEN MONTH(GETUTCDATE()) < 4
                                     THEN YEAR(GETUTCDATE()) - 1
                                     ELSE YEAR(GETUTCDATE())
                                END, 4, 1);
    DECLARE @fyEnd   DATE = DATEADD(DAY, -1, DATEADD(YEAR, 1, @fyStart)); -- 31 Mar next year

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
        YEAR(@fyStart)                                                                       AS [year]
    FROM [portal].[NPS]
    WHERE [submittedAt] >= @fyStart
      AND [submittedAt] <  DATEADD(DAY, 1, @fyEnd);
END
Go