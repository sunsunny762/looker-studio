/*
 Navicat Premium Data Transfer

 Source Server         : NCZ [Dev]
 Source Server Type    : SQL Server
 Source Server Version : 12001017 (12.00.1017)
 Source Host           : ncz.database.windows.net:1433
 Source Catalog        : nczdev
 Source Schema         : DataModel

 Target Server Type    : SQL Server
 Target Server Version : 12001017 (12.00.1017)
 File Encoding         : 65001

 Date: 17/02/2026 17:37:01
*/


-- ----------------------------
-- procedure structure for spSilver_DataOutputByScope_Portal
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[DataModel].[spSilver_DataOutputByScope_Portal]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [DataModel].[spSilver_DataOutputByScope_Portal]
GO

CREATE PROCEDURE [DataModel].[spSilver_DataOutputByScope_Portal] 
	@BAQSubmissionid BIGINT,
	@silverSubmissionIds nvarchar(MAX) = NULL,
    @CHWSubmissionIds nvarchar(MAX) = NULL,
	@emissionProfileId INT = 1,
	@dataInsert int = 0
AS
BEGIN
	
	CREATE TABLE #BAQData (
    category NVARCHAR(255),
    total DECIMAL(18, 2),
    dataUnit NVARCHAR(50),
    bmCategory NVARCHAR(255),
		[order] DECIMAL(5,2)
	);

	INSERT INTO #BAQData (category, total, dataUnit, bmCategory, [order])
  SELECT category, total, dataUnit, bmCategory, [order]
  FROM DataModel.fnBAQ_DataOutput_Portal(@BAQSubmissionid); 

	CREATE TABLE #BAQDataWithBM (
    category NVARCHAR(1000),
    total DECIMAL(18, 2),
    dataUnit NVARCHAR(50),
    bmCategory NVARCHAR(255),
		[order] DECIMAL(5,2),
		EF DECIMAL(18, 2),
		WTT DECIMAL(18, 2),
		TND DECIMAL(18, 2),
		TNDWTT DECIMAL(18, 2)
	);

	-- Totals by activity from our data collection
	WITH CTE_INPUT_TOTALS_BY_ACTIVITY AS (
				SELECT
						CONVERT(DATE,GETDATE()) AS Date,
						formName,  
						PercentageOfTotal,
						Utilities.GetEF(t.emissionActivityId, @emissionProfileId) as EF,
						Utilities.GetWTT(t.emissionActivityId, @emissionProfileId) as WTT, 
						Utilities.GetTND(t.emissionActivityId, @emissionProfileId) as TND, 
						Utilities.GetTNDWTT(t.emissionActivityId, @emissionProfileId) as TNDWTT
			 FROM DataModel.InputTotalsByActivity t
			 LEFT JOIN Emissions.EmissionFactor e ON e.activityId = t.emissionActivityId AND e.emissionProfileId = @emissionProfileId
	)

	-- Calculate Benchmark data
	,CTE_BENCHMARKS_BY_CATEGORY AS (
				SELECT
						CONVERT(DATE,GETDATE()) AS Date,
						formName AS Category,  
						SUM(PercentageOfTotal*ef) AS EF,
						SUM(PercentageOfTotal*wtt) AS WTT,
						SUM(PercentageOfTotal*tnd) AS TND,
						SUM(PercentageOfTotal*tndwtt) AS TNDWTT
			 FROM CTE_INPUT_TOTALS_BY_ACTIVITY
			 GROUP BY formname
	)

	,CTE_FINAL AS (
		 SELECT baq.category, 
						baq.total, 
						baq.dataunit, 
						baq.bmCategory, 
						baq.[order],
						bm.EF, 	
						bm.WTT, 
						bm.TND, 
						bm.TNDWTT
			 FROM #BAQData baq
	LEFT JOIN [CTE_BENCHMARKS_BY_CATEGORY] bm ON baq.bmCategory = bm.category
 )

