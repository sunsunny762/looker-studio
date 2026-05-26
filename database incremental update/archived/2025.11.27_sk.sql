/****** Table [portal].[SupplierStatusHistory] ******/
-- DROP TABLE [portal].[SupplierStatusHistory];
GO

IF NOT EXISTS (
    SELECT * FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[portal].[SupplierStatusHistory]')
      AND type = N'U'
)
BEGIN
    CREATE TABLE [portal].[SupplierStatusHistory] (
        eventId INT IDENTITY(1,1) NOT NULL,
        companyId INT NOT NULL,
        eventType VARCHAR(20) NOT NULL,
        updatedDate DATETIME NOT NULL DEFAULT GETDATE(),
        userId INT NULL,
        CONSTRAINT PK_SupplierStatusHistory PRIMARY KEY (eventId),
        CONSTRAINT CK_SupplierStatusHistory_EventType 
            CHECK (eventType IN ('imported','uploaded'))
    );
END
GO

/****** Function [portal].[fnGetSixteenWeekDate] ******/
IF NOT EXISTS (
    SELECT * FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[portal].[fnGetSixteenWeekDate]')
      AND type = N'FN'
)
BEGIN
    EXEC dbo.sp_executesql 
        @statement = N'CREATE FUNCTION [portal].[fnGetSixteenWeekDate]() RETURNS DATETIME AS BEGIN RETURN NULL END'
END
GO

ALTER FUNCTION [portal].[fnGetSixteenWeekDate]
(
    @startDate DATETIME
)
RETURNS DATETIME
AS
BEGIN
    IF @startDate IS NULL
        RETURN NULL;

    DECLARE @effectiveDate DATETIME =
        CASE 
            WHEN @startDate > GETDATE() THEN @startDate 
            ELSE GETDATE() 
        END;

    RETURN DATEADD(WEEK, 16, @effectiveDate);
END
GO

/****** Function [portal].[fnGetWeekFridays] ******/
IF NOT EXISTS (
    SELECT * FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[portal].[fnGetWeekFridays]')
      AND type = N'IF'
)
BEGIN
    EXEC dbo.sp_executesql 
        @statement = N'CREATE FUNCTION [portal].[fnGetWeekFridays]() RETURNS TABLE AS RETURN SELECT 1 AS dummy'
END
GO

ALTER FUNCTION [portal].[fnGetWeekFridays]()
RETURNS TABLE
AS
RETURN
(
    WITH LastFriday AS
    (
        SELECT 
            DATEADD(
                DAY, 
                -((DATEPART(WEEKDAY, GETDATE()) + @@DATEFIRST - 6) % 7),
                CAST(GETDATE() AS DATE)
            ) AS FridayDate
    ),
    GenerateWeeks AS
    (
        SELECT TOP 12 
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
        FROM sys.objects
    )
    SELECT 
        DATEADD(WEEK, -n, FridayDate) AS FridayDate
    FROM LastFriday, GenerateWeeks
);
GO


/****** Function [portal].[fnGetTwoWeekDate] ******/
IF NOT EXISTS (
    SELECT * FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[portal].[fnGetTwoWeekDate]')
      AND type = N'IF'
)
BEGIN
    EXEC dbo.sp_executesql 
        @statement = N'CREATE FUNCTION [portal].[fnGetTwoWeekDate]() RETURNS @T TABLE (periodStart DATE, periodEnd DATE) AS BEGIN RETURN END'
END
GO

ALTER FUNCTION [portal].[fnGetTwoWeekDate]
(
    @startDate DATE,
    @lastDate DATE
)
RETURNS @T TABLE
(
    periodStart DATE,
    periodEnd   DATE
)
AS
BEGIN
    DECLARE 
        @periodStart DATE = @startDate,
        @periodEnd   DATE,
        @i INT = 0;

    WHILE @periodStart <= @lastDate
    BEGIN
        -- 14-day period = start + 13 days
        SET @periodEnd = DATEADD(DAY, 13, @periodStart);

        -- exit if start beyond upper bound
        IF @periodStart > @lastDate BREAK;

        -- cap end date if exceeds lastDate
        IF @periodEnd > @lastDate 
            SET @periodEnd = @lastDate;

        INSERT INTO @T(periodStart, periodEnd)
        VALUES (@periodStart, @periodEnd);

        -- move to next block
        SET @periodStart = DATEADD(DAY, 14, @periodStart);

        SET @i = @i + 1;
        IF @i > 500 BREAK; -- safety limit
    END;

    RETURN;
