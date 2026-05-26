/****** StoredProcedure [portal].[spCertificationReportDetail] ******/
IF NOT EXISTS (
    SELECT * 
    FROM sys.objects 
    WHERE object_id = OBJECT_ID(N'[portal].[spCertificationReportDetail]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC dbo.sp_executesql 
        @statement = N'CREATE PROCEDURE [portal].[spCertificationReportDetail] AS'
END
GO

ALTER PROCEDURE [portal].[spCertificationReportDetail]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        f.FridayDate AS reportingDate,
        crt.certId,
        crt.refNumber,
        crt.companyId,
        c.companyName,
        p.progId,
        p.progName,
        FORMAT(crt.startDate, 'dd/MM/yyyy') + ' - ' +
        FORMAT(crt.endDate, 'dd/MM/yyyy') AS period,
        di.itemName AS statusStr,
        v.dataCollCompDate AS completedDate,
        CASE 
            WHEN crt.startDate <= f.FridayDate
                 AND (crt.endDate >= f.FridayDate OR crt.endDate IS NULL)
            THEN 1
            ELSE 0
        END AS isActive,
        CASE 
            WHEN 
                v.dataCollCompDate IS NULL
                AND f.FridayDate > v.SixteenWeekDate
                AND crt.startDate <= f.FridayDate
                AND (crt.endDate IS NULL OR crt.endDate >= f.FridayDate)
            THEN DATEDIFF(DAY, v.SixteenWeekDate, f.FridayDate)
            ELSE 0
        END AS overdueDays
    FROM portal.fnGetWeekFridays() f
    JOIN portal.vCertificationWeekStatusReport v
        ON 1 = 1
    JOIN portal.Certification crt
        ON crt.certId = v.certId
    JOIN portal.Company c
        ON c.companyId = crt.companyId
    INNER JOIN (
        SELECT certId, MAX(eventId) AS latestEventId
        FROM portal.CertificationStatusHistory
        GROUP BY certId
    ) lastEvt
        ON lastEvt.certId = crt.certId
    INNER JOIN portal.CertificationStatusHistory csh
        ON csh.eventId = lastEvt.latestEventId
    LEFT JOIN portal.DropdownItems di
        ON csh.status = di.itemId AND di.groupId = 1
    LEFT JOIN portal.Programme p
        ON p.progId = crt.progId
    WHERE crt.isDeleted = 0
    ORDER BY c.companyName, f.FridayDate, p.progName;
END
GO

/****** StoredProcedure [portal].[spReportIssuedDetail] ******/
IF NOT EXISTS (
    SELECT * FROM sys.objects 
    WHERE object_id = OBJECT_ID(N'[portal].[spReportIssuedDetail]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC dbo.sp_executesql 
        @statement = N'CREATE PROCEDURE [portal].[spReportIssuedDetail] AS'
END
GO

ALTER PROCEDURE [portal].[spReportIssuedDetail]
AS
BEGIN
    SET NOCOUNT ON;

    WITH Completed AS (
        SELECT 
            csh.certId,
            MAX(csh.fromDate) AS completedDate
        FROM portal.CertificationStatusHistory csh
        WHERE csh.status = 5
        GROUP BY csh.certId
    )

    SELECT
        f.FridayDate AS reportingDate,
        crt.certId,
        crt.refNumber,
        crt.companyId,
        c.companyName,
        p.progId,
        p.progName,
        FORMAT(crt.startDate, 'dd/MM/yyyy') + ' - ' +
        FORMAT(crt.endDate, 'dd/MM/yyyy') AS period,
        di.itemName AS statusStr,                   
        comp.completedDate AS completedDate,  
        CASE 
            WHEN crt.startDate <= f.FridayDate
             AND (crt.endDate IS NULL OR crt.endDate >= f.FridayDate)
            THEN 1 ELSE 0
        END AS isActive,
        CASE 
            WHEN comp.completedDate IS NULL
             AND f.FridayDate > DATEADD(WEEK, 2, crt.startDate)
             AND crt.startDate <= f.FridayDate
             AND (crt.endDate IS NULL OR crt.endDate >= f.FridayDate)
            THEN DATEDIFF(DAY, DATEADD(WEEK, 2, crt.startDate), f.FridayDate)
            ELSE 0
        END AS overdueDays,
        CASE 
            WHEN crt.startDate <= f.FridayDate
             AND (crt.endDate IS NULL OR crt.endDate >= f.FridayDate)
             AND (
                    (comp.completedDate IS NOT NULL 
                         AND DATEADD(WEEK, 2, crt.startDate) < comp.completedDate)
                  OR
                    (comp.completedDate IS NULL 
                         AND f.FridayDate > DATEADD(WEEK, 2, crt.startDate))
                 )
            THEN 1 ELSE 0
        END AS isOverdue
    FROM portal.fnGetWeekFridays() f
    JOIN portal.Certification crt
        ON crt.isDeleted = 0
       AND crt.progId IN (2,3,4)
    LEFT JOIN Completed comp
        ON comp.certId = crt.certId
    JOIN portal.Company c
        ON c.companyId = crt.companyId
    LEFT JOIN portal.Programme p
        ON p.progId = crt.progId
    LEFT JOIN portal.DropdownItems di
        ON di.itemId = 5
       AND di.groupId = 1
    ORDER BY
        c.companyName,
        f.FridayDate,
        p.progName;
END
GO

/****** StoredProcedure [portal].[spSupplierReportDetail] ******/
IF NOT EXISTS (
    SELECT * FROM sys.objects 
    WHERE object_id = OBJECT_ID(N'[portal].[spSupplierReportDetail]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC dbo.sp_executesql 
        @statement = N'CREATE PROCEDURE [portal].[spSupplierReportDetail] AS'
END
GO


ALTER PROCEDURE [portal].[spSupplierReportDetail]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        f.FridayDate AS reportingDate,
        v.companyId,
        c.companyName,
        v.startDate,
        v.endDate,
        FORMAT(v.startDate, 'dd/MM/yyyy') + ' - ' +
        FORMAT(v.endDate, 'dd/MM/yyyy') AS certPeriod,
        FORMAT(v.periodStart, 'dd/MM/yyyy') + ' - ' +
        FORMAT(v.periodEnd, 'dd/MM/yyyy') AS period,
        v.periodStart,
        v.periodEnd,
        v.importedDate,

        CASE 
            WHEN f.FridayDate BETWEEN v.startDate AND v.endDate
            THEN 1 ELSE 0
        END AS isActive,

        CASE 
            WHEN v.importedDate IS NOT NULL
                 AND v.importedDate BETWEEN v.periodStart AND v.periodEnd
                 AND f.FridayDate BETWEEN v.startDate AND v.endDate
            THEN 1 ELSE 0
        END AS isCompleted,

        CASE 
            WHEN 
                f.FridayDate BETWEEN v.startDate AND v.endDate
                AND (
                       (v.importedDate IS NOT NULL AND v.importedDate > v.periodEnd)
                    OR (v.importedDate IS NULL AND f.FridayDate > v.periodEnd)
                    )
            THEN 1 ELSE 0
        END AS isOverdue,

        CASE 
            WHEN 
                v.importedDate IS NULL
                AND f.FridayDate > v.periodEnd
                AND f.FridayDate BETWEEN v.startDate AND v.endDate
            THEN DATEDIFF(DAY, v.periodEnd, f.FridayDate)
            ELSE 0
        END AS overdueDays

    FROM portal.fnGetWeekFridays() f
    JOIN portal.vSupplierWeekStatusReport v
        ON f.FridayDate BETWEEN v.startDate AND v.endDate
    LEFT JOIN portal.Company c
        ON c.companyId = v.companyId
    ORDER BY 
        c.companyName,
        f.FridayDate;

END
GO