-- BAQ data group by category.
	INSERT INTO #BAQDataWithBM (category, total, dataUnit, bmCategory, [order], ef, wtt, tnd, tndwtt)
	SELECT  STRING_AGG([Category], ', ') as [Sub Categories],
				SUM(total) as [Total],
				MAX(dataUnit) as [dataUnit],
				bmCategory,
				MAX([order]) as [Order],
				SUM(total * ef) as TotalEF, 
				SUM(total * wtt) as TotalWTT,
				SUM(total * tnd) as TotalTND, 
				SUM(total * tndwtt) as TotalTNDWTT
		FROM CTE_FINAL 
		GROUP BY bmCategory;

  -- C&HW submissions data and calculation 
    /* C&HW EF total formula, 
       - Commuting, (Total EF/ No of submissions ) * Commuting Head count
       - Home working, (Total EF/ No of submissions ) * Home working Head count
    */
    Declare @HomeWorkingSubmissionIds NVARCHAR(MAX), @CommutingSubmissionIds NVARCHAR(MAX);
    Declare @HomeWorkingSubmissionCount int, @CommutingSubmissionCount int;
    Declare @HomeWorkingHeadCount NUMERIC(10,2), @CommutingHeadCount NUMERIC(10,2);
    
    Select @HomeWorkingHeadCount = cast(BAQ_OfficeHeadcount as NUMERIC(10,2)), 
           @CommutingHeadCount = cast(BAQ_TotalHeadcount as NUMERIC(10,2)) - cast( BAQ_OfficeHeadcount as NUMERIC(10,2))
    From DataModel.BlueAwardSubmissionData Where dimSubmissionId = @BAQSubmissionid;
    
    CREATE TABLE #CHWSubmissions (
          submissionId int, -- dimension's submissionId
          CHWType NVARCHAR(50)
      );

    INSERT INTO #CHWSubmissions (submissionId, CHWType)
    SELECT DISTINCT submissionId, 
           CASE 
               WHEN emissionActivityId IN (357, 358, 359) THEN 'HOME_WORKING' 
               ELSE 'COMMUTING' 
           END AS CHWType
    FROM DataModel.vSilverSubmissions 
    WHERE submissionId IN (
          SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@CHWSubmissionIds, ',')
      );
      
    -- Get Emission data for C&HW (Home working)
    Select @HomeWorkingSubmissionCount = COUNT(*),
           @HomeWorkingSubmissionIds = STRING_AGG(CAST(submissionId AS NVARCHAR(MAX)), ',')
    From #CHWSubmissions
    Where CHWType='HOME_WORKING'; 

    CREATE TABLE #HomeWorkingData (
        formName NVARCHAR(255),
        category NVARCHAR(255),
        TotalEF DECIMAL(18, 2),
        TotalWTT DECIMAL(18, 2),
        TotalTND DECIMAL(18, 2),
        TotalTNDWTT DECIMAL(18, 2),
        isMBD INT
      );
    
    INSERT INTO #HomeWorkingData (formName, category, TotalEF, TotalWTT, TotalTND, TotalTNDWTT, isMBD)
    SELECT formName, category, TotalEF, TotalWTT, TotalTND, TotalTNDWTT, isMBD
    FROM DataModel.fnSilver_DataOutput_Portal(@HomeWorkingSubmissionIds, @emissionProfileId); 
    
    Update #HomeWorkingData 
      set TotalEF = (TotalEF / @HomeWorkingSubmissionCount) * @HomeWorkingHeadCount,
          TotalWTT = (TotalWTT / @HomeWorkingSubmissionCount) * @HomeWorkingHeadCount,
          TotalTND = (TotalTND / @HomeWorkingSubmissionCount) * @HomeWorkingHeadCount,
          TotalTNDWTT = (TotalTNDWTT / @HomeWorkingSubmissionCount) * @HomeWorkingHeadCount;
          
    -- Get Emission data for C&HW (Commuting)
    Select @CommutingSubmissionCount = COUNT(*),
           @CommutingSubmissionIds = STRING_AGG(CAST(submissionId AS NVARCHAR(MAX)), ',')
    From #CHWSubmissions
    Where CHWType='COMMUTING';
    
    CREATE TABLE #CommutingData (
			formName NVARCHAR(255),
			category NVARCHAR(255),
			TotalEF DECIMAL(18, 2),
			TotalWTT DECIMAL(18, 2),
			TotalTND DECIMAL(18, 2),
			TotalTNDWTT DECIMAL(18, 2),
      isMBD INT
		);

    INSERT INTO #CommutingData (formName, category, TotalEF, TotalWTT, TotalTND, TotalTNDWTT, isMBD)
    SELECT formName, category, TotalEF, TotalWTT, TotalTND, TotalTNDWTT, isMBD
    FROM DataModel.fnSilver_DataOutput_Portal(@CommutingSubmissionIds, @emissionProfileId); 
    
    Update #CommutingData 
      set TotalEF = (TotalEF / @CommutingSubmissionCount) * @CommutingHeadCount,
          TotalWTT = (TotalWTT / @CommutingSubmissionCount) * @CommutingHeadCount,
          TotalTND = (TotalTND / @CommutingSubmissionCount) * @CommutingHeadCount,
          TotalTNDWTT = (TotalTNDWTT / @CommutingSubmissionCount) * @CommutingHeadCount;

  -- Get the silver submission data
    CREATE TABLE #SilverData (
        formName NVARCHAR(255),
        category NVARCHAR(255),
        TotalEF DECIMAL(18, 2),
        TotalWTT DECIMAL(18, 2),
        TotalTND DECIMAL(18, 2),
        TotalTNDWTT DECIMAL(18, 2),
        isMBD INT
      );
		
	INSERT INTO #SilverData (formName, category, TotalEF, TotalWTT, TotalTND, TotalTNDWTT, isMBD)
  SELECT formName, category, TotalEF, TotalWTT, TotalTND, TotalTNDWTT, isMBD
  FROM DataModel.fnSilver_DataOutput_Portal(@silverSubmissionIds, @emissionProfileId); 
  
  INSERT INTO #SilverData (formName, category, TotalEF, TotalWTT, TotalTND, TotalTNDWTT, isMBD)
  Select formName, category, TotalEF, TotalWTT, TotalTND, TotalTNDWTT, isMBD from #HomeWorkingData;
  
  INSERT INTO #SilverData (formName, category, TotalEF, TotalWTT, TotalTND, TotalTNDWTT, isMBD)
  Select formName, category, TotalEF, TotalWTT, TotalTND, TotalTNDWTT, isMBD from #CommutingData;
	-- select * from #SilverData;
  DECLARE @scope1Categories NVARCHAR(MAX) = 'Natural Gas,Company Vehicles,Refrigerents,Other Fuels';
	DECLARE @scope2Categories NVARCHAR(MAX) = 'Electricity';
	DECLARE @scope3Categories NVARCHAR(MAX) = 'Business Travel - Domestic,Business Travel - International,Commuting,Home Working,Waste and Recycling,Water,Upstream Deliveries,Downstream Deliveries,Purchased Goods and Services';
  