END
GO

/****** View [portal].[vCertificationWeekStatusReport] ******/
IF NOT EXISTS (
    SELECT * FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[portal].[vCertificationWeekStatusReport]')
      AND type = N'V'
)
BEGIN
    EXEC dbo.sp_executesql
        @statement = N'CREATE VIEW [portal].[vCertificationWeekStatusReport] AS SELECT 1 AS dummy'
END
GO

ALTER VIEW [portal].[vCertificationWeekStatusReport]
AS
WITH CompletedDate AS (
    SELECT
        csh.certId,
        MAX(csh.fromDate) AS CompletedDate
    FROM portal.CertificationStatusHistory csh
    WHERE csh.status = 2
    GROUP BY csh.certId
)
SELECT
    cert.companyId,
    cert.certId,
    cert.progId,
    cert.startDate AS certStartDate,
    cert.endDate AS certEndDate,
    cd.CompletedDate AS dataCollCompDate,
    cert.status AS currentStatus,
    DATEADD(
        WEEK,
        CASE 
            WHEN cert.progId = 4 THEN 16
            WHEN cert.progId IN (2,3) THEN 12
            ELSE 16
        END,
        cert.startDate
    ) AS sixteenWeekDate
FROM portal.Certification cert
LEFT JOIN CompletedDate cd ON cd.certId = cert.certId;
GO

/****** View [portal].[vReportIssuedWeekStatusReport] ******/
IF NOT EXISTS (
    SELECT * FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[portal].[vReportIssuedWeekStatusReport]')
      AND type = N'V'
)
BEGIN
    EXEC dbo.sp_executesql
        @statement = N'CREATE VIEW [portal].[vReportIssuedWeekStatusReport] AS SELECT 1 AS dummy'
END
GO

ALTER VIEW [portal].[vReportIssuedWeekStatusReport]
AS
WITH CompletedDate AS (
    SELECT
        csh.certId,
        MAX(csh.fromDate) AS CompletedDate
    FROM portal.CertificationStatusHistory csh
    WHERE csh.status = 5
    GROUP BY csh.certId
)
SELECT
    cert.companyId,
    cert.certId,
    cert.progId,
    cert.startDate AS certStartDate,
    cert.endDate AS certEndDate,
    cd.CompletedDate AS dataCollCompDate,
    DATEADD(WEEK, 2, cert.startDate) AS twoWeekDate
FROM portal.Certification cert
LEFT JOIN CompletedDate cd 
    ON cd.certId = cert.certId
WHERE cert.progId IN (2,3,4);
GO

/****** View [portal].[vSupplierWeekStatusReport] ******/
IF NOT EXISTS (
    SELECT * FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[portal].[vSupplierWeekStatusReport]')
      AND type = N'V'
)
BEGIN
    EXEC dbo.sp_executesql
        @statement = N'CREATE VIEW [portal].[vSupplierWeekStatusReport] AS SELECT 1 AS dummy'
END
GO

ALTER VIEW [portal].[vSupplierWeekStatusReport]
AS
WITH LatestCert AS (
    SELECT
        cert.companyId,
        cert.startDate,
        cert.endDate,
        ROW_NUMBER() OVER (
            PARTITION BY cert.companyId
            ORDER BY cert.startDate DESC
        ) AS rn
    FROM portal.Certification cert
    WHERE cert.progId = 4
),

ImportedData AS (
    SELECT companyId, updatedDate
    FROM portal.SupplierStatusHistory
    WHERE eventType = 'imported'
),

LastFriday AS (
    SELECT 
        DATEADD(
            DAY,
            -((DATEPART(WEEKDAY, GETDATE()) + @@DATEFIRST - 6) % 7),
            CAST(GETDATE() AS DATE)
        ) AS lastFriday
)