/*	DECLARE @scope1Categories NVARCHAR(MAX) = 'Natural Gas,Company Vehicles (KM),Company Vehicles (Electricity),Company Vehicles (No of litre - Diesel),Company Vehicles (No of litre - Petrol),Company Vehicles (Currency),Refrigerents,Other Fuels';
	DECLARE @scope2Categories NVARCHAR(MAX) = 'Electricity';
	DECLARE @scope3Categories NVARCHAR(MAX) = 'Business Travel - Domestic (KM),Business Travel - International (KM),Business Travel - Domestic (Currency),Business Travel - Domestic (No of litre - Diesel),Business Travel - Domestic (No of litre - Petrol),Business Travel - Domestic (Hotel Stay),Business Travel - International (Hotel Stay),Business Travel - Amount Spend (Hotel Stay),Commuting,Home Working,Waste and Recycling,Water,Upstream Deliveries,Downstream Deliveries,Purchased Goods and Services';
*/
	DECLARE @totalScope1 DECIMAL(18,2) = (SELECT SUM(COALESCE(s.totalEF, CASE WHEN isMBD = 1 THEN b.EF ELSE 0 END))
																					FROM #BAQDataWithBM b LEFT JOIN #SilverData s ON s.category = b.bmCategory 
																				 WHERE b.bmCategory in (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@scope1Categories, ',')));
	
	DECLARE @totalScope2 DECIMAL(18,2) = (SELECT SUM(COALESCE(s.totalEF, CASE WHEN isMBD = 1 THEN b.EF ELSE 0 END))
																					FROM #BAQDataWithBM b LEFT JOIN #SilverData s ON s.category = b.bmCategory 
																				 WHERE b.bmCategory in (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@scope2Categories, ',')));
																				 
	DECLARE @totalScope3EF DECIMAL(18,2) = (SELECT SUM(COALESCE(s.totalEF, CASE WHEN isMBD = 1 THEN b.EF ELSE 0 END))
																					FROM #BAQDataWithBM b LEFT JOIN #SilverData s ON s.category = b.bmCategory 
																				 WHERE b.bmCategory in (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@scope3Categories, ',')));
	
	DECLARE @totalScope3WTT DECIMAL(18,2) =  (SELECT SUM(COALESCE(s.totalWTT, CASE WHEN isMBD = 1 THEN b.WTT ELSE 0 END)) + 
                                                   SUM(COALESCE(s.totalTND, CASE WHEN isMBD = 1 THEN b.TND ELSE 0 END)) + 
                                                   SUM(COALESCE(s.totalTNDWTT, CASE WHEN isMBD = 1 THEN b.TNDWTT ELSE 0 END))
																					FROM #BAQDataWithBM b LEFT JOIN #SilverData s ON s.category = b.bmCategory 
																				 WHERE NULLIF(b.bmCategory, '') IS NOT NULL);
	
	DECLARE @totalScope3 DECIMAL(10,2) = @totalScope3EF + @totalScope3WTT;
	DECLARE @company nvarchar(500), @headCount NUMERIC(10,2), @revenue nvarchar(50), @submissionDate DATETIME, @name nvarchar(100), @email nvarchar(100), @jobtitle nvarchar(100), @startDate nvarchar(25), @endDate nvarchar(25), @certId int;
	
  SELECT @company = isNull(c.companyName, [BAQ_CompanyName]), @headCount = [BAQ_TotalHeadCount], @revenue = isNull(cert.revenue, BAQ_CompanyRevenue), 
         @submissionDate = cfs.dateSubmitted, @certId = cfs.certId, 
				 @name = isNull(c.contactName, BAQ_YourName), @email = isNull(c.email,  BAQ_Email), @jobtitle = isNull(c.jobtitle,  BAQ_JobTitle), 
         @startDate = cert.startDate, @endDate = cert.endDate
		FROM [DataModel].[BlueAwardSubmissionData] bas
		--INNER JOIN [Forms].[JotformRawResponse] jr on jr.submissionId = bas.submissionId
    INNER JOIN portal.CertFormSubmissions as cfs on (bas.dimSubmissionId = cfs.dimSubmissionId)
    INNER JOIN portal.Certification as cert on (cfs.certId = cert.certId)
    INNER JOIN portal.Company as c on (c.companyId = cert.companyId)
		WHERE bas.dimSubmissionId = @BAQSubmissionid;
 

	--SCOPE BASED CALCULATIONS
	
IF @dataInsert = 1
BEGIN
	
	IF EXISTS (
        SELECT 1
        FROM Reports.silverAwardByScope
        WHERE submissionId = @BAQSubmissionid
    )
    BEGIN
        DELETE
        FROM Reports.silverAwardByScope
        WHERE submissionId = @BAQSubmissionid;
    END;

	INSERT
	INTO
	Reports.silverAwardByScope
    (
    certId,
    orderNo,
	submissionId,
	submissionDate,
	companyName,
	headCount,
	revenue,
	[scope],
	category,
	subCategories,
	totalKgCO2e,
	pctOfTotalEmissionsScope,
	isModelled,
	contactName,
	email,
	jobTitle,
	reportStartDate,
	reportEndDate,
	createdDate
    )
    SELECT
    @certId,
	X.orderNo,
	@BAQSubmissionid,
	@submissionDate,
	@company,
	@headCount,
	@revenue,
	X.Scope,
	X.Category,
	STRING_AGG(X.SubCategory, ', '),
	SUM(IsNull(X.TotalKgCO2e,0)),
	SUM(IsNull(X.Pct,0)),
	X.IsModelled,
	@name,
	@email,
	@jobtitle,
	@startDate,
	@endDate,
	GETDATE()
FROM
	(
	SELECT 
				[order] as orderNo,
				'Scope-1' as Scope, 
				b.bmCategory as [Category], 
				b.category as [SubCategory], 
				(CASE WHEN s.isMBD = 1 THEN CAST((IsNull(b.EF,0)) as DECIMAL(18,2)) 
						 ELSE CAST((IsNull(s.totalEF,0)) as DECIMAL(18,2)) 
				END) as TotalKgCO2e, 
				CAST(CASE WHEN @totalScope1 = 0 THEN 0 ELSE 
					(CASE 
						WHEN s.isMBD = 1 THEN ((IsNull(b.EF,0)) / @totalScope1) * 100 
						ELSE (IsNull(s.totalEF,0) / @totalScope1) * 100 
					END)
				END AS DECIMAL(18,2)) as Pct,
        Case When s.isMBD = 1 Then 1 Else 0 END as [IsModelled]
		FROM #BAQDataWithBM b
	LEFT JOIN #SilverData s ON b.bmCategory = s.category
	 WHERE b.bmCategory in (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@scope1Categories, ','))

	UNION
	
	SELECT
		100 AS orderNo,
		'Scope-1' AS Scope,
		'Total Scope-1' AS Category,
		'' AS SubCategory,
		@totalScope1 AS TotalKgCO2e,
		100 AS Pct,
		0 AS IsModelled
	
	UNION

	-- SCOPE 2 Calculations
	SELECT 
				[order] as orderNo,
				'Scope-2' as Scope, 
				b.bmCategory as [Category], 
				b.category as [SubCategory],
				(CASE WHEN s.isMBD = 1 THEN CAST((IsNull(b.EF,0)) as DECIMAL(18,2)) 
						 ELSE CAST((IsNull(s.totalEF,0)) as DECIMAL(18,2)) 
				END) as TotalKgCO2e, 
				CAST(CASE WHEN @totalScope2 = 0 THEN 0 ELSE 
					(CASE 
						WHEN s.isMBD = 1 THEN ((IsNull(b.EF,0)) / @totalScope2) * 100 
						ELSE (IsNull(s.totalEF,0) / @totalScope2) * 100 
					END)
				END AS DECIMAL(18,2)) as Pct,
        Case When s.isMBD = 1 Then 1 Else 0 END as [IsModelled]
		FROM #BAQDataWithBM b
	LEFT JOIN #SilverData s ON b.bmCategory = s.category
	 WHERE b.bmCategory in (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@scope2Categories, ','))

	UNION
	
	SELECT
        100 AS orderNo,
        'Scope-2' AS Scope,
        'Total Scope-2' AS Category,
        '' AS SubCategory,
        @totalScope2 AS TotalKgCO2e,
        100 AS Pct,
        0 AS IsModelled
	
	UNION

	-- SCOPE 3 Calculations
	SELECT 
					[order] as orderNo,
					'Scope-3' as Scope, 
					b.bmCategory as [Category], 
					b.category as [SubCategory], 
					(CASE WHEN s.isMBD = 1 THEN CAST((IsNull(b.EF,0)) as DECIMAL(18,2)) 
						 ELSE CAST((IsNull(s.totalEF,0)) as DECIMAL(18,2)) 
					END) as TotalKgCO2e, 
					CAST(CASE WHEN @totalScope3 = 0 THEN 0 ELSE 
						(CASE 
							WHEN s.isMBD = 1 THEN ((IsNull(b.EF,0)) / @totalScope3) * 100 
							ELSE (IsNull(s.totalEF,0) / @totalScope3) * 100 
						END)
					END AS DECIMAL(18,2)) as Pct,
          Case When s.isMBD = 1 Then 1 Else 0 END as [IsModelled]
			FROM #BAQDataWithBM b
	LEFT JOIN #SilverData s ON b.bmCategory = s.category
	 WHERE b.bmCategory in (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@scope3Categories, ','))
	
	UNION

	-- SCOPE 3 WTT Calculations
	SELECT 
					b.[order] as orderNo,
					'Scope-3' as Scope, 
					CONCAT('WTT-',b.bmCategory) as [Category], 
					CONCAT('WTT-',b.category) as [SubCategory],
					(CASE WHEN s.isMBD = 1 THEN CAST(((ISNULL(b.WTT, 0) + ISNULL(b.TND, 0) + ISNULL(b.TNDWTT, 0))) as DECIMAL(18,2)) 
						 ELSE CAST(((ISNULL(TotalWTT, 0) + ISNULL(TotalTND, 0) + ISNULL(TotalTNDWTT, 0))) as DECIMAL(18,2))
					END) as TotalKgCO2e, 
					CAST(CASE WHEN @totalScope3 = 0 THEN 0 ELSE 
						(CASE 
							WHEN s.isMBD = 1 THEN CAST((((ISNULL(b.WTT, 0) + ISNULL(b.TND, 0) + ISNULL(b.TNDWTT, 0))) / @totalScope3) * 100 AS DECIMAL(18,2))
							ELSE CAST((((ISNULL(totalWTT, 0) + ISNULL(TotalTND, 0) + ISNULL(TotalTNDWTT, 0))) / @totalScope3) * 100 AS DECIMAL(18,2)) 
						END)
					END AS DECIMAL(18,2)) as Pct,
          Case When s.isMBD = 1 Then 1 Else 0 END as [IsModelled]
		FROM #BAQDataWithBM b
		LEFT JOIN #SilverData s ON b.bmCategory = s.category
	 WHERE NULLIF(bmCategory, '') IS NOT NULL AND bmCategory NOT IN ('Purchased Goods and Services','Waste and Recycling')
	
	UNION
	
	 SELECT
        100 AS orderNo,
        'Scope-3' AS Scope,
        'Total Scope-3' AS Category,
        '' AS SubCategory,
        @totalScope3 AS TotalKgCO2e,
        100 AS Pct,
        0 AS IsModelled

) X
GROUP BY X.orderNo, X.Scope, X.Category, X.IsModelled;