SELECT
    lc.companyId,

    -- Also returned in output
    lc.startDate AS startDate,
    lc.endDate AS endDate,

    p.periodStart,
    p.periodEnd,

    ( SELECT TOP 1 updatedDate
      FROM ImportedData i
      WHERE i.companyId = lc.companyId
        AND i.updatedDate BETWEEN p.periodStart AND p.periodEnd
      ORDER BY updatedDate DESC
    ) AS importedDate,

    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM ImportedData i
            WHERE i.companyId = lc.companyId
              AND i.updatedDate BETWEEN p.periodStart AND p.periodEnd
        )
        THEN 1 
        ELSE 0 
    END AS isImportedWithinPeriod

FROM LatestCert lc
JOIN LastFriday lf ON 1 = 1
CROSS APPLY portal.fnGetTwoWeekDate(lc.startDate, lf.lastFriday) p
WHERE lc.rn = 1;
GO


/****** StoredProcedure [portal].[spCertificationAllStatusReport] ******/
IF NOT EXISTS (
    SELECT * FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[portal].[spCertificationAllStatusReport]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC dbo.sp_executesql
        @statement = N'CREATE PROCEDURE [portal].[spCertificationAllStatusReport] AS'
END
GO

ALTER PROCEDURE [portal].[spCertificationAllStatusReport]
AS
BEGIN
    SET NOCOUNT ON;

    --------------------------------------------------
    -- 1. Get ONLY the latest Friday
    --------------------------------------------------
    DECLARE @LastFriday DATE = (
        SELECT MAX(FridayDate)
        FROM portal.fnGetWeekFridays()
    );

    --------------------------------------------------
    -- 2. Main Aggregation Query
    --------------------------------------------------
    SELECT
        v.progId,
        p.progName,
        @LastFriday AS reportingDate,

        -----------------------------
        -- Status-wise counts (1–5)
        -----------------------------
        SUM(CASE WHEN v.currentStatus = 1 THEN 1 ELSE 0 END) AS status1,
        SUM(CASE WHEN v.currentStatus = 2 THEN 1 ELSE 0 END) AS status2,
        SUM(CASE WHEN v.currentStatus = 3 THEN 1 ELSE 0 END) AS status3,
        SUM(CASE WHEN v.currentStatus = 4 THEN 1 ELSE 0 END) AS status4,
        SUM(CASE WHEN v.currentStatus = 5 THEN 1 ELSE 0 END) AS status5

    FROM portal.vCertificationWeekStatusReport v
    INNER JOIN portal.Programme p 
        ON p.progId = v.progId

    LEFT JOIN portal.DropdownItems DI 
        ON v.currentStatus = DI.itemId
        AND DI.groupId = 1
        AND DI.itemId BETWEEN 1 AND 5   -- restrict valid statuses

    --------------------------------------------------
    -- Include only certificates active on last Friday
    --------------------------------------------------
    WHERE 
        v.certStartDate <= @LastFriday
        AND (v.certEndDate IS NULL OR v.certEndDate >= @LastFriday)

    GROUP BY 
        v.progId,
        p.progName

    ORDER BY 
        v.progId;

END
GO

/****** StoredProcedure [portal].[spCertificationWeekStatusReport] ******/
IF NOT EXISTS (
    SELECT * FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[portal].[spCertificationWeekStatusReport]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC dbo.sp_executesql
        @statement = N'CREATE PROCEDURE [portal].[spCertificationWeekStatusReport] AS'
END
GO

ALTER PROCEDURE [portal].[spCertificationWeekStatusReport]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        v.progId,
        p.progName,
        f.FridayDate AS reportingDate,

        ------------------------------------------------
        -- Completed Certificates
        ------------------------------------------------
        SUM(
            CASE 
                WHEN 
                    v.dataCollCompDate IS NOT NULL
                    AND v.dataCollCompDate <= f.FridayDate
                    AND v.dataCollCompDate <= v.SixteenWeekDate
                    AND v.certStartDate <= f.FridayDate
                    AND (v.certEndDate >= f.FridayDate)
                THEN 1
                ELSE 0
            END
        ) AS completedCertCount,

        ------------------------------------------------
        -- Active Certificates
        ------------------------------------------------
        SUM(
            CASE
                WHEN 
                    v.certStartDate <= f.FridayDate
                    AND (v.certEndDate >= f.FridayDate)
                THEN 1
                ELSE 0
            END
        ) AS activeCertCount,

        ------------------------------------------------
        -- Total Overdue Days
        ------------------------------------------------
        SUM(
            CASE 
                WHEN 
                    v.dataCollCompDate IS NULL
                    AND f.FridayDate > v.SixteenWeekDate
                    AND v.certStartDate <= f.FridayDate
                    AND (v.certEndDate >= f.FridayDate)
                THEN DATEDIFF(DAY, v.SixteenWeekDate, f.FridayDate)
                ELSE 0
            END
        ) AS totalOverdueDays,

        ------------------------------------------------
        -- Overdue Certificates Count
        ------------------------------------------------
        SUM(
            CASE 
                WHEN 
                    v.certStartDate <= f.FridayDate
                    AND (v.certEndDate IS NULL OR v.certEndDate >= f.FridayDate)
                    AND (
                            -- Completed but late
                            (v.dataCollCompDate IS NOT NULL
                             AND v.SixteenWeekDate <= f.FridayDate
                             AND v.SixteenWeekDate < v.dataCollCompDate)
                            OR
                            -- Not completed and overdue
                            (v.dataCollCompDate IS NULL
                             AND f.FridayDate > v.SixteenWeekDate)
                        )
                THEN 1
                ELSE 0
            END
        ) AS overdueCertCount

    FROM 
        portal.fnGetWeekFridays() f
    CROSS JOIN 
        portal.vCertificationWeekStatusReport v
    INNER JOIN 
        portal.Programme p ON p.progId = v.progId

    GROUP BY 
        f.FridayDate,
        v.progId,
        p.progName

    HAVING 
        SUM(
            CASE
                WHEN 
                    v.certStartDate <= f.FridayDate
                    AND (v.certEndDate >= f.FridayDate)
                THEN 1
                ELSE 0
            END
        ) > 0

    ORDER BY 
        f.FridayDate,
        v.progId;

END
GO

/****** StoredProcedure [portal].[spReportIssuedWeekStatusReport] ******/
IF NOT EXISTS (
    SELECT * FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[portal].[spReportIssuedWeekStatusReport]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC dbo.sp_executesql
        @statement = N'CREATE PROCEDURE [portal].[spReportIssuedWeekStatusReport] AS'
END
GO

ALTER PROCEDURE [portal].[spReportIssuedWeekStatusReport]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        v.progId,
        p.progName,
        f.FridayDate AS reportingDate,

        ------------------------------------------------
        -- Completed Certificates
        ------------------------------------------------
        SUM(
            CASE 
                WHEN 
                    v.dataCollCompDate IS NOT NULL
                    AND v.dataCollCompDate <= f.FridayDate
                    AND v.dataCollCompDate <= v.twoWeekDate
                    AND v.certStartDate <= f.FridayDate
                    AND (v.certEndDate >= f.FridayDate)
                THEN 1
                ELSE 0
            END
        ) AS completedCertCount,

        ------------------------------------------------
        -- Active Certificates
        ------------------------------------------------
        SUM(
            CASE
                WHEN 
                    v.certStartDate <= f.FridayDate
                    AND (v.certEndDate >= f.FridayDate)
                THEN 1
                ELSE 0
            END
        ) AS activeCertCount,

        ------------------------------------------------
        -- Total Overdue Days
        ------------------------------------------------
        SUM(
            CASE 
                WHEN 
                    v.dataCollCompDate IS NULL
                    AND f.FridayDate > v.twoWeekDate
                    AND v.certStartDate <= f.FridayDate
                    AND (v.certEndDate >= f.FridayDate)
                THEN DATEDIFF(DAY, v.twoWeekDate, f.FridayDate)
                ELSE 0
            END
        ) AS totalOverdueDays,

        ------------------------------------------------
        -- Overdue Certificate Count
        ------------------------------------------------
        SUM(
            CASE 
                WHEN 
                    v.certStartDate <= f.FridayDate
                    AND (v.certEndDate IS NULL OR v.certEndDate >= f.FridayDate)
                    AND (

                            -- 1. Completed but late
                            (v.dataCollCompDate IS NOT NULL
                             AND v.twoWeekDate <= f.FridayDate
                             AND v.twoWeekDate < v.dataCollCompDate)

                            OR

                            -- 2. Not completed and overdue
                            (v.dataCollCompDate IS NULL
                             AND f.FridayDate > v.twoWeekDate)
                        )
                THEN 1
                ELSE 0
            END
        ) AS overdueCertCount

    FROM 
        portal.fnGetWeekFridays() f
    CROSS JOIN 
        portal.vReportIssuedWeekStatusReport v
    INNER JOIN 
        portal.Programme p ON p.progId = v.progId

    GROUP BY 
        f.FridayDate,
        v.progId,
        p.progName

    HAVING 
        SUM(
            CASE
                WHEN 
                    v.certStartDate <= f.FridayDate
                    AND (v.certEndDate >= f.FridayDate)
                THEN 1
                ELSE 0
            END
        ) > 0

    ORDER BY 
        f.FridayDate,
        v.progId;

END
GO

/****** StoredProcedure [portal].[spSupplierWeekStatusReport] ******/
IF NOT EXISTS (
    SELECT * FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[portal].[spSupplierWeekStatusReport]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC dbo.sp_executesql
        @statement = N'CREATE PROCEDURE [portal].[spSupplierWeekStatusReport] AS'
END
GO

ALTER PROCEDURE [portal].[spSupplierWeekStatusReport]
AS
BEGIN
    SET NOCOUNT ON;

    WITH ReportCTE AS (
        SELECT
            v.companyId,
            f.FridayDate AS reportingDate,

            -----------------------------------
            -- Completed Count
            -----------------------------------
            SUM(
                CASE 
                    WHEN v.importedDate IS NOT NULL
                         AND v.importedDate BETWEEN v.periodStart AND v.periodEnd
                         AND f.FridayDate BETWEEN v.startDate AND v.endDate
                THEN 1 ELSE 0 END
            ) AS completedCount,

            -----------------------------------
            -- Active Count
            -----------------------------------
            SUM(
                CASE 
                    WHEN f.FridayDate BETWEEN v.startDate AND v.endDate
                THEN 1 ELSE 0 END
            ) AS activeCount,

            -----------------------------------
            -- Overdue Count
            -----------------------------------
            SUM(
                CASE 
                    WHEN f.FridayDate BETWEEN v.startDate AND v.endDate
                         AND (
                                (v.importedDate IS NOT NULL AND v.importedDate > v.periodEnd)
                             OR (v.importedDate IS NULL AND f.FridayDate > v.periodEnd)
                         )
                THEN 1 ELSE 0 END
            ) AS overDueCount,

            -----------------------------------
            -- Total Overdue Days
            -----------------------------------
            SUM(
                CASE 
                    WHEN v.importedDate IS NULL
                         AND f.FridayDate > v.periodEnd
                         AND f.FridayDate BETWEEN v.startDate AND v.endDate
                THEN DATEDIFF(DAY, v.periodEnd, f.FridayDate)
                ELSE 0 END
            ) AS totalOverDueDays

        FROM 
            portal.fnGetWeekFridays() f
        CROSS JOIN 
            portal.vSupplierWeekStatusReport v

        GROUP BY 
            v.companyId, f.FridayDate

        HAVING 
            SUM(
                CASE 
                    WHEN f.FridayDate BETWEEN v.startDate AND v.endDate 
                    THEN 1 ELSE 0 
                END
            ) > 0
    )

    SELECT
        companyId,
        reportingDate,
        completedCount,
        activeCount,
        overDueCount,

        ---------------------------------------
        -- Average Overdue Days per Friday
        ---------------------------------------
        CASE 
            WHEN activeCount > 0 
                THEN CAST(ROUND(CAST(totalOverDueDays AS FLOAT) / activeCount, 0) AS INT)
            ELSE 0
        END AS overDueDays

    FROM ReportCTE
    ORDER BY reportingDate, companyId;

END
GO