END
ELSE
BEGIN	
	

SELECT MAX(id) as [ID], MAX([order]) as [Order], @BAQSubmissionid as [Submission Id], @submissionDate as [Submission Date], @company as [Company], @headCount as [Head Count], @revenue as [Revenue],
			 [Scope], [Category], STRING_AGG([Sub Category], ', ') as [Sub Categories], SUM(ISNULL([Total Kg CO2e], 0)) as [Total Kg CO2e], 
       SUM(ISNULL([% of total emissions scope wise], 0)) as [% of total emissions scope wise], [IsModelled],
       @name as [Name], @email as [Email], @jobtitle as [Job Title], @startDate as [Report Start Date], @endDate as [Report End Date]
 FROM (
	-- SCOPE 1 Calculations
	SELECT 1 as [id], 
				[order],
				'Scope-1' as Scope, 
				b.bmCategory as [Category], 
				b.category as [Sub Category], 
				(CASE WHEN s.isMBD = 1 THEN CAST((b.EF) as DECIMAL(18,2)) 
						 ELSE CAST((s.totalEF) as DECIMAL(18,2)) 
				END) as [Total Kg CO2e], 
				CAST(CASE WHEN @totalScope1 = 0 THEN 0 ELSE 
					(CASE 
						WHEN s.isMBD = 1 THEN ((b.EF) / @totalScope1) * 100 
						ELSE (s.totalEF / @totalScope1) * 100 
					END)
				END AS DECIMAL(18,2)) as [% of total emissions scope wise],
        Case When s.isMBD = 1 Then 1 Else 0 END as [IsModelled]
		FROM #BAQDataWithBM b
	LEFT JOIN #SilverData s ON b.bmCategory = s.category
	 WHERE b.bmCategory in (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@scope1Categories, ','))

	UNION
	
	SELECT 2 as [id], '100', 'Total Scope-1' as [Scope], '', '', @totalScope1, '100' , 0
	
	UNION

	-- SCOPE 2 Calculations
	SELECT 3 as [id], 
				[order],
				'Scope-2' as Scope, 
				b.bmCategory as [Category], 
				b.category as [Sub Category],
				(CASE WHEN s.isMBD = 1 THEN CAST((b.EF) as DECIMAL(18,2)) 
						 ELSE CAST((s.totalEF) as DECIMAL(18,2)) 
				END) as [Total Kg CO2e], 
				CAST(CASE WHEN @totalScope2 = 0 THEN 0 ELSE 
					(CASE 
						WHEN s.isMBD = 1 THEN ((b.EF) / @totalScope2) * 100 
						ELSE (s.totalEF / @totalScope2) * 100 
					END)
				END AS DECIMAL(18,2)) as [% of total emissions scope wise],
        Case When s.isMBD = 1 Then 1 Else 0 END as [IsModelled]
		FROM #BAQDataWithBM b
	LEFT JOIN #SilverData s ON b.bmCategory = s.category
	 WHERE b.bmCategory in (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@scope2Categories, ','))

	UNION
	
	SELECT 4 as [id], '100', 'Total Scope-2' ,'', '',  @totalScope2 , '100' , 0
	
	UNION

	-- SCOPE 3 Calculations
	SELECT 5 as [id], 
					[order],
					'Scope-3', 
					b.bmCategory, 
					b.category, 
					(CASE WHEN s.isMBD = 1 THEN CAST((b.EF) as DECIMAL(18,2)) 
						 ELSE CAST((s.totalEF) as DECIMAL(18,2)) 
					END) as [Total Kg CO2e], 
					CAST(CASE WHEN @totalScope3 = 0 THEN 0 ELSE 
						(CASE 
							WHEN s.isMBD = 1 THEN ((b.EF) / @totalScope3) * 100 
							ELSE (s.totalEF / @totalScope3) * 100 
						END)
					END AS DECIMAL(18,2)) as [% of total emissions scope wise],
          Case When s.isMBD = 1 Then 1 Else 0 END as [IsModelled]
			FROM #BAQDataWithBM b
	LEFT JOIN #SilverData s ON b.bmCategory = s.category
	 WHERE b.bmCategory in (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@scope3Categories, ','))
	
	UNION

	-- SCOPE 3 WTT Calculations
	SELECT 6 as [id], 
					b.[order],
					'Scope-3' as Scope, 
					CONCAT('WTT-',b.bmCategory), 
					CONCAT('WTT-',b.category),
					(CASE WHEN s.isMBD = 1 THEN CAST(((ISNULL(b.WTT, 0) + ISNULL(b.TND, 0) + ISNULL(b.TNDWTT, 0))) as DECIMAL(18,2)) 
						 ELSE CAST(((ISNULL(TotalWTT, 0) + ISNULL(TotalTND, 0) + ISNULL(TotalTNDWTT, 0))) as DECIMAL(18,2))
					END) as [Total Kg CO2e], 
					CAST(CASE WHEN @totalScope3 = 0 THEN 0 ELSE 
						(CASE 
							WHEN s.isMBD = 1 THEN CAST((((ISNULL(b.WTT, 0) + ISNULL(b.TND, 0) + ISNULL(b.TNDWTT, 0))) / @totalScope3) * 100 AS DECIMAL(18,2))
							ELSE CAST((((ISNULL(totalWTT, 0) + ISNULL(TotalTND, 0) + ISNULL(TotalTNDWTT, 0))) / @totalScope3) * 100 AS DECIMAL(18,2)) 
						END)
					END AS DECIMAL(18,2)) as [% of total emissions scope wise],
          Case When s.isMBD = 1 Then 1 Else 0 END as [IsModelled]
		FROM #BAQDataWithBM b
		LEFT JOIN #SilverData s ON b.bmCategory = s.category
	 WHERE NULLIF(bmCategory, '') IS NOT NULL AND bmCategory NOT IN ('Purchased Goods and Services','Waste and Recycling')
	
	UNION
	
	SELECT 7 as [id], '100', 'Total Scope-3','', '', @totalScope3, '100', 0

) as tbl 	
	GROUP BY [Scope], [Category], [IsModelled]
	ORDER BY [id], [order]
	
END	

-- 	SELECT * FROM #BAQData;
-- 	SELECT * FROM #SilverData;
-- 	SELECT * FROM #BAQDataWithBM;
-- 	SELECT @totalScope3EF as totalScope3EF, @totalScope3WTT as totalScope3WTT;
	
	DROP TABLE #BAQData;
	DROP TABLE #BAQDataWithBM;
	DROP TABLE #SilverData;
  drop table if EXISTS #HomeWorkingData;
  drop table if EXISTS #CommutingData;
  drop table if EXISTS #CHWSubmissions;

END
GO


-- ----------------------------
-- procedure structure for spSilver_DataOutputDetailedWrapper_Portal
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[DataModel].[spSilver_DataOutputDetailedWrapper_Portal]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [DataModel].[spSilver_DataOutputDetailedWrapper_Portal]
GO

CREATE PROCEDURE [DataModel].[spSilver_DataOutputDetailedWrapper_Portal] 
	@certId int,
	@emissionProfileId INT,
	@dataInsert int = 0
AS
BEGIN
	
    DECLARE @BAQSubmissionId bigint;
    DECLARE @SilverSubmissionIds nvarchar(max), @CHWSubmissionIds nvarchar(max);
    
    SET @SilverSubmissionIds = (SELECT STRING_AGG([dimSubmissionId], ',') FROM portal.CertFormSubmissions 
                                WHERE dimFormId not in (14, 29, 33, 11, 26) and certId = @certId and isProcessed=1);
    
    SELECT @BAQSubmissionId = MAX(dimSubmissionId)
	FROM portal.CertFormSubmissions
	WHERE dimFormId IN (14, 29, 33) AND certId = @certId AND isProcessed = 1;
    
    IF @SilverSubmissionIds IS NULL
    BEGIN
      SELECT 'Could not find Silver submissionIds' as [error]
    END
    
    IF @BAQSubmissionId IS NULL
    BEGIN
      SELECT 'Could not find BAQ submissionId' as [error]
    END
    
    Declare @HomeWorkingHeadCount int, @CommutingHeadCount int;
    Select @HomeWorkingHeadCount = cast(BAQ_OfficeHeadcount as int), 
           @CommutingHeadCount = cast(BAQ_TotalHeadcount as int) - cast( BAQ_OfficeHeadcount as int)
    From DataModel.BlueAwardSubmissionData Where dimSubmissionId = @BAQSubmissionid;
        
    SET @CHWSubmissionIds = (SELECT STRING_AGG([dimSubmissionId], ',') FROM portal.CertFormSubmissions 
                              WHERE dimFormId in (11, 26) and certId = @certId and isProcessed=1);                          
  
    DECLARE @hwRatio decimal(10,4) = NULL, @cmRatio decimal(10,4) = NULL;
    
    IF @CHWSubmissionIds IS NULL OR @HomeWorkingHeadCount Is Null OR @CommutingHeadCount Is Null
      BEGIN
        SET @hwRatio = 1.0;
        SET @cmRatio = 1.0;
      END
    ELSE
      BEGIN
        Declare @HomeWorkingSubmissionCount int, @CommutingSubmissionCount int;
      
        SELECT @CommutingSubmissionCount = Count(distinct submissionId) ,
               @HomeWorkingSubmissionCount = Sum(CASE WHEN emissionActivityId IN (357, 358, 359) THEN 1 ELSE 0 END)
        FROM DataModel.vSilverSubmissions 
        WHERE submissionId IN (
              SELECT value FROM STRING_SPLIT(@CHWSubmissionIds, ',')
          );
        
        Set @CommutingSubmissionCount = @CommutingSubmissionCount - @HomeWorkingSubmissionCount;

        IF @HomeWorkingSubmissionCount > 0
            SET @hwRatio = 1.0 * @HomeWorkingHeadCount / @HomeWorkingSubmissionCount;
        else
          set @hwRatio = 1.0;

        IF @CommutingSubmissionCount > 0
            SET @cmRatio = 1.0 * @CommutingHeadCount / @CommutingSubmissionCount;
        else
          set @cmRatio = 1.0;
      END
      
    EXEC DataModel.spSilver_DataOutputDetailed_Portal	
            @silverSubmissionIds = @SilverSubmissionIds, 
            @emissionProfileId = @emissionProfileId,
            @hwRatio = @hwRatio,
            @cmRatio = @cmRatio,
            @certId =  @certId,
            @dataInsert = @dataInsert;
	
END
GO


-- ----------------------------
-- procedure structure for spSilver_DataOutputWrapper_Portal
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[DataModel].[spSilver_DataOutputWrapper_Portal]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [DataModel].[spSilver_DataOutputWrapper_Portal]
GO

CREATE PROCEDURE [DataModel].[spSilver_DataOutputWrapper_Portal] 
	@certId int,
	@emissionProfileId INT,
	@dataInsert int = 0
AS
BEGIN
	
	DECLARE @BAQSubmissionId bigint;
	DECLARE @SilverSubmissionIds nvarchar(max), @CHWSubmissionIds nvarchar(max);
  
  SET @SilverSubmissionIds = (SELECT STRING_AGG([dimSubmissionId], ',') FROM portal.CertFormSubmissions 
                              WHERE dimFormId not in (14, 29, 33, 11, 26) and certId = @certId and isProcessed=1);
                              
  SET @CHWSubmissionIds = (SELECT STRING_AGG([dimSubmissionId], ',') FROM portal.CertFormSubmissions 
                              WHERE dimFormId in (11, 26) and certId = @certId and isProcessed=1);                          
  
  SET @BAQSubmissionId = (SELECT top 1 [dimSubmissionId] FROM portal.CertFormSubmissions 
                              WHERE dimFormId in (14, 29, 33) and certId = @certId and isProcessed=1);
    
  IF @BAQSubmissionId IS NULL
	BEGIN
		SELECT 'Could not find BAQ submissionId' as [error]
		RETURN 0;
	END
	
	IF @SilverSubmissionIds IS NULL
	BEGIN
		SELECT 'Could not find Silver submissionIds' as [error]
	END
	-- select @BAQSubmissionId, @SilverSubmissionIds;
	EXEC DataModel.spSilver_DataOutputByScope_Portal		@BAQSubmissionid = @BAQSubmissionId, 
                                                  @silverSubmissionIds = @SilverSubmissionIds, 
                                                  @CHWSubmissionIds = @CHWSubmissionIds,
                                                  @emissionProfileId = @emissionProfileId,
                                                  @dataInsert = @dataInsert;
	
	
END
GO


-- ----------------------------
-- procedure structure for spFormSubmission_Save
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spFormSubmission_Save]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spFormSubmission_Save]
GO

CREATE PROCEDURE [portal].[spFormSubmission_Save]
    @formId INT,
    @submissionId int, 
    @userId int,
    @submissionData NVARCHAR(MAX),
    @responses NVARCHAR(MAX),
    @status int = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    -- DECLARE @submissionId INT;
    DECLARE @currentDate DATETIME2 = GETDATE();
    DECLARE @action nvarchar(15);
    
    BEGIN TRY
        BEGIN TRANSACTION;

            if not exists (select * from portal.FormSubmissions where submissionId = @submissionId)
              BEGIN
                INSERT into [portal].[FormSubmissions] (formId, userId, submissionData, createdAt, status)
                              values (@formId, @userId, @submissionData, @currentDate, @status);
                              
                SELECT @submissionId = SCOPE_IDENTITY();
                set @action = 'insert';
              END
            else
              BEGIN
                -- Update main submission record
                UPDATE [portal].[FormSubmissions] 
                SET 
                    SubmissionData = @submissionData,
                    UpdatedAt = @currentDate,
                    Status = @status
                WHERE submissionId = @submissionId;
                
                set @action = 'update';
              END
              
              -- Submitted
              if @status = 1 
              begin 
                -- Delete existing responses
                DELETE FROM [portal].[FormSubmissionResponses] 
                WHERE submissionId = @submissionId;
              
                -- Insert responses
                IF @responses IS NOT NULL
                BEGIN
                    INSERT INTO [portal].[FormSubmissionResponses] 
                    (submissionId, QuestionId, ResponseData, ResponseDataType)
                    SELECT 
                        @submissionId,
                        [QuestionId],
                        [ResponseValue],
                        [ResponseDataType]
                    FROM OPENJSON(@responses)
                    WITH (
                        QuestionId INT '$.questionId',
                        ResponseValue NVARCHAR(MAX) '$.responseValue',
                        ResponseDataType NVARCHAR(50) '$.responseDataType'
                    )
                    Where ResponseValue is not null;
                END;
            
            
                Update portal.CertFormSubmissions
                  set isDraft = 0,
                      isProcessed = 0,
                      userId = @userId, -- who submitted
                      dateSubmitted = @currentDate
                Where submissionId = @submissionId;
                
                set @action = 'submit';
              end;
        
              -- Audit log
              INSERT into portal.FormSubmissionAuditTrail (submissionId, userId, [action], changes, createdAt)
                                                  values (@submissionId, @userId, @action, @submissionData, @currentDate);
        
        COMMIT TRANSACTION;
        
        -- Return the submission ID
        SELECT @submissionId AS submissionId;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
