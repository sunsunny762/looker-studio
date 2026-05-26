/****** Object:  Database [nczdev]    Script Date: 4/11/2024 10:08:53 AM ******/
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'nczdev')
BEGIN
CREATE DATABASE [nczdev]  (EDITION = 'GeneralPurpose', SERVICE_OBJECTIVE = 'GP_S_Gen5_1', MAXSIZE = 32 GB) WITH CATALOG_COLLATION = SQL_Latin1_General_CP1_CI_AS, LEDGER = OFF;

END
GO
ALTER DATABASE [nczdev] SET COMPATIBILITY_LEVEL = 150
GO
ALTER DATABASE [nczdev] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [nczdev] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [nczdev] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [nczdev] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [nczdev] SET ARITHABORT OFF 
GO
ALTER DATABASE [nczdev] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [nczdev] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [nczdev] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [nczdev] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [nczdev] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [nczdev] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [nczdev] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [nczdev] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [nczdev] SET ALLOW_SNAPSHOT_ISOLATION ON 
GO
ALTER DATABASE [nczdev] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [nczdev] SET READ_COMMITTED_SNAPSHOT ON 
GO
ALTER DATABASE [nczdev] SET  MULTI_USER 
GO
ALTER DATABASE [nczdev] SET ENCRYPTION ON
GO
ALTER DATABASE [nczdev] SET QUERY_STORE = ON
GO
ALTER DATABASE [nczdev] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 100, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)
GO
/*** The scripts of database scoped configurations in Azure should be executed inside the target database connection. ***/
GO
-- ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 8;
GO
/****** Object:  User [nczBasicUser]    Script Date: 4/11/2024 10:08:53 AM ******/
CREATE USER [nczBasicUser] FOR LOGIN [basicUser] WITH DEFAULT_SCHEMA=[DataModel]
GO
sys.sp_addrolemember @rolename = N'db_owner', @membername = N'nczBasicUser'
GO
/****** Object:  Schema [clickup]    Script Date: 4/11/2024 10:08:53 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'clickup')
EXEC sys.sp_executesql N'CREATE SCHEMA [clickup]'
GO
/****** Object:  Schema [DataModel]    Script Date: 4/11/2024 10:08:53 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'DataModel')
EXEC sys.sp_executesql N'CREATE SCHEMA [DataModel]'
GO
/****** Object:  Schema [Dimension]    Script Date: 4/11/2024 10:08:53 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Dimension')
EXEC sys.sp_executesql N'CREATE SCHEMA [Dimension]'
GO
/****** Object:  Schema [Emissions]    Script Date: 4/11/2024 10:08:53 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Emissions')
EXEC sys.sp_executesql N'CREATE SCHEMA [Emissions]'
GO
/****** Object:  Schema [Fact]    Script Date: 4/11/2024 10:08:53 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Fact')
EXEC sys.sp_executesql N'CREATE SCHEMA [Fact]'
GO
/****** Object:  Schema [Forms]    Script Date: 4/11/2024 10:08:53 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Forms')
EXEC sys.sp_executesql N'CREATE SCHEMA [Forms]'
GO
/****** Object:  Schema [Lookups]    Script Date: 4/11/2024 10:08:53 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Lookups')
EXEC sys.sp_executesql N'CREATE SCHEMA [Lookups]'
GO
/****** Object:  Schema [Utilities]    Script Date: 4/11/2024 10:08:53 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Utilities')
EXEC sys.sp_executesql N'CREATE SCHEMA [Utilities]'
GO
/****** Object:  UserDefinedTableType [dbo].[TaskPersonCustomer]    Script Date: 4/11/2024 10:08:53 AM ******/
IF NOT EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'TaskPersonCustomer' AND ss.name = N'dbo')
CREATE TYPE [dbo].[TaskPersonCustomer] AS TABLE(
	[taskId] [nvarchar](36) NULL,
	[parentId] [nvarchar](36) NULL
)
GO
/****** Object:  UserDefinedFunction [Utilities].[CalculateEf]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Utilities].[CalculateEf]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'CREATE FUNCTION [Utilities].[CalculateEf]
( 
	@emissionActivityId INT
	,@emissionProfileId INT
	,@userInput decimal(10,2)
	,@conversionFactor decimal(10,4)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
  DECLARE @ef decimal(10,5), @id INT;

	SELECT TOP 1 @id = id, @ef = ef 
		FROM [Emissions].[EmissionFactor] 
	 WHERE [activityId] = @emissionActivityId
		 AND [emissionProfileId] = @emissionProfileId

	DECLARE @result DECIMAL(10,2)
	IF @id IS NULL 
		SET @result = 0;
	ELSE
		SET @result = @userInput * @conversionFactor * cast(ISNULL(@ef, 0) as decimal(10,4)) 

	RETURN @result;

END

' 
END
GO
/****** Object:  UserDefinedFunction [Utilities].[CalculateTnd]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Utilities].[CalculateTnd]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'CREATE FUNCTION [Utilities].[CalculateTnd]
( 
	@emissionActivityId INT
	,@emissionProfileId INT
	,@userInput decimal(10,2)
	,@conversionFactor decimal(10,4)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
  DECLARE @tnd decimal(10,5), @id INT;

	SELECT TOP 1 @id = id, @tnd = tnd 
		FROM [Emissions].[EmissionFactor] 
	 WHERE [activityId] = @emissionActivityId
		 AND [emissionProfileId] = @emissionProfileId

	DECLARE @result DECIMAL(10,2)
	IF @id IS NULL 
		SET @result = 0;
	ELSE
		SET @result = @userInput * @conversionFactor * cast(ISNULL(@tnd, 0) as decimal(10,4)) 

	RETURN @result;

END


' 
END
GO
/****** Object:  UserDefinedFunction [Utilities].[CalculateTndWtt]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Utilities].[CalculateTndWtt]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'CREATE FUNCTION [Utilities].[CalculateTndWtt]
( 
	@emissionActivityId INT
	,@emissionProfileId INT
	,@userInput decimal(10,2)
	,@conversionFactor decimal(10,4)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
  DECLARE @tndWtt decimal(10,5), @id INT;

	SELECT TOP 1 @id = id, @tndWtt = tndWtt 
		FROM [Emissions].[EmissionFactor] 
	 WHERE [activityId] = @emissionActivityId
		 AND [emissionProfileId] = @emissionProfileId

	DECLARE @result DECIMAL(10,2)
	IF @id IS NULL 
		SET @result = 0;
	ELSE
		SET @result = @userInput * @conversionFactor * cast(ISNULL(@tndWtt, 0) as decimal(10,4)) 

	RETURN @result;

END



' 
END
GO
/****** Object:  UserDefinedFunction [Utilities].[CalculateTotalEmission]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Utilities].[CalculateTotalEmission]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'CREATE FUNCTION [Utilities].[CalculateTotalEmission]
( 
	@emissionActivityId INT
	,@emissionProfileId INT
	,@userInput decimal(10,2)
	,@conversionFactor decimal(10,5)
)
RETURNS DECIMAL(15,2)
AS
BEGIN
  DECLARE @ef decimal(10,5), @wtt decimal(10,5), @tnd decimal(10,5), @tndWtt decimal(10,5), @id INT;

	SELECT TOP 1 @id = id
				,@ef = ef 
				,@wtt = wtt 
				,@tnd = tnd 
				,@tndWtt = tndWtt 
		FROM [Emissions].[EmissionFactor] 
	 WHERE [activityId] = @emissionActivityId
		 AND [emissionProfileId] = @emissionProfileId

	DECLARE @result DECIMAL(15,5)
	IF @id IS NULL 
		SET @result = 0;
	ELSE
	BEGIN
		DECLARE @effectiveInput DECIMAL(15, 5) = @userInput * @conversionFactor 
		SET @result = (@effectiveInput * cast(ISNULL(@ef, 0) as decimal(15,5)))
								+ (@effectiveInput * cast(ISNULL(@wtt, 0) as decimal(15,5)))
								+ (@effectiveInput * cast(ISNULL(@tnd, 0) as decimal(10,5)))
								+ (@effectiveInput * cast(ISNULL(@tndWtt, 0) as decimal(10,5)))
	END
	RETURN ROUND(@result, 2);

END
' 
END
GO
/****** Object:  UserDefinedFunction [Utilities].[CalculateWtt]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Utilities].[CalculateWtt]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'CREATE FUNCTION [Utilities].[CalculateWtt]
( 
	@emissionActivityId INT
	,@emissionProfileId INT
	,@userInput decimal(10,2)
	,@conversionFactor decimal(10,4)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
  DECLARE @wtt decimal(10,5), @id INT;

	SELECT TOP 1 @id = id, @wtt = wtt 
		FROM [Emissions].[EmissionFactor] 
	 WHERE [activityId] = @emissionActivityId
		 AND [emissionProfileId] = @emissionProfileId

	DECLARE @result DECIMAL(10,2)
	IF @id IS NULL 
		SET @result = 0;
	ELSE
		SET @result = @userInput * @conversionFactor * cast(ISNULL(@wtt, 0) as decimal(10,4)) 

	RETURN @result;

END


' 
END
GO
/****** Object:  UserDefinedFunction [Utilities].[DateToEpoch]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Utilities].[DateToEpoch]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'
CREATE FUNCTION [Utilities].[DateToEpoch]
(
	@dt datetime
)
RETURNS bigint
AS
BEGIN
	RETURN DATEDIFF(SECOND,''1970-01-01'', IsNull(@dt, GetDate()))
END
' 
END
GO
/****** Object:  UserDefinedFunction [Utilities].[DateToEpochTZ]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Utilities].[DateToEpochTZ]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'
CREATE FUNCTION [Utilities].[DateToEpochTZ]
(
    @dt datetime
)
RETURNS bigint
AS
BEGIN
    DECLARE @offset INT = DATEPART(tz, IsNull(@dt, GetDate()) AT TIME ZONE ''GMT Standard Time'')
    DECLARE @d DATETIME = DATEADD(MINUTE, @offset*-1, IsNull(@dt, GetDate())) 
    RETURN DATEDIFF(SECOND,''1970-01-01'', IsNull(@d, GetDate()))
END
' 
END
GO
/****** Object:  UserDefinedFunction [Utilities].[EpochToDate]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Utilities].[EpochToDate]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'CREATE FUNCTION [Utilities].[EpochToDate]
(
	@ep BIGINT = NULL
)
RETURNS DATETIME
AS
BEGIN
	IF @ep IS NULL
	BEGIN
		RETURN GETUTCDATE()
	END
	DECLARE @unadjustedDate datetime = DATEADD(SECOND, @ep,''1970-01-01'')
	RETURN DateAdd(Minute, DatePart(tz, @unadjustedDate AT TIME ZONE ''GMT Standard Time''), @unadjustedDate)
END
' 
END
GO
/****** Object:  Table [Emissions].[EmissionActivity]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Emissions].[EmissionActivity]') AND type in (N'U'))
BEGIN
CREATE TABLE [Emissions].[EmissionActivity](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[parentId] [int] NULL,
	[name] [nvarchar](100) NOT NULL,
	[description] [nvarchar](250) NULL,
	[active] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [Forms].[JotformSubmission]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Forms].[JotformSubmission]') AND type in (N'U'))
BEGIN
CREATE TABLE [Forms].[JotformSubmission](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[submissionId] [nvarchar](25) NOT NULL,
	[submissionDate] [datetime] NOT NULL,
	[managementBasedDecision] [bit] NULL,
	[optedIn] [bit] NULL,
	[createdDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [Fact].[Emission]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Fact].[Emission]') AND type in (N'U'))
BEGIN
CREATE TABLE [Fact].[Emission](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[emissionActivityId] [int] NOT NULL,
	[entityId] [int] NOT NULL,
	[entityTypeId] [int] NOT NULL,
	[submissionId] [int] NULL,
	[month] [int] NULL,
	[year] [int] NULL,
	[reportingFrequencyId] [int] NULL,
	[userInput] [decimal](10, 2) NULL,
	[conversionFactor] [decimal](10, 4) NULL,
	[dataUnit] [nvarchar](25) NULL,
	[active] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [Dimension].[Form]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Dimension].[Form]') AND type in (N'U'))
BEGIN
CREATE TABLE [Dimension].[Form](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](100) NOT NULL,
	[description] [nvarchar](250) NULL,
	[sourceId] [int] NOT NULL,
	[dataSourceId] [int] NOT NULL,
	[entityTypeId] [int] NOT NULL,
	[categoryId] [int] NULL,
	[active] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [Dimension].[Submission]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Dimension].[Submission]') AND type in (N'U'))
BEGIN
CREATE TABLE [Dimension].[Submission](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[entityId] [int] NOT NULL,
	[entityTypeId] [int] NOT NULL,
	[formId] [int] NOT NULL,
	[sourceId] [int] NOT NULL,
	[dataSourceId] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [Dimension].[CustomerProfile]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Dimension].[CustomerProfile]') AND type in (N'U'))
BEGIN
CREATE TABLE [Dimension].[CustomerProfile](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](100) NOT NULL,
	[reference] [nvarchar](25) NULL,
	[description] [nvarchar](250) NULL,
	[periodStart] [date] NULL,
	[periodEnd] [date] NULL,
	[headCount] [int] NULL,
	[annualRevenue] [decimal](20, 2) NULL,
	[industryType] [nvarchar](100) NULL,
	[active] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [Lookups].[FormCategory]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Lookups].[FormCategory]') AND type in (N'U'))
BEGIN
CREATE TABLE [Lookups].[FormCategory](
	[id] [int] NOT NULL,
	[name] [nvarchar](50) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [Dimension].[Customer]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Dimension].[Customer]') AND type in (N'U'))
BEGIN
CREATE TABLE [Dimension].[Customer](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](100) NOT NULL,
	[code] [nvarchar](25) NULL,
	[description] [nvarchar](250) NULL,
	[active] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [Lookups].[ReportingFrequency]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Lookups].[ReportingFrequency]') AND type in (N'U'))
BEGIN
CREATE TABLE [Lookups].[ReportingFrequency](
	[id] [int] NOT NULL,
	[name] [nvarchar](50) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [Emissions].[EmissionFactor]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Emissions].[EmissionFactor]') AND type in (N'U'))
BEGIN
CREATE TABLE [Emissions].[EmissionFactor](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[activityId] [int] NOT NULL,
	[ef] [decimal](10, 5) NULL,
	[wtt] [decimal](10, 5) NULL,
	[tnd] [decimal](10, 5) NULL,
	[tndWtt] [decimal](10, 5) NULL,
	[year] [int] NULL,
	[emissionProfileId] [int] NULL,
	[active] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  View [DataModel].[vCertificationSubmissionsWithCalcs]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[DataModel].[vCertificationSubmissionsWithCalcs]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [DataModel].[vCertificationSubmissionsWithCalcs] AS 
SELECT cp.id as [customerProfileId]
			,cp.reference as [customerReference]
			,c.id as [customerId]
			,c.name as [customerName]
			,f.id as [formId]
			,f.name as [formName]
			,fc.name as [formCategory]
			,cp.periodStart
			,cp.periodEnd
			,ea.id as [emissionActivityId]
			,ea.name as [emissionActivityName]
			,ef.ef as [ef_P1]
			,ef.wtt as [wtt_P1]
			,ef.tnd as [tnd_P1]
			,ef.tndWtt as [tndWtt_P1]
			,r.id as [reportingFrequencyId]
			,r.name as [reportingFrequency]
			,e.submissionId
			,e.[month]
			,e.userInput
			,e.conversionFactor
			,e.dataUnit
			,js.submissionId as [JotformSubmissionId]
			,js.submissionDate
			,[Utilities].[CalculateEf](e.emissionActivityId, 1, e.userInput, e.conversionFactor) as [totalEf_P1]
			,[Utilities].[CalculateWtt](e.emissionActivityId, 1, e.userInput, e.conversionFactor) as [totalWtt_P1]
			,[Utilities].[CalculateTnd](e.emissionActivityId, 1, e.userInput, e.conversionFactor) as [totalTnd_P1]
			,[Utilities].[CalculateTndWtt](e.emissionActivityId, 1, e.userInput, e.conversionFactor) as [totalTndWtt_P1]
			,[Utilities].[CalculateTotalEmission](e.emissionActivityId, 1, e.userInput, e.conversionFactor) as [totalEmission_P1]
	FROM Fact.Emission e
INNER JOIN Dimension.Submission s on s.id = e.submissionId
LEFT JOIN Dimension.CustomerProfile cp on cp.id = e.entityId AND e.entityTypeId = 1
LEFT JOIN Dimension.customer c on c.id = e.entityId AND e.entityTypeId = 4
INNER JOIN Dimension.Form f on f.id = s.formId
INNER JOIN Emissions.EmissionActivity ea on ea.id = e.emissionActivityId
LEFT JOIN Emissions.EmissionFactor ef on ef.activityId = ea.id AND ef.emissionProfileId = 1
LEFT JOIN Lookups.ReportingFrequency r on r.id = e.reportingFrequencyId
LEFT JOIN Lookups.FormCategory fc on fc.id = f.categoryId
LEFT JOIN Forms.JotformSubmission js on js.id = s.sourceId AND s.dataSourceId = 1
WHERE e.active = 1 AND e.entityTypeId in (1, 4)' 
GO
/****** Object:  View [DataModel].[vCertificationSubsmissions]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[DataModel].[vCertificationSubsmissions]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [DataModel].[vCertificationSubsmissions] AS 
SELECT cp.id as [customerProfileId]
			,cp.reference as [customerReference]
			,f.id as [formId]
			,f.name as [formName]
			,fc.name as [formCategory]
			,cp.periodStart
			,cp.periodEnd
			,ea.id as [emissionActivityId]
			,ea.name as [emissionActivityName]
			,r.id as [reportingFrequencyId]
			,r.name as [reportingFrequency]
			,e.submissionId
			,e.[month]
			,e.userInput
			,e.conversionFactor
			,e.dataUnit
	FROM Fact.Emission e
INNER JOIN Dimension.Submission s on s.id = e.submissionId
INNER JOIN Dimension.CustomerProfile cp on cp.id = e.entityId AND e.entityTypeId = 1
INNER JOIN Dimension.Form f on f.id = s.formId
INNER JOIN Emissions.EmissionActivity ea on ea.id = e.emissionActivityId
LEFT JOIN Lookups.ReportingFrequency r on r.id = e.reportingFrequencyId
LEFT JOIN Lookups.FormCategory fc on fc.id = f.categoryId
WHERE e.active = 1
' 
GO
/****** Object:  Table [Forms].[Response]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Forms].[Response]') AND type in (N'U'))
BEGIN
CREATE TABLE [Forms].[Response](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[submissionId] [int] NOT NULL,
	[questionId] [int] NOT NULL,
	[value] [nvarchar](max) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO
/****** Object:  Table [Dimension].[Event]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Dimension].[Event]') AND type in (N'U'))
BEGIN
CREATE TABLE [Dimension].[Event](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[title] [nvarchar](100) NOT NULL,
	[reference] [nvarchar](50) NOT NULL,
	[type] [nvarchar](25) NULL,
	[organiserName] [nvarchar](100) NULL,
	[organiserEmail] [nvarchar](100) NULL,
	[companyName] [nvarchar](100) NULL,
	[location] [nvarchar](250) NULL,
	[locationType] [nvarchar](100) NULL,
	[startDateTime] [datetime] NULL,
	[endDateTime] [datetime] NULL,
	[noOfAttendees] [int] NULL,
	[active] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [Emissions].[EmissionCategory]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Emissions].[EmissionCategory]') AND type in (N'U'))
BEGIN
CREATE TABLE [Emissions].[EmissionCategory](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](100) NOT NULL,
	[description] [nvarchar](250) NULL,
	[parentId] [int] NULL,
	[active] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  View [DataModel].[vEventSubmissionsWithCalcs]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[DataModel].[vEventSubmissionsWithCalcs]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [DataModel].[vEventSubmissionsWithCalcs] AS 
SELECT ev.id as [eventId]
			,ev.reference as [eventReference]
			--,ev.title as [eventTitle]
			--,ev.startDateTime
			--,ev.endDateTime
			--,ev.noOfAttendees as attendees
			,f.id as [formId]
			,f.name as [formName]
			,fc.name as [formCategory]
			,ec.id as [categoryId]
			,ec.name as [categoryName]
			,ea.id as [emissionActivityId]
			,ea.name as [emissionActivityName]
			,ef.ef as [ef_P1]
			,ef.wtt as [wtt_P1]
			,ef.tnd as [tnd_P1]
			,e.submissionId
			,e.[month]
			,e.userInput
			,e.conversionFactor
			,e.dataUnit
			,js.submissionDate
			,(SELECT [value] FROM Forms.Response r WHERE r.submissionId = e.submissionId AND r.questionId = 128) as [userName]
			,(SELECT [value] FROM Forms.Response r WHERE r.submissionId = e.submissionId AND r.questionId = 129) as [userEmail]
			,[Utilities].[CalculateEf](e.emissionActivityId, 1, e.userInput, e.conversionFactor) as [totalEf_P1]
			,[Utilities].[CalculateWtt](e.emissionActivityId, 1, e.userInput, e.conversionFactor) as [totalWtt_P1]
			,[Utilities].[CalculateTnd](e.emissionActivityId, 1, e.userInput, e.conversionFactor) as [totalTnd_P1]
			,[Utilities].[CalculateTndWtt](e.emissionActivityId, 1, e.userInput, e.conversionFactor) as [totalTndWtt_P1]
			,[Utilities].[CalculateTotalEmission](e.emissionActivityId, 1, e.userInput, e.conversionFactor) as [totalEmission_P1]
	FROM Fact.Emission e
INNER JOIN Dimension.Submission s on s.id = e.submissionId
INNER JOIN Dimension.Event ev on ev.id = e.entityId AND e.entityTypeId = 2
INNER JOIN Dimension.Form f on f.id = s.formId
INNER JOIN Emissions.EmissionActivity ea on ea.id = e.emissionActivityId
LEFT JOIN Emissions.EmissionFactor ef on ef.activityId = ea.id AND ef.emissionProfileId = 1
LEFT JOIN Lookups.FormCategory fc on fc.id = f.categoryId
LEFT JOIN Emissions.EmissionCategory ec on ec.id = ea.parentId
LEFT JOIN Forms.JotformSubmission js on js.id = s.sourceId AND s.dataSourceId = 1' 
GO
/****** Object:  Table [clickup].[PersonCompany]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[PersonCompany]') AND type in (N'U'))
BEGIN
CREATE TABLE [clickup].[PersonCompany](
	[personTaskId] [nvarchar](25) NOT NULL,
	[companyTaskId] [nvarchar](25) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[personTaskId] ASC,
	[companyTaskId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [clickup].[Task]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[Task]') AND type in (N'U'))
BEGIN
CREATE TABLE [clickup].[Task](
	[id] [nvarchar](15) NOT NULL,
	[name] [nvarchar](250) NOT NULL,
	[description] [nvarchar](max) NULL,
	[folderId] [bigint] NULL,
	[listId] [bigint] NULL,
	[spaceId] [bigint] NULL,
	[status] [nvarchar](50) NULL,
	[createdBy] [int] NULL,
	[startDate] [bigint] NULL,
	[dueDate] [bigint] NULL,
	[dateCreated] [bigint] NULL,
	[dateUpdated] [bigint] NULL,
	[dateDone] [bigint] NULL,
	[isArchived] [bit] NULL,
	[parentId] [nvarchar](15) NULL,
	[activeTo] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO
/****** Object:  Table [clickup].[User]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[User]') AND type in (N'U'))
BEGIN
CREATE TABLE [clickup].[User](
	[id] [bigint] NOT NULL,
	[name] [nvarchar](250) NULL,
	[email] [nvarchar](250) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [clickup].[StatusHistory]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[StatusHistory]') AND type in (N'U'))
BEGIN
CREATE TABLE [clickup].[StatusHistory](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[taskId] [nvarchar](50) NOT NULL,
	[status] [nvarchar](50) NOT NULL,
	[type] [nvarchar](50) NULL,
	[dateCreated] [bigint] NOT NULL,
	[durationInMinutes] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [clickup].[CustomField]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[CustomField]') AND type in (N'U'))
BEGIN
CREATE TABLE [clickup].[CustomField](
	[id] [uniqueidentifier] NOT NULL,
	[name] [nvarchar](50) NOT NULL,
	[value] [nvarchar](max) NULL,
	[taskId] [nvarchar](25) NOT NULL,
	[type] [nvarchar](200) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO
/****** Object:  Table [clickup].[Assignee]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[Assignee]') AND type in (N'U'))
BEGIN
CREATE TABLE [clickup].[Assignee](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[taskId] [nvarchar](15) NOT NULL,
	[userId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [clickup].[TaskStatus]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[TaskStatus]') AND type in (N'U'))
BEGIN
CREATE TABLE [clickup].[TaskStatus](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[statusName] [nvarchar](255) NULL,
	[friendlyName] [nvarchar](255) NULL,
	[description] [nvarchar](255) NULL,
	[category] [nvarchar](255) NULL,
	[groupName] [nvarchar](255) NULL,
	[orderNo] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  View [clickup].[vPeople]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[clickup].[vPeople]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [clickup].[vPeople]
AS

  SELECT t.id, 
	t.name,
	cf_email.email as [email],
	cf_contacttitle.contacttitle AS [title],
	ISNULL(comp.name,cf_company.company) AS company,
	cf_leadsource.leadsource AS leadSource,
	cf_value.value AS taskValue,
	[Utilities].[EpochToDate](t.DateCreated) AS CreatedDate,
	CASE WHEN DATEDIFF(DAY,[Utilities].[EpochToDate](t.DateCreated),GETDATE()) < 7 THEN ''Less than 07 days''
		 WHEN DATEDIFF(DAY,[Utilities].[EpochToDate](t.DateCreated),GETDATE()) < 14 THEN ''Less than 14 days''
		 WHEN DATEDIFF(DAY,[Utilities].[EpochToDate](t.DateCreated),GETDATE()) < 28 THEN ''Less than 28 days''
		 WHEN DATEDIFF(DAY,[Utilities].[EpochToDate](t.DateCreated),GETDATE()) < 56 THEN ''Less than 56 days''
		 WHEN DATEDIFF(DAY,[Utilities].[EpochToDate](t.DateCreated),GETDATE()) < 84 THEN ''Less than 84 days''
		 ELSE ''More than 86 days''
		  END AS TimeSinceCreated,
	CASE WHEN t.DueDate IS NULL THEN NULL ELSE [Utilities].[EpochToDate](t.dueDate) END AS DueDate,
	CASE WHEN [Utilities].[EpochToDate](t.dueDate) < GETDATE() THEN ''Yes'' ELSE ''No'' END AS Overdue,
	ISNULL(ts.friendlyName,t.status) AS status,
	DATEDIFF(DAY,ISNULL(his.movedToStatus,[Utilities].[EpochToDate](t.DateCreated)),GETDATE()) AS timeInStatus,
	ts.description AS statusDescription,
	ts.category,
	ts.groupName,
	orderNo,
	u.name AS assignee,
	CASE WHEN cf_value.value IS NULL THEN ''{Missing Value}'' ELSE '''' END +
	CASE WHEN t.dueDate IS NULL AND ISNULL(ts.friendlyName,t.status) <> ''Active Customer'' THEN ''{Missing Due Date}'' ELSE '''' END +
	CASE WHEN cf_leadsource.leadsource IS NULL THEN ''{Missing Lead Source}'' ELSE '''' END +
	CASE WHEN cf_contacttitle.contacttitle IS NULL THEN ''{Missing Title}'' ELSE '''' END +
	CASE WHEN u.name IS NULL THEN ''{Missing Assignee}'' ELSE '''' END AS Exceptions,

	CASE WHEN cf_value.value IS NULL THEN 1 ELSE 0 END +
	CASE WHEN t.dueDate IS NULL AND ISNULL(ts.friendlyName,t.status) <> ''Active Customer'' THEN 1 ELSE 0 END +
	CASE WHEN cf_leadsource.leadsource IS NULL THEN 1 ELSE 0 END +
	CASE WHEN cf_contacttitle.contacttitle IS NULL THEN 1 ELSE 0 END +
	CASE WHEN u.name IS NULL THEN 1 ELSE 0 END AS ExceptionCount
    FROM clickup.Task t 
  LEFT JOIN clickup.TaskStatus ts ON t.status = ts.statusName
  LEFT JOIN (SELECT taskId,status, MAX(utilities.EpochToDate(dateCreated)) AS movedToStatus FROM clickup.StatusHistory GROUP BY taskId,status) his ON his.taskid = t.id AND his.[status] = t.[status]
  LEFT JOIN clickup.assignee a ON a.taskId = t.id
  LEFT JOIN clickup.[user] u ON u.id = a.userid
  LEFT JOIN clickup.personcompany pc ON pc.persontaskid = t.id
  LEFT JOIN clickup.task comp ON comp.id = pc.companytaskid
  OUTER APPLY (
	SELECT [value] as [email]
		FROM [clickup].[CustomField] cf 
	WHERE cf.[taskId] = t.[id] AND cf.[name] = ''Email''
) as cf_email(email)
  OUTER APPLY (
	SELECT [value] as [company]
		FROM [clickup].[CustomField] cf 
	WHERE cf.[taskId] = t.[id] AND cf.[name] = ''Company Name''
) as cf_company(company)
  OUTER APPLY (
	SELECT [value] as [value]
		FROM [clickup].[CustomField] cf 
	WHERE cf.[taskId] = t.[id] AND cf.[name] = ''Current Task Value''
) as cf_value(value)
  OUTER APPLY (
	SELECT [value] as [leadsource]
		FROM [clickup].[CustomField] cf 
	WHERE cf.[taskId] = t.[id] AND cf.[name] = ''Lead Source''
) as cf_leadsource(leadsource)
  OUTER APPLY (
	SELECT [value] as [contacttitle]
		FROM [clickup].[CustomField] cf 
	WHERE cf.[taskId] = t.[id] AND cf.[name] = ''Contact Title''
) as cf_contacttitle(contacttitle) 

  WHERE t.listid = 901201812211
    AND t.parentId IS NULL
	AND (t.activeTo IS NULL OR [utilities].[EpochToDate](t.activeTo) >= GETDATE())
' 
GO
/****** Object:  Table [clickup].[CompanyCertification]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[CompanyCertification]') AND type in (N'U'))
BEGIN
CREATE TABLE [clickup].[CompanyCertification](
	[companyTaskId] [nvarchar](25) NOT NULL,
	[certificationTaskId] [nvarchar](25) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[companyTaskId] ASC,
	[certificationTaskId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  View [clickup].[vCompany]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[clickup].[vCompany]'))
EXEC dbo.sp_executesql @statement = N'

CREATE VIEW [clickup].[vCompany] AS 
SELECT t.id
			,t.name
			,t.description
			,t.status
			--,pc.personTaskId 
			,cc.certificationTaskId
FROM [clickup].[Task] t 
--LEFT JOIN [clickup].[PersonCompany] pc on pc.companyTaskId = t.id
LEFT JOIN [clickup].[CompanyCertification] cc on cc.companyTaskId = t.id
WHERE t.listId = ''901201812237'' AND t.parentId is NULL AND (t.activeTo > [Utilities].[DateToEpoch](GetDate()) OR t.activeTo is NULL);
' 
GO
/****** Object:  View [DataModel].[vEventSubmissions]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[DataModel].[vEventSubmissions]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [DataModel].[vEventSubmissions] AS 
SELECT ev.id as [eventId]
			,ev.reference as [eventReference]
			--,ev.title as [eventTitle]
			--,ev.startDateTime
			--,ev.endDateTime
			--,ev.noOfAttendees as attendees
			,f.id as [formId]
			,f.name as [formName]
			,fc.name as [formCategory]
			,ec.id as [categoryId]
			,ec.name as [categoryName]
			,ea.id as [emissionActivityId]
			,ea.name as [emissionActivityName]
			,e.submissionId
			,e.[month]
			,e.userInput
			,e.conversionFactor
			,e.dataUnit
			,(SELECT [value] FROM Forms.Response r WHERE r.submissionId = e.submissionId AND r.questionId = 128) as [userName]
			,(SELECT [value] FROM Forms.Response r WHERE r.submissionId = e.submissionId AND r.questionId = 129) as [userEmail]
	FROM Fact.Emission e
INNER JOIN Dimension.Submission s on s.id = e.submissionId
INNER JOIN Dimension.Event ev on ev.id = e.entityId AND e.entityTypeId = 2
INNER JOIN Dimension.Form f on f.id = s.formId
INNER JOIN Emissions.EmissionActivity ea on ea.id = e.emissionActivityId
LEFT JOIN Lookups.FormCategory fc on fc.id = f.categoryId
LEFT JOIN Emissions.EmissionCategory ec on ec.id = ea.parentId' 
GO
/****** Object:  View [DataModel].[vEvents]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[DataModel].[vEvents]'))
EXEC dbo.sp_executesql @statement = N'  CREATE VIEW [DataModel].[vEvents]
  AS
  SELECT [id]
      ,[title]
      ,[reference]
      ,[type]
      ,[organiserName]
      ,[organiserEmail]
      ,[companyName]
      ,[location]
      ,[locationType]
      ,[startDateTime]
      ,[endDateTime]
      ,[noOfAttendees]
      ,[active]
  FROM [Dimension].[Event]' 
GO
/****** Object:  View [Emissions].[vEmissionFactors]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[Emissions].[vEmissionFactors]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [Emissions].[vEmissionFactors] AS 
SELECT a.id as [activityId], a.name as [activityName], ef.ef, ef.wtt, ef.tnd, ef.tndWtt, ef.emissionProfileId
FROM Emissions.EmissionActivity a
LEFT JOIN Emissions.EmissionFactor ef on ef.activityId = a.id' 
GO
/****** Object:  Table [Forms].[QuestionEmissionActivity]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Forms].[QuestionEmissionActivity]') AND type in (N'U'))
BEGIN
CREATE TABLE [Forms].[QuestionEmissionActivity](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[questionId] [int] NOT NULL,
	[emissionActivityId] [int] NULL,
	[rowNo] [int] NULL,
	[columnNo] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [Lookups].[QuestionType]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Lookups].[QuestionType]') AND type in (N'U'))
BEGIN
CREATE TABLE [Lookups].[QuestionType](
	[id] [int] NOT NULL,
	[name] [nvarchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [Forms].[Question]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Forms].[Question]') AND type in (N'U'))
BEGIN
CREATE TABLE [Forms].[Question](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[reference] [nvarchar](100) NOT NULL,
	[displayText] [nvarchar](1000) NULL,
	[questionTypeId] [int] NULL,
	[inputTypeId] [int] NULL,
	[formId] [int] NOT NULL,
	[dataType] [nvarchar](25) NULL,
	[properties] [nvarchar](max) NULL,
	[active] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO
/****** Object:  View [Forms].[vFormQuestions]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[Forms].[vFormQuestions]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [Forms].[vFormQuestions] AS 
SELECT f.id as formId
			,f.name as formName
			,qp.questionId
			,q.reference
			,q.displayText
			,q.questionTypeId
			,qt.name as questionType
			,ea.id as emissionActivityId
			,ea.name as emiissionActivity
			,qp.rowNo
			,qp.columnNo
FROM Forms.QuestionEmissionActivity qp
INNER JOIN Forms.Question q on q.id = qp.questionId
INNER JOIN Emissions.EmissionActivity ea on ea.id = qp.emissionActivityId
INNER JOIN Dimension.Form f on f.id = q.formId
LEFT JOIN Lookups.QuestionType qt on qt.id = q.questionTypeId' 
GO
/****** Object:  View [clickup].[vTasks]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[clickup].[vTasks]'))
EXEC dbo.sp_executesql @statement = N'



CREATE VIEW [clickup].[vTasks] AS 
/*
SELECT t.id
			,t.name
			,t.description
			,t.status
			,creator.name as [createdBy]
			,Utilities.EpochToDate(t.dueDate) as [dueDate]
			,Utilities.EpochToDate(t.dateCreated) as [dateCreated]
			,Utilities.EpochToDate(t.dateUpdated) as [dateUpdated]
			,subtasks.entries as [subTasks]
			,statusHistory.entries as [statusHistory]
FROM clickup.Task t 

OUTER APPLY (
	SELECT u.name, u.email FROM clickup.[User] u WHERE u.id = t.createdBy
) creator(name, email)

OUTER APPLY ( 
	SELECT st.id
				,st.name
				--,st.description
				,st.status 
	FROM clickup.Task st 
	WHERE st.parentId = t.id FOR JSON AUTO
) subtasks(entries)

OUTER APPLY ( 
	SELECT sh.status
				,sh.type
				,Utilities.EpochToDate(sh.dateCreated) as [dateCreated]
		FROM clickup.StatusHistory sh 
	 WHERE sh.taskId = t.id FOR JSON AUTO
) statusHistory(entries)

WHERE t.parentId is NULL
*/

SELECT t.id
			,t.name
			,t.description
			,t.status
			,u.name as [createdBy]
			,Utilities.EpochToDate(t.dueDate) as [dueDate]
			,Utilities.EpochToDate(t.dateCreated) as [dateCreated]
			,Utilities.EpochToDate(t.dateUpdated) as [dateUpdated]
			,st.name AS [subTaskName]
			,st.status AS [subTaskStatus]
			,CASE WHEN st.status = ''subtask Complete'' THEN 1 ELSE 0 END AS [subTaskComplete]
			,CASE WHEN st.status = ''subtask Complete'' THEN ''Yes'' ELSE ''No'' END AS [subTaskCompleteName]
			--,Utilities.EpochToDate(sh.dateCreated) AS [statusHistoryDate]
			--,sh.status AS [statusHistory]
			--,sh.type AS [statusHistoryType]
			,t.isArchived
FROM clickup.Task t 
LEFT JOIN clickup.[User] u ON u.id = t.createdBy
LEFT JOIN clickup.Task st ON st.parentId = t.id
--LEFT JOIN clickup.StatusHistory sh ON sh.taskId = t.id

WHERE t.parentId is NULL AND (t.activeTo > [Utilities].[DateToEpoch](GetDate()) OR t.activeTo is NULL);

' 
GO
/****** Object:  View [clickup].[vTaskHistory]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[clickup].[vTaskHistory]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [clickup].[vTaskHistory]
AS 

SELECT h.taskId, 
		[utilities].[EpochToDate](dateCreated) AS createdDate,
		s.statusName,
		h.durationInMinutes / 1440.0 AS statusDurationDays,
		s.friendlyname,
		s.category,
		s.groupName,
		s.orderNo
 FROM clickup.StatusHistory h 
 JOIN clickup.TaskStatus s ON h.status = s.statusname
 WHERE [utilities].[EpochToDate](dateCreated) >= ''2024-04-01''
 ' 
GO
/****** Object:  Table [Forms].[JotformRawResponse]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Forms].[JotformRawResponse]') AND type in (N'U'))
BEGIN
CREATE TABLE [Forms].[JotformRawResponse](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[formId] [nvarchar](25) NOT NULL,
	[submissionId] [nvarchar](25) NOT NULL,
	[data] [nvarchar](max) NOT NULL,
	[processFlag] [bit] NOT NULL,
	[createdDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO
/****** Object:  Table [Forms].[JotForm]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Forms].[JotForm]') AND type in (N'U'))
BEGIN
CREATE TABLE [Forms].[JotForm](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](100) NOT NULL,
	[description] [nvarchar](250) NULL,
	[category] [nvarchar](50) NULL,
	[formId] [nvarchar](25) NOT NULL,
	[active] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  View [Forms].[vFormRawResponse]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[Forms].[vFormRawResponse]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [Forms].[vFormRawResponse] AS 
SELECT f.name as [formName], r.formId, r.id, r.submissionId, r.processFlag, r.createdDate
FROM Forms.JotformRawResponse r
INNER JOIN Forms.JotForm f on f.formId = r.formId' 
GO
/****** Object:  Table [clickup].[Configuration]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[Configuration]') AND type in (N'U'))
BEGIN
CREATE TABLE [clickup].[Configuration](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](100) NOT NULL,
	[description] [nvarchar](250) NULL,
	[listId] [bigint] NOT NULL,
	[active] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [clickup].[Folder]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[Folder]') AND type in (N'U'))
BEGIN
CREATE TABLE [clickup].[Folder](
	[id] [bigint] NOT NULL,
	[name] [nvarchar](250) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [clickup].[List]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[List]') AND type in (N'U'))
BEGIN
CREATE TABLE [clickup].[List](
	[id] [bigint] NOT NULL,
	[name] [nvarchar](250) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [clickup].[Space]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[Space]') AND type in (N'U'))
BEGIN
CREATE TABLE [clickup].[Space](
	[id] [bigint] NOT NULL,
	[name] [nvarchar](250) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [Dimension].[Person]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Dimension].[Person]') AND type in (N'U'))
BEGIN
CREATE TABLE [Dimension].[Person](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[firstName] [nvarchar](50) NULL,
	[lastName] [nvarchar](50) NULL,
	[mobile] [nvarchar](12) NULL,
	[address] [nvarchar](1000) NULL,
	[active] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [Emissions].[EmissionProfile]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Emissions].[EmissionProfile]') AND type in (N'U'))
BEGIN
CREATE TABLE [Emissions].[EmissionProfile](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](100) NOT NULL,
	[description] [nvarchar](250) NULL,
	[active] [bit] NOT NULL,
	[year] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [Forms].[NczForm]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Forms].[NczForm]') AND type in (N'U'))
BEGIN
CREATE TABLE [Forms].[NczForm](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](100) NOT NULL,
	[description] [nvarchar](250) NULL,
	[category] [nvarchar](50) NULL,
	[active] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [Lookups].[DataSource]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Lookups].[DataSource]') AND type in (N'U'))
BEGIN
CREATE TABLE [Lookups].[DataSource](
	[id] [int] NOT NULL,
	[name] [nvarchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [Lookups].[EntityType]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Lookups].[EntityType]') AND type in (N'U'))
BEGIN
CREATE TABLE [Lookups].[EntityType](
	[id] [int] NOT NULL,
	[name] [nvarchar](50) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [Lookups].[QuestionInputType]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Lookups].[QuestionInputType]') AND type in (N'U'))
BEGIN
CREATE TABLE [Lookups].[QuestionInputType](
	[id] [int] NOT NULL,
	[name] [nvarchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[DF__Configura__activ__2C88998B]') AND type = 'D')
BEGIN
ALTER TABLE [clickup].[Configuration] ADD  DEFAULT ((1)) FOR [active]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Dimension].[DF__Customer__isActi__5FB337D6]') AND type = 'D')
BEGIN
ALTER TABLE [Dimension].[Customer] ADD  DEFAULT ((1)) FOR [active]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Dimension].[DF__CustomerP__activ__634EBE90]') AND type = 'D')
BEGIN
ALTER TABLE [Dimension].[CustomerProfile] ADD  DEFAULT ((1)) FOR [active]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Dimension].[DF__Event__active__308E3499]') AND type = 'D')
BEGIN
ALTER TABLE [Dimension].[Event] ADD  DEFAULT ((1)) FOR [active]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Dimension].[DF__Form__active__4D5F7D71]') AND type = 'D')
BEGIN
ALTER TABLE [Dimension].[Form] ADD  DEFAULT ((1)) FOR [active]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Dimension].[DF__Person__isActive__5EBF139D]') AND type = 'D')
BEGIN
ALTER TABLE [Dimension].[Person] ADD  DEFAULT ((1)) FOR [active]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Emissions].[DF__EmissionA__activ__02FC7413]') AND type = 'D')
BEGIN
ALTER TABLE [Emissions].[EmissionActivity] ADD  DEFAULT ((1)) FOR [active]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Emissions].[DF__EmissionC__activ__3A179ED3]') AND type = 'D')
BEGIN
ALTER TABLE [Emissions].[EmissionCategory] ADD  DEFAULT ((1)) FOR [active]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Emissions].[DF__EmissionF__activ__00200768]') AND type = 'D')
BEGIN
ALTER TABLE [Emissions].[EmissionFactor] ADD  DEFAULT ((1)) FOR [active]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Emissions].[DF__EmissionA__activ__05D8E0BE]') AND type = 'D')
BEGIN
ALTER TABLE [Emissions].[EmissionProfile] ADD  DEFAULT ((1)) FOR [active]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Fact].[DF__Emission__active__65F62111]') AND type = 'D')
BEGIN
ALTER TABLE [Fact].[Emission] ADD  DEFAULT ((1)) FOR [active]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Forms].[DF__JotForm__active__73BA3083]') AND type = 'D')
BEGIN
ALTER TABLE [Forms].[JotForm] ADD  DEFAULT ((1)) FOR [active]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Forms].[DF__JotformRa__proce__0E6E26BF]') AND type = 'D')
BEGIN
ALTER TABLE [Forms].[JotformRawResponse] ADD  DEFAULT ((0)) FOR [processFlag]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Forms].[DF__JotformRa__creat__19AACF41]') AND type = 'D')
BEGIN
ALTER TABLE [Forms].[JotformRawResponse] ADD  DEFAULT (getdate()) FOR [createdDate]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Forms].[DF__JotformSu__creat__1A9EF37A]') AND type = 'D')
BEGIN
ALTER TABLE [Forms].[JotformSubmission] ADD  DEFAULT (getdate()) FOR [submissionDate]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Forms].[DF__JotformSu__creat__52E34C9D]') AND type = 'D')
BEGIN
ALTER TABLE [Forms].[JotformSubmission] ADD  DEFAULT (getdate()) FOR [createdDate]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Forms].[DF__NczForm__active__6FE99F9F]') AND type = 'D')
BEGIN
ALTER TABLE [Forms].[NczForm] ADD  DEFAULT ((1)) FOR [active]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Forms].[DF__Question__active__3A4CA8FD]') AND type = 'D')
BEGIN
ALTER TABLE [Forms].[Question] ADD  DEFAULT ((1)) FOR [active]
END
GO
/****** Object:  StoredProcedure [clickup].[spClickup_AddAssignees]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[spClickup_AddAssignees]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [clickup].[spClickup_AddAssignees] AS' 
END
GO

ALTER PROCEDURE [clickup].[spClickup_AddAssignees]
	@taskId nvarchar(25)
	,@assignees_JSON nvarchar(max)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @assignees TABLE(
		[id] bigint,
		[name] nvarchar(100),
		[email] nvarchar(100)
	)
	INSERT INTO @assignees ([id], [name], [email])
	SELECT ln.[id], ln.[name], ln.[email]
	  FROM OPENJSON(@assignees_JSON) A
	CROSS APPLY OPENJSON(A.value) 
	WITH
	(
		[id] bigint,
		[name] nvarchar(100),
		[email] nvarchar(100)
	) ln;

	MERGE [clickup].[Assignee] ca
		USING @assignees a
	ON (ca.[taskId] = @taskId and a.[id] = ca.[userId])
	--WHEN MATCHED
		-- THEN do nothing
	WHEN NOT MATCHED BY TARGET
		THEN INSERT ([taskId], [userId])
			 VALUES (@taskId, a.[id])
	WHEN NOT MATCHED BY SOURCE AND ca.taskId = @taskId
		THEN DELETE
	;

	Return 1;
END
GO
/****** Object:  StoredProcedure [clickup].[spClickup_AddCompanyCertifications]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[spClickup_AddCompanyCertifications]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [clickup].[spClickup_AddCompanyCertifications] AS' 
END
GO

ALTER PROCEDURE [clickup].[spClickup_AddCompanyCertifications]
	@task_companycertifications_json NVARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @task_companycertificationsTable TABLE(
		[companyTaskId] nvarchar(36),
		[certificationTaskId] nvarchar(36)
	)
	INSERT INTO @task_companycertificationsTable ([companyTaskId], [certificationTaskId])
	SELECT ln.[taskId], ln.[parentId]
	FROM OPENJSON(@task_companycertifications_json) A
	CROSS APPLY OPENJSON(A.value) 
	WITH
	(
		[taskId] nvarchar(36),
		[parentId] nvarchar(36)
	) ln;

	MERGE INTO [clickup].[CompanyCertification] AS target
    USING @task_companycertificationsTable AS source
    ON target.companyTaskId = source.[companyTaskId] AND target.certificationTaskId = source.[certificationTaskId]
    WHEN NOT MATCHED THEN
        INSERT (companyTaskId, certificationTaskId) VALUES (source.[companyTaskId], source.[certificationTaskId]);

	Return 1;
END
GO
/****** Object:  StoredProcedure [clickup].[spClickup_AddCustomFields]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[spClickup_AddCustomFields]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [clickup].[spClickup_AddCustomFields] AS' 
END
GO

ALTER PROCEDURE [clickup].[spClickup_AddCustomFields]
	@taskId nvarchar(25)
	,@customFields_JSON nvarchar(max)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @customFields TABLE(
		[id] uniqueidentifier,
		[name] nvarchar(50),
		[value] nvarchar(max),
		[type] nvarchar(250)
	)
	INSERT INTO @customFields ([id], [name], [value],[type])
		SELECT [id] = B.id,
		   [name] = B.name,
		   [value] = B.[value],
		   [type] = B.type
		FROM OPENJSON(@customFields_JSON) A
		CROSS APPLY (
			SELECT [id] = JSON_VALUE(A.value, '$.id'),
				   [name] = COALESCE(JSON_VALUE(A.value, '$.name'), ''),
				   [value] = CASE
								WHEN ISJSON(JSON_QUERY(A.value, '$.value')) = 1 THEN JSON_QUERY(A.value, '$.value')
								ELSE JSON_VALUE(A.value, '$.value')
							END,
				   [type] = JSON_VALUE(A.value, '$.type')
		) B;

	MERGE [clickup].[CustomField] cc
		USING @customFields c
	ON (cc.[taskId] = @taskId and c.[id] = cc.[id])
	WHEN MATCHED
		THEN UPDATE
			SET cc.[name] = c.[name],
				cc.[value] = c.[value],
				cc.[type] = c.[type]
	WHEN NOT MATCHED BY TARGET
		THEN INSERT ([id], [taskId], [name], [value], [type])
			 VALUES (c.[id], @taskId, c.[name], c.[value], c.[type])
	WHEN NOT MATCHED BY SOURCE AND cc.taskId = @taskId
		THEN DELETE
	;

	Return 1;
END

GO
/****** Object:  StoredProcedure [clickup].[spClickup_AddPersonCompany]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[spClickup_AddPersonCompany]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [clickup].[spClickup_AddPersonCompany] AS' 
END
GO

ALTER PROCEDURE [clickup].[spClickup_AddPersonCompany]
	@task_personcompany_json NVARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON;
	
	
	DECLARE @task_personcompanyTable TABLE(
		[personTaskId] nvarchar(36),
		[companyTaskId] nvarchar(36)
	)
	INSERT INTO @task_personcompanyTable ([personTaskId], [companyTaskId])
	SELECT ln.[taskId], ln.[parentId]
	FROM OPENJSON(@task_personcompany_json) A
	CROSS APPLY OPENJSON(A.value) 
	WITH
	(
		[taskId] nvarchar(36),
		[parentId] nvarchar(36)
	) ln;

	MERGE INTO [clickup].[PersonCompany] AS target
    USING @task_personcompanyTable AS source
    ON target.personTaskId = source.personTaskId AND target.companyTaskId = source.companyTaskId
    WHEN NOT MATCHED THEN
        INSERT (personTaskId, companyTaskId) VALUES (source.personTaskId, source.companyTaskId);

	Return 1;
END




GO
/****** Object:  StoredProcedure [clickup].[spClickup_AddStatusHistory]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[spClickup_AddStatusHistory]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [clickup].[spClickup_AddStatusHistory] AS' 
END
GO

ALTER PROCEDURE [clickup].[spClickup_AddStatusHistory]
	@taskId nvarchar(25)
	,@status_JSON nvarchar(max)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @status TABLE(
		[status] nvarchar(100),
		[type] nvarchar(100),
		[durationInMinutes] int,
		[dateCreated] bigint
	)
	INSERT INTO @status ([status], [type], [durationInMinutes] ,[dateCreated])
	SELECT ln.[status], ln.[type] , ln.[durationInMinutes] , ln.[dateCreated]
	  FROM OPENJSON(@status_JSON) A
	CROSS APPLY OPENJSON(A.value) 
	WITH
	(
		[status] nvarchar(100),
		[type] nvarchar(100),
		[durationInMinutes] int,
		[dateCreated] bigint
	) ln;

	MERGE [clickup].[statusHistory] cs
		USING @status s
	ON (cs.[taskId] = @taskId and s.[status] = cs.[status] and s.[dateCreated] = cs.[dateCreated])
	--WHEN MATCHED
		-- THEN do nothing
	WHEN NOT MATCHED BY TARGET
		THEN INSERT ([taskId], [status], [type], [dateCreated] ,[durationInMinutes])
			 VALUES (@taskId, s.[status], s.[type], s.[dateCreated], s.[durationInMinutes])
	--WHEN NOT MATCHED BY SOURCE AND cs.taskId = @taskId
		--THEN do nothing
	;

	Return 1;
END

GO
/****** Object:  StoredProcedure [clickup].[spClickup_AddTasks]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[spClickup_AddTasks]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [clickup].[spClickup_AddTasks] AS' 
END
GO

ALTER PROCEDURE [clickup].[spClickup_AddTasks]
	@tasks_JSON nvarchar(max)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @lastProcessedOn bigint =  [Utilities].[DateToEpoch](GetDate());

	DECLARE @tasks TABLE(
		[id] nvarchar(15), 
		[name] nvarchar(250),
		[description] nvarchar(MAX), 
		[parentId] nvarchar(15),
		[folderId] bigint,
		[listId]bigint,
		[spaceId] bigint,
		[status] nvarchar(50),
		[createdBy] int,
		[startDate] bigint,
		[dueDate] bigint,
		[dateCreated] bigint,
		[dateUpdated] bigint,
		[dateDone] bigint,
		[isArchived] bit,
		[status_JSON] nvarchar(max),
		[creator_JSON] nvarchar(max),
		[assignees_JSON] nvarchar(max),
		[customFields_JSON] nvarchar(max)
	)
	INSERT INTO @tasks ([id], [name], [description], [parentId], [folderId], [listId], [spaceId], [status], [createdBy], [startDate], [dueDate], [dateCreated], 
											[dateUpdated], [dateDone], [isArchived], [status_JSON], [creator_JSON], [assignees_JSON], [customFields_JSON])
	SELECT ln.[id], ln.[name], ln.[description], ln.[parentId], ln.[folderId], ln.[listId], ln.[spaceId], ln.[status], ln.[createdBy], ln.[startDate], ln.[dueDate],
					ln.[dateCreated], ln.[dateUpdated], ln.[dateDone], ln.[isArchived], ln.[status_JSON], ln.[creator_JSON], ln.[assignees_JSON], ln.[customFields_JSON]
	  FROM OPENJSON(@tasks_JSON) A
	CROSS APPLY OPENJSON(A.value) 
	WITH
	(
		[id] nvarchar(15), 
		[name] nvarchar(250),
		[description] nvarchar(MAX), 
		[parentId] nvarchar(15),
		[folderId] bigint,
		[listId]bigint,
		[spaceId] bigint,
		[status] nvarchar(50),
		[createdBy] int,
		[startDate] bigint,
		[dueDate] bigint,
		[dateCreated] bigint,
		[dateUpdated] bigint,
		[dateDone] bigint,
		[isArchived] bit,
		[status_JSON] nvarchar(max),
		[creator_JSON] nvarchar(max),
		[assignees_JSON] nvarchar(max),
		[customFields_JSON] nvarchar(max)
	) ln;

	MERGE [clickup].[Task] ct
		USING @tasks t
	ON (t.[id] = ct.[id])
	WHEN MATCHED
		THEN UPDATE
				SET ct.[name] = t.[name]
					,ct.[description] = t.[description]
					,ct.[status] = t.[status]
					,ct.[startDate] = t.[startDate]
					,ct.[dueDate] = t.[dueDate]
					,ct.[dateCreated] = t.[dateCreated]
					,ct.[dateUpdated] = t.[dateUpdated]
					,ct.[dateDone] = t.[dateDone]
					,ct.[isArchived] = t.[isArchived]
					,ct.[parentId] = t.[parentId]
					,ct.[folderId] = t.[folderId]
					,ct.[listId] = t.[listId]
					,ct.[spaceId] = t.[spaceId]
					,ct.[activeTo] = null
	WHEN NOT MATCHED BY TARGET
		THEN INSERT ([id], [name], [description], [parentId], [folderId], [listId], [spaceId], [status], [createdBy], [startDate], [dueDate], [dateCreated], [dateUpdated], [dateDone], [isArchived] , [activeTo])
			 VALUES (t.[id], t.[name], t.[description], t.[parentId], t.[folderId], t.[listId], t.[spaceId], t.[status], t.[createdBy], t.[startDate], t.[dueDate], t.[dateCreated], t.[dateUpdated], t.[dateDone], t.[isArchived] , null)
	--WHEN NOT MATCHED BY SOURCE 
	--THEN Update SET t.[active] = 0 where [ct].[id] = t.[id]
	;

	-- For each tasks, add assignees and custom fields
	DECLARE @taskId nvarchar(50)
	DECLARE @assignees_JSON nvarchar(max)
	DECLARE @creator_JSON nvarchar(max)
	DECLARE @status_JSON nvarchar(max)
	DECLARE @customFields_JSON nvarchar(max)
	DECLARE cur CURSOR for
		SELECT [id], [assignees_JSON], [creator_JSON], [status_JSON], [customFields_JSON] FROM @tasks
	OPEN cur
	FETCH NEXT FROM cur INTO @taskId, @assignees_JSON, @creator_JSON, @status_JSON, @customFields_JSON
	WHILE @@FETCH_STATUS = 0 BEGIN
				EXEC [clickup].[spClickup_AddAssignees] @taskId, @assignees_JSON
				EXEC [clickup].[spClickup_AddUsers] @assignees_JSON
				EXEC [clickup].[spClickup_AddUsers] @creator_JSON
			--	EXEC [clickup].[spClickup_AddStatusHistory] @taskId, @status_JSON
				EXEC [clickup].[spClickup_AddCustomFields] @taskId, @customFields_JSON
			FETCH NEXT FROM cur INTO @taskId, @assignees_JSON, @creator_JSON, @status_JSON, @customFields_JSON
	END
	CLOSE cur
	DEALLOCATE cur

	Return 1;
END

GO
/****** Object:  StoredProcedure [clickup].[spClickup_AddUsers]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[spClickup_AddUsers]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [clickup].[spClickup_AddUsers] AS' 
END
GO

ALTER PROCEDURE [clickup].[spClickup_AddUsers]
	@users_JSON nvarchar(max)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @users TABLE(
		[id] bigint,
		[username] nvarchar(100),
		[email] nvarchar(100)
	)
	INSERT INTO @users ([id], [username], [email])
	SELECT ln.[id], ln.[username], ln.[email]
	  FROM OPENJSON(@users_JSON) A
	CROSS APPLY OPENJSON(A.value) 
	WITH
	(
		[id] bigint,
		[username] nvarchar(100),
		[email] nvarchar(100)
	) ln;

	MERGE [clickup].[User] cu
		USING @users u
	ON (u.[id] = cu.[id])
	WHEN MATCHED
		THEN UPDATE
			SET cu.[name] = u.[username],
					cu.[email] = u.[email]
	WHEN NOT MATCHED BY TARGET
		THEN INSERT ([id], [name], [email])
			 VALUES (u.[id], u.[username], u.[email])
	--WHEN NOT MATCHED BY SOURCE
		-- THEN do nothing
	;

	Return 1;
END

GO
/****** Object:  StoredProcedure [clickup].[spClickup_DeleteTasks]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[spClickup_DeleteTasks]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [clickup].[spClickup_DeleteTasks] AS' 
END
GO
ALTER PROCEDURE [clickup].[spClickup_DeleteTasks]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @activeTo bigint =  [Utilities].[DateToEpoch](DateAdd(MINUTE,30,GetDate()));
	
	Update [clickup].[Task] set activeTo = @activeTo where activeTo IS NULL;

END

GO
/****** Object:  StoredProcedure [clickup].[spClickup_GetAllParentTasks]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[spClickup_GetAllParentTasks]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [clickup].[spClickup_GetAllParentTasks] AS' 
END
GO
ALTER PROCEDURE [clickup].[spClickup_GetAllParentTasks]
AS
BEGIN
	 SELECT * FROM [clickup].[Task] WHERE parentId is null AND (activeTo > [Utilities].[DateToEpoch](GetDate()) OR activeTo is NULL);
END
GO
/****** Object:  StoredProcedure [clickup].[spClickup_GetCertificationTaskByPersonEmail]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[spClickup_GetCertificationTaskByPersonEmail]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [clickup].[spClickup_GetCertificationTaskByPersonEmail] AS' 
END
GO
ALTER PROCEDURE [clickup].[spClickup_GetCertificationTaskByPersonEmail]
	@email nvarchar(100)
AS
BEGIN

	SET NOCOUNT ON;
	
	DECLARE @certTaskId nvarchar(25), @companyName nvarchar(250)
	
	SELECT @certTaskId = [certificationTaskId], @companyName = [companyName]
		FROM [clickup].[vPeople] 
	 WHERE [email] = @email;
		
	IF @certTaskId IS NULL
		 SET @certTaskId = '8694174h3'; -- create subtask under default - Customer Certification Journey

	SELECT @certTaskId as [certificationTaskId], @companyName as [companyName], 'SUBTASK COMPLETE' as [status], '901200207978' as [listId] 

END
GO
/****** Object:  StoredProcedure [clickup].[spClickup_GetTasksWithDueDate]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[spClickup_GetTasksWithDueDate]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [clickup].[spClickup_GetTasksWithDueDate] AS' 
END
GO
ALTER PROCEDURE [clickup].[spClickup_GetTasksWithDueDate]
AS
BEGIN
	 SELECT id,[Utilities].EpochToDate(dueDate) dueDate 
		FROM [clickup].[Task] 
	 WHERE listId  = '901201812211' --People
		 AND dueDate is not null 
		 AND (activeTo > [Utilities].[DateToEpochTZ](GetDate()) OR activeTo is NULL)
		 AND (CAST([Utilities].EpochToDate(dueDate) as time) not between '10:00:00' AND '16:00:00'  
		 OR 
		 DATEPART(dw,[Utilities].EpochToDate(dueDate)) IN (1,7))
END

GO
/****** Object:  StoredProcedure [clickup].[spConfigration_Select]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[spConfigration_Select]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [clickup].[spConfigration_Select] AS' 
END
GO
ALTER PROCEDURE [clickup].[spConfigration_Select]
AS
BEGIN
	 SELECT *
    FROM [clickup].[Configuration] c
	 WHERE c.active = 1;
END

GO
/****** Object:  StoredProcedure [clickup].[spCustomField_SelectByTypeName]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[spCustomField_SelectByTypeName]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [clickup].[spCustomField_SelectByTypeName] AS' 
END
GO
ALTER PROCEDURE [clickup].[spCustomField_SelectByTypeName]
	@type nvarchar(50),
	@name nvarchar(50),
	@listId bigint
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN
			SELECT CF.* FROM [clickup].[CustomField] CF INNER JOIN [clickup].[Task] CT ON CT.[id] = CF.[taskId]
			 WHERE CF.[name] = @name AND CF.[type] = @type AND (CT.activeTo > [Utilities].[DateToEpoch](GetDate()) OR CT.activeTo is NULL)
			 AND CT.[listId] = @listId; 
	END
END
GO
/****** Object:  StoredProcedure [clickup].[spJotForm_PopulateCustomer]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[spJotForm_PopulateCustomer]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [clickup].[spJotForm_PopulateCustomer] AS' 
END
GO
ALTER PROCEDURE [clickup].[spJotForm_PopulateCustomer]
AS
BEGIN
    MERGE INTO [Dimension].[Customer] AS target
    USING (
        SELECT * from [clickup].[vCompany] where status = 'active'
    ) AS source
    ON (target.code = source.id) 
    WHEN NOT MATCHED THEN
        INSERT (name, code, description , active)
        VALUES (source.name, source.id, source.description ,1)
	WHEN NOT MATCHED BY SOURCE THEN
		UPDATE SET target.active = 0;
END;
GO
/****** Object:  StoredProcedure [DataModel].[Operations]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[DataModel].[Operations]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [DataModel].[Operations] AS' 
END
GO
ALTER PROC [DataModel].[Operations]
AS 
BEGIN 
SELECT  --t.id,
		t.spaceid,
		CASE t.listid WHEN 901200207978 THEN 'Certification Journey' WHEN 1 THEN 'Certification Complete' END AS listName,
		t.name, 
		t.status AS currentStatus, 
		u.name AS createdBy,
		CONVERT(DATE,[Utilities].[EpochToDate](dateCreated)) AS dateCreated,
		CONVERT(DATE,[Utilities].[EpochToDate](dateUpdated)) AS dateUpdated,
		CONVERT(DATE,[Utilities].[EpochToDate](dueDate)) AS dueDate,
		(SELECT COUNT(*) FROM clickup.Task x WHERE x.parentId = t.id AND status = 'subtask complete') AS dataFormsComplete,
		((SELECT COUNT(*) FROM clickup.Task x WHERE x.parentId = t.id AND status = 'subtask complete') / 13.0) AS percComplete,
		CASE WHEN ((SELECT COUNT(*) FROM clickup.Task x WHERE x.parentId = t.id AND status = 'subtask complete') / 13.0) = 0.0 THEN 'Not yet started' ELSE 'Started' END AS startStaus,
		CASE WHEN ((SELECT COUNT(*) FROM clickup.Task x WHERE x.parentId = t.id AND status = 'subtask complete') / 13.0) >= 1.0 THEN 'Complete'
			 WHEN ((SELECT COUNT(*) FROM clickup.Task x WHERE x.parentId = t.id AND status = 'subtask complete') / 13.0) = 0.0 THEN '0%'
			 WHEN ((SELECT COUNT(*) FROM clickup.Task x WHERE x.parentId = t.id AND status = 'subtask complete') / 13.0) < 0.5 THEN '1-50%'
			 WHEN ((SELECT COUNT(*) FROM clickup.Task x WHERE x.parentId = t.id AND status = 'subtask complete') / 13.0) < 0.75 THEN '51-75%'
			 ELSE '75%+'
			 END AS percCompleteName
FROM clickup.Task t
JOIN clickup.[User] u ON t.createdBy = u.id
WHERE spaceId = 90120081374
AND parentid IS NULL
AND t.id != '8694174h3'
--AND status != 'current certificate issued'
END
GO
/****** Object:  StoredProcedure [DataModel].[operations_completedforms]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[DataModel].[operations_completedforms]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [DataModel].[operations_completedforms] AS' 
END
GO
ALTER PROC [DataModel].[operations_completedforms]
AS
SELECT p.name AS customer,
		c.name AS form, 
		CONVERT(DATE,[Utilities].[EpochToDate](c.dateCreated)) AS completedDate,
		DATEADD(dd, 0 - (@@DATEFIRST + 5 + DATEPART(dw, CONVERT(DATE,[Utilities].[EpochToDate](c.dateCreated)))) % 7, CONVERT(DATE,[Utilities].[EpochToDate](c.dateCreated))) AS WeekCommencing
FROM clickup.Task c
JOIN clickup.Task p ON p.id = c.parentid
WHERE c.listid = 901200207978 --need correct list id 
AND c.parentId IS NOT NULL
AND CONVERT(DATE,[Utilities].[EpochToDate](c.dateCreated)) >= '2024-03-11'
GO
/****** Object:  StoredProcedure [DataModel].[spEmissions_SelectForCertifications]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[DataModel].[spEmissions_SelectForCertifications]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [DataModel].[spEmissions_SelectForCertifications] AS' 
END
GO
ALTER PROCEDURE [DataModel].[spEmissions_SelectForCertifications]
	 @customerReference nvarchar(50)
	,@emissionProfileId INT
	,@formId INT = NULL
AS
BEGIN

	SELECT e.* 
				,[Utilities].[CalculateEf](e.emissionActivityId, @emissionProfileId, e.userInput, e.conversionFactor) as [totalEf]
				,[Utilities].[CalculateWtt](e.emissionActivityId, @emissionProfileId, e.userInput, e.conversionFactor) as [totalWtt]
				--,[Utilities].[CalculateTnd](e.emissionActivityId, @emissionProfileId, e.userInput, e.conversionFactor) as [totalTnd]
				--,[Utilities].[CalculateTndWtt](e.emissionActivityId, @emissionProfileId, e.userInput, e.conversionFactor) as [totalTndWtt]
				--,[Utilities].[CalculateTotalEmission](e.emissionActivityId, @emissionProfileId, e.userInput, e.conversionFactor) as [totalEmission]
		FROM [DataModel].[vCertificationSubsmissions] e
	 WHERE [customerReference] = @customerReference
		AND ([formId] = @formId OR @formId IS NULL);
END
GO
/****** Object:  StoredProcedure [DataModel].[spEmissions_SelectForEvents]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[DataModel].[spEmissions_SelectForEvents]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [DataModel].[spEmissions_SelectForEvents] AS' 
END
GO
ALTER PROCEDURE [DataModel].[spEmissions_SelectForEvents]
	 @eventReference nvarchar(50)
	,@emissionProfileId INT
	,@formId INT = NULL
AS
BEGIN

	SELECT e.* 
				,[Utilities].[CalculateEf](e.emissionActivityId, @emissionProfileId, e.userInput, e.conversionFactor) as [totalEf]
				,[Utilities].[CalculateWtt](e.emissionActivityId, @emissionProfileId, e.userInput, e.conversionFactor) as [totalWtt]
				,[Utilities].[CalculateTnd](e.emissionActivityId, @emissionProfileId, e.userInput, e.conversionFactor) as [totalTnd]
				,[Utilities].[CalculateTndWtt](e.emissionActivityId, @emissionProfileId, e.userInput, e.conversionFactor) as [totalTndWtt]
				,[Utilities].[CalculateTotalEmission](e.emissionActivityId, @emissionProfileId, e.userInput, e.conversionFactor) as [totalEmission]
		FROM [DataModel].[vEventSubmissions] e
	 WHERE [eventReference] = @eventReference
		AND ([formId] = @formId OR @formId IS NULL);
END

GO
/****** Object:  StoredProcedure [Dimension].[spCustomer_SaveProfile]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Dimension].[spCustomer_SaveProfile]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Dimension].[spCustomer_SaveProfile] AS' 
END
GO
ALTER PROCEDURE [Dimension].[spCustomer_SaveProfile]
	 @reference nvarchar(50)
	,@name nvarchar(100)
	,@periodStart date
	,@periodEnd date
	,@headCount int
	,@annualRevenue decimal(10,2)
	,@industryType nvarchar(100)
	,@locations_JSON nvarchar(max) 
AS
BEGIN
	SET NOCOUNT ON;


	DECLARE @profileId int = (SELECT TOP 1 [id] FROM [Dimension].[CustomerProfile] WHERE [reference] = @reference AND active = 1)
	IF @profileId IS NULL 
	BEGIN
		INSERT INTO [Dimension].[CustomerProfile] (reference, name, periodStart, periodEnd, headCount, annualRevenue, industryType) 
			VALUES (@reference, @name, @periodStart, @periodEnd, @headCount, @annualRevenue, @industryType);
		SET @profileId = SCOPE_IDENTITY();
	END
	--ELSE 
	--BEGIN
		-- update?
	--END
	
	SELECT * FROM [Dimension].[CustomerProfile] WHERE [id] = @profileId;

	-- TODO: SAVE LOCATIONS HERE
	 
END

GO
/****** Object:  StoredProcedure [Dimension].[spCustomer_SelectByPersonEmail]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Dimension].[spCustomer_SelectByPersonEmail]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Dimension].[spCustomer_SelectByPersonEmail] AS' 
END
GO
ALTER PROCEDURE [Dimension].[spCustomer_SelectByPersonEmail]
	@email nvarchar(100)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @customerCode nvarchar(50) = (SELECT [companyTaskId] FROM [clickup].[vPeople] WHERE email = @email);
	IF @customerCode IS NOT NULL
	BEGIN
		SELECT TOP 1 [id] FROM [Dimension].[Customer] WHERE code = @customerCode 
	END
	
END
GO
/****** Object:  StoredProcedure [Dimension].[spEntity_Select]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Dimension].[spEntity_Select]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Dimension].[spEntity_Select] AS' 
END
GO
ALTER PROCEDURE [Dimension].[spEntity_Select]
	@entityName nvarchar(50)
	,@entityTypeId int
AS
BEGIN
	SET NOCOUNT ON;
	IF @entityTypeId = 1 --Customer Profile
	BEGIN
			SELECT * 
				FROM [Dimension].[CustomerProfile]
			 WHERE [reference] = @entityName AND active=1; 
	END
	ELSE IF @entityTypeId = 2 --Events
	BEGIN
			SELECT * 
				FROM [Dimension].[Event]
			 WHERE [reference] = @entityName AND active=1; 
	END
	ELSE IF @entityTypeId = 4 --Customers
	BEGIN
			SELECT * 
				FROM [Dimension].[Customer]
			 WHERE [code] = @entityName AND active=1; 
	END
END



GO
/****** Object:  StoredProcedure [Dimension].[spEvent_Save]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Dimension].[spEvent_Save]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Dimension].[spEvent_Save] AS' 
END
GO
ALTER PROCEDURE [Dimension].[spEvent_Save]
	 @title nvarchar(100)
	,@reference nvarchar(50)
	,@type nvarchar(50)
	,@organiserName nvarchar(100)
	,@organiserEmail nvarchar(100)
	,@companyName nvarchar(100)
	,@startDateTime datetime
	,@endDateTime datetime
	,@location nvarchar(250)
	,@locationType nvarchar(100)
	,@noOfAttendees int
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @eventId int = (SELECT TOP 1 [id] FROM [Dimension].[Event] WHERE [reference] = @reference AND active = 1)
	IF @eventId IS NULL 
	BEGIN
		INSERT INTO [Dimension].[Event] (title, reference, type, organiserName, organiserEmail, companyName, startDateTime, endDateTime, location, locationType, noOfAttendees) 
			VALUES (@title, @reference, @type, @organiserName, @organiserEmail, @companyName, @startDateTime, @endDateTime, @location, @locationType, @noOfAttendees);
		SET @eventId = SCOPE_IDENTITY();
	END

	SELECT * FROM [Dimension].[Event] WHERE [id] = @eventId;
	 
END


GO
/****** Object:  StoredProcedure [Fact].[spEmission_Save]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Fact].[spEmission_Save]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Fact].[spEmission_Save] AS' 
END
GO
ALTER PROCEDURE [Fact].[spEmission_Save]
	 @entityId INT
	,@entityTypeId INT
	,@submissionId INT
	,@emissionActivityId INT
	,@userInput DECIMAL(10,2)
	,@month int
	,@conversionFactor decimal(10,4)
	,@reportingFrequencyId int
	,@dataUnit nvarchar(25)
AS
BEGIN
	SET NOCOUNT ON;

	--DECLARE @emissionId int = (SELECT TOP 1 [id] FROM [Fact].[Emission] WHERE [entityId] = @entityId AND entityTypeId = @entityTypeId AND emissionActivityId = @emissionActivityId AND [month] = @month)
	--IF @emissionId IS NULL 
	--BEGIN
		INSERT INTO [Fact].[Emission] (entityId, entityTypeId, submissionId, emissionActivityId, userInput, month, conversionFactor, reportingFrequencyId, dataUnit) 
			VALUES (@entityId, @entityTypeId, @submissionId, @emissionActivityId, @userInput, @month, @conversionFactor, @reportingFrequencyId, @dataUnit); 
		--SET @emissionId = SCOPE_IDENTITY();
	--END
	--ELSE 
	--BEGIN
		-- update user input, month, conversionFactor etc?
	--END
	 
END



GO
/****** Object:  StoredProcedure [Forms].[spForm_SaveRawResponse]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Forms].[spForm_SaveRawResponse]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Forms].[spForm_SaveRawResponse] AS' 
END
GO
ALTER PROCEDURE [Forms].[spForm_SaveRawResponse]
	@formID nvarchar(25)
	,@submissionID nvarchar(25)
	,@data nvarchar(max)
	,@dataSourceId int = 1
AS
BEGIN
	SET NOCOUNT ON;
	IF @dataSourceId = 1 
	BEGIN
		INSERT INTO [Forms].[JotformRawResponse] (formId, SubmissionId, data) 
			VALUES (@formID, @submissionID, @data);
	END
END
GO
/****** Object:  StoredProcedure [Forms].[spForm_SaveResponseData]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Forms].[spForm_SaveResponseData]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Forms].[spForm_SaveResponseData] AS' 
END
GO
ALTER PROCEDURE [Forms].[spForm_SaveResponseData]
	@submissionId int,
	@responseData nvarchar(max),
	@dataSourceId int = 1
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @data TABLE([questionId] int, [value] nvarchar(max), [submissionId] int) 
	INSERT INTO @data ([questionId], [value], [submissionId])
	SELECT *, @submissionId FROM OPENJSON(@responseData) WITH ([questionId] int '$.questionId', [value] nvarchar(max) '$.value')

	MERGE [Forms].[Response] r
	USING @data d
	ON (d.[submissionId] = r.[submissionId] AND d.[questionId] = r.[questionId])
	WHEN MATCHED
		THEN UPDATE
			SET r.[value] = d.[value]
	WHEN NOT MATCHED BY TARGET
		THEN INSERT ([questionId], [value], [submissionId])
			 VALUES (d.[questionId], d.[value], d.[submissionId])
	WHEN NOT MATCHED BY SOURCE AND r.[submissionId] = @submissionId
		THEN DELETE
	;
END
GO
/****** Object:  StoredProcedure [Forms].[spForm_SaveSubmission]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Forms].[spForm_SaveSubmission]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Forms].[spForm_SaveSubmission] AS' 
END
GO
ALTER PROCEDURE [Forms].[spForm_SaveSubmission]
	 @extSubmissionId nvarchar(25)
	,@entityId INT
	,@entityTYpeId int
	,@formID int
	,@managementBasedDecision bit
	,@optedIn bit
	,@submissionDate bigint = null
	,@dataSourceId int = 1
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @sourceId int;
	IF @dataSourceId = 1
	BEGIN
		SET @sourceId = (SELECT TOP 1 [id] FROM [Forms].[JotformSubmission] WHERE [submissionId] = @extSubmissionId)
		IF @sourceId IS NULL 
		BEGIN
			DECLARE @sDate datetime = Utilities.EpochToDate(@submissionDate);
			INSERT INTO [Forms].[JotformSubmission] ([submissionId], [submissionDate], [managementBasedDecision], [optedIn]) VALUES (@extSubmissionId, @sDate, @managementBasedDecision, @optedIn);
			SET @sourceId = SCOPE_IDENTITY();
		END
	END

	-- Update Dimension.Submission TODO Create Refresh Proc for this.
	DECLARE @submissionId int = (SELECT TOP 1 [id] FROM [Dimension].[Submission] WHERE [sourceId] = @sourceId AND [dataSourceId] = @dataSourceId)
	IF @submissionId IS NULL 
	BEGIN
		INSERT INTO [Dimension].[Submission] (entityId, entityTypeId, formId, sourceId, dataSourceId) 
			VALUES (@entityId, @entityTYpeId, @formID, @sourceId, @dataSourceId);
		SET @submissionId = SCOPE_IDENTITY();
	END
	ELSE
	BEGIN
		-- Soft delete all old emission activities for current submission
		UPDATE [Fact].[Emission] SET [active]=0 WHERE [submissionId] = @submissionId;
	END
	
	SELECT * FROM [Dimension].[Submission] WHERE [id] = @submissionId;
	 
END
GO
/****** Object:  StoredProcedure [Forms].[spForm_SelectAll]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Forms].[spForm_SelectAll]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Forms].[spForm_SelectAll] AS' 
END
GO
ALTER PROCEDURE [Forms].[spForm_SelectAll]
	@extSourceId int = 1
AS
BEGIN
	SET NOCOUNT ON;
	IF @extSourceId = 1 --Jotform
	BEGIN
			SELECT * 
				FROM [Forms].[JotForm]
			 WHERE active=1; 
	END
END




GO
/****** Object:  StoredProcedure [Forms].[spForm_SelectByExternalId]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Forms].[spForm_SelectByExternalId]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Forms].[spForm_SelectByExternalId] AS' 
END
GO
ALTER PROCEDURE [Forms].[spForm_SelectByExternalId]
	@formId nvarchar(50)
	,@dataSourceId int = 1
AS
BEGIN
	SET NOCOUNT ON;
	IF @dataSourceId = 1 --Jotform
	BEGIN
			SELECT * 
				FROM [Forms].[JotForm]
			 WHERE [formId] = @formId AND active=1; 
	END
END



GO
/****** Object:  StoredProcedure [Forms].[spForm_SelectQuestions]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Forms].[spForm_SelectQuestions]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Forms].[spForm_SelectQuestions] AS' 
END
GO
ALTER PROCEDURE [Forms].[spForm_SelectQuestions]
	@formId int
AS
BEGIN
	SET NOCOUNT ON;

		SELECT q.*, emissions.entries as [emissionActivities]
			FROM [Forms].[Question] q
			OUTER APPLY (
				 SELECT emissionActivityId, rowNo, columnNo 
					FROM [Forms].[QuestionEmissionActivity] 
					WHERE [questionId] = q.[id] 
					FOR JSON PATH 
			) emissions(entries)
		WHERE formId = @formId AND active = 1;
END

GO
/****** Object:  StoredProcedure [Forms].[spFormResponse_MarkProcessed]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Forms].[spFormResponse_MarkProcessed]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Forms].[spFormResponse_MarkProcessed] AS' 
END
GO
ALTER PROCEDURE [Forms].[spFormResponse_MarkProcessed]
	@id int
AS
BEGIN
	SET NOCOUNT ON;
	UPDATE [Forms].[JotformRawResponse] 
		 SET [processFlag] = 1
	 WHERE [id] = @id;  
END
GO
/****** Object:  StoredProcedure [Forms].[spFormResponse_SelectToProcess]    Script Date: 4/11/2024 10:08:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Forms].[spFormResponse_SelectToProcess]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Forms].[spFormResponse_SelectToProcess] AS' 
END
GO
ALTER PROCEDURE [Forms].[spFormResponse_SelectToProcess]
	@max int = 50,
	@dataSourceId int = 1
AS
BEGIN
	SET NOCOUNT ON;
			SELECT TOP (@max)
						jr.id as [id]
						,f.id as [formId]
						,f.name as [formName]
						,f.[entityTypeId]
						,jr.[submissionId]
						,jr.[data]
				FROM [Forms].[JotformRawResponse] jr
	INNER JOIN [Forms].[JotForm] jf on jf.[formId] = jr.[formId]
	INNER JOIN [Dimension].[Form] f on f.[sourceId] = jf.[id] AND f.[dataSourceId] = @dataSourceId
			 WHERE jr.[processFlag] = 0 AND f.[active] = 1;  
END
GO
ALTER DATABASE [nczdev] SET  READ_WRITE 
GO





----------------------------------------------------------- DATA -------------------------------------------------

SET IDENTITY_INSERT [clickup].[Configuration] ON 
GO
INSERT [clickup].[Configuration] ([id], [name], [description], [listId], [active]) VALUES (1, N'Certifications', NULL, 901200207978, 1)
GO
INSERT [clickup].[Configuration] ([id], [name], [description], [listId], [active]) VALUES (2, N'People', NULL, 901201812211, 1)
GO
INSERT [clickup].[Configuration] ([id], [name], [description], [listId], [active]) VALUES (3, N'Companies', N'', 901201812237, 1)
GO
SET IDENTITY_INSERT [clickup].[Configuration] OFF
GO
SET IDENTITY_INSERT [clickup].[TaskStatus] ON 
GO
INSERT [clickup].[TaskStatus] ([id], [statusName], [friendlyName], [description], [category], [groupName], [orderNo]) VALUES (1, N'active customer', N'Active Customer', N'Contact who has purchased a product or service', N'Active', N'Sold', 80)
GO
INSERT [clickup].[TaskStatus] ([id], [statusName], [friendlyName], [description], [category], [groupName], [orderNo]) VALUES (2, N'cold prospect', N'Cold Prospect', N'A person who has either not responded or confirmed they are currently not interested in NCZ products or services', N'Cold', N'Cold', 200)
GO
INSERT [clickup].[TaskStatus] ([id], [statusName], [friendlyName], [description], [category], [groupName], [orderNo]) VALUES (3, N'complete', N'Complete', NULL, N'Complete', N'Closed', 220)
GO
INSERT [clickup].[TaskStatus] ([id], [statusName], [friendlyName], [description], [category], [groupName], [orderNo]) VALUES (4, N'contract sent 1', N'Contract Sent 1', NULL, N'Contract Sent', N'Warm', 70)
GO
INSERT [clickup].[TaskStatus] ([id], [statusName], [friendlyName], [description], [category], [groupName], [orderNo]) VALUES (5, N'contract sent 2', N'Contract Sent 2', NULL, N'Contract Sent', N'Warm', 71)
GO
INSERT [clickup].[TaskStatus] ([id], [statusName], [friendlyName], [description], [category], [groupName], [orderNo]) VALUES (6, N'contract sent 3', N'Contract Sent 3', NULL, N'Contract Sent', N'Warm', 72)
GO
INSERT [clickup].[TaskStatus] ([id], [statusName], [friendlyName], [description], [category], [groupName], [orderNo]) VALUES (7, N'contract sent 4', N'Contract Sent 4', NULL, N'Contract Sent', N'Warm', 73)
GO
INSERT [clickup].[TaskStatus] ([id], [statusName], [friendlyName], [description], [category], [groupName], [orderNo]) VALUES (8, N'customer accepted', N'Customer Accepted', N'Prospect has accepted the proposal and now requires contract to be issued', N'Accepted', N'Warm', 60)
GO
INSERT [clickup].[TaskStatus] ([id], [statusName], [friendlyName], [description], [category], [groupName], [orderNo]) VALUES (9, N'meeting completed', N'Meeting Completed', N'A meeting has taken place and an action sits with NCZ', N'Meeting', N'Warm', 31)
GO
INSERT [clickup].[TaskStatus] ([id], [statusName], [friendlyName], [description], [category], [groupName], [orderNo]) VALUES (10, N'meeting scheduled', N'Meeting Scheduled', N'A prospect has a meeting booked', N'Meeting', N'Warm', 30)
GO
INSERT [clickup].[TaskStatus] ([id], [statusName], [friendlyName], [description], [category], [groupName], [orderNo]) VALUES (11, N'new prospect', N'New Prospect', NULL, N'New', N'Open', 1)
GO
INSERT [clickup].[TaskStatus] ([id], [statusName], [friendlyName], [description], [category], [groupName], [orderNo]) VALUES (12, N'not ready 1', N'Not Ready 1', NULL, N'Not Ready', N'Cold', 50)
GO
INSERT [clickup].[TaskStatus] ([id], [statusName], [friendlyName], [description], [category], [groupName], [orderNo]) VALUES (13, N'not ready 2', N'Not Ready 2', NULL, N'Not Ready', N'Cold', 51)
GO
INSERT [clickup].[TaskStatus] ([id], [statusName], [friendlyName], [description], [category], [groupName], [orderNo]) VALUES (14, N'not ready 3', N'Not Ready 3', NULL, N'Not Ready', N'Cold', 52)
GO
INSERT [clickup].[TaskStatus] ([id], [statusName], [friendlyName], [description], [category], [groupName], [orderNo]) VALUES (15, N'proposal sent 1', N'Proposal Sent 1', NULL, N'Proposal Sent', N'Warm', 40)
GO
INSERT [clickup].[TaskStatus] ([id], [statusName], [friendlyName], [description], [category], [groupName], [orderNo]) VALUES (16, N'proposal sent 2', N'Proposal Sent 2', NULL, N'Proposal Sent', N'Warm', 41)
GO
INSERT [clickup].[TaskStatus] ([id], [statusName], [friendlyName], [description], [category], [groupName], [orderNo]) VALUES (17, N'proposal sent 3', N'Proposal Sent 3', NULL, N'Proposal Sent', N'Warm', 42)
GO
INSERT [clickup].[TaskStatus] ([id], [statusName], [friendlyName], [description], [category], [groupName], [orderNo]) VALUES (18, N'unqualified prospect 1', N'Unqualified Prospect 1', NULL, N'Unqualified', N'Open', 10)
GO
INSERT [clickup].[TaskStatus] ([id], [statusName], [friendlyName], [description], [category], [groupName], [orderNo]) VALUES (19, N'unqualified prospect 2', N'Unqualified Prospect 2', NULL, N'Unqualified', N'Open', 11)
GO
INSERT [clickup].[TaskStatus] ([id], [statusName], [friendlyName], [description], [category], [groupName], [orderNo]) VALUES (20, N'unqualified prospect 3', N'Unqualified Prospect 3', NULL, N'Unqualified', N'Open', 12)
GO
INSERT [clickup].[TaskStatus] ([id], [statusName], [friendlyName], [description], [category], [groupName], [orderNo]) VALUES (21, N'unqualified prospect 4', N'Unqualified Prospect 4', NULL, N'Unqualified', N'Open', 13)
GO
INSERT [clickup].[TaskStatus] ([id], [statusName], [friendlyName], [description], [category], [groupName], [orderNo]) VALUES (22, N'unqualified prospect 5', N'Unqualified Prospect 5', NULL, N'Unqualified', N'Open', 14)
GO
INSERT [clickup].[TaskStatus] ([id], [statusName], [friendlyName], [description], [category], [groupName], [orderNo]) VALUES (23, N'unqualified prospect 6', N'Unqualified Prospect 6', NULL, N'Unqualified', N'Open', 15)
GO
INSERT [clickup].[TaskStatus] ([id], [statusName], [friendlyName], [description], [category], [groupName], [orderNo]) VALUES (24, N'unqualified prospect 7', N'Unqualified Prospect 7', NULL, N'Unqualified', N'Open', 16)
GO
INSERT [clickup].[TaskStatus] ([id], [statusName], [friendlyName], [description], [category], [groupName], [orderNo]) VALUES (25, N'unqualified prospect 8', N'Unqualified Prospect 8', NULL, N'Unqualified', N'Open', 17)
GO
INSERT [clickup].[TaskStatus] ([id], [statusName], [friendlyName], [description], [category], [groupName], [orderNo]) VALUES (26, N'unsubscribed', N'Unsubscribed', N'Prospect who has unsubscribed from communications', N'Unsubscribed', N'Cold', 210)
GO
SET IDENTITY_INSERT [clickup].[TaskStatus] OFF
GO
SET IDENTITY_INSERT [Emissions].[EmissionActivity] ON 
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (1, NULL, N'Water', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (2, NULL, N'Electricity', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (3, NULL, N'Natural Gas', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (4, NULL, N'Carbon dioxide', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (5, NULL, N'Methane', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (6, NULL, N'Nitrous oxide', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (7, NULL, N'HFC-23', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (8, NULL, N'HFC-32', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (9, NULL, N'HFC-41', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (10, NULL, N'HFC-125', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (11, NULL, N'HFC-134', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (12, NULL, N'HFC-134a', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (13, NULL, N'HFC-143', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (14, NULL, N'HFC-143a', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (15, NULL, N'HFC-152a', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (16, NULL, N'HFC-227ea', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (17, NULL, N'HFC-236fa', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (18, NULL, N'HFC-245fa', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (19, NULL, N'HFC-43-I0mee', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (20, NULL, N'Perfluoromethane (PFC-14)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (21, NULL, N'Perfluoroethane (PFC-116)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (22, NULL, N'Perfluoropropane (PFC-218)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (23, NULL, N'Perfluorocyclobutane (PFC-318)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (24, NULL, N'Perfluorobutane (PFC-3-1-10)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (25, NULL, N'Perfluoropentane (PFC-4-1-12)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (26, NULL, N'Perfluorohexane (PFC-5-1-14)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (27, NULL, N'PFC-9-1-18', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (28, NULL, N'Perfluorocyclopropane', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (29, NULL, N'Sulphur hexafluoride (SF6)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (30, NULL, N'HFC-152', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (31, NULL, N'HFC-161', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (32, NULL, N'HFC-236cb', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (33, NULL, N'HFC-236ea', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (34, NULL, N'HFC-245ca', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (35, NULL, N'HFC-365mfc', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (36, NULL, N'Nitrogen trifluoride', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (37, NULL, N'R401A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (38, NULL, N'R401B', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (39, NULL, N'R401C', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (40, NULL, N'R402A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (41, NULL, N'R402B', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (42, NULL, N'R403A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (43, NULL, N'R403B', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (44, NULL, N'R404A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (45, NULL, N'R405A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (46, NULL, N'R406A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (47, NULL, N'R407A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (48, NULL, N'R407B', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (49, NULL, N'R407C', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (50, NULL, N'R407D', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (51, NULL, N'R407E', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (52, NULL, N'R407F', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (53, NULL, N'R408A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (54, NULL, N'R409A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (55, NULL, N'R409B', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (56, NULL, N'R410A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (57, NULL, N'R410B', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (58, NULL, N'R411A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (59, NULL, N'R411B', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (60, NULL, N'R412A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (61, NULL, N'R413A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (62, NULL, N'R414A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (63, NULL, N'R414B', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (64, NULL, N'R415A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (65, NULL, N'R415B', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (66, NULL, N'R416A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (67, NULL, N'R417A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (68, NULL, N'R417B', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (69, NULL, N'R417C', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (70, NULL, N'R418A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (71, NULL, N'R419A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (72, NULL, N'R419B', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (73, NULL, N'R420A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (74, NULL, N'R421A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (75, NULL, N'R421B', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (76, NULL, N'R422A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (77, NULL, N'R422B', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (78, NULL, N'R422C', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (79, NULL, N'R422D', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (80, NULL, N'R422E', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (81, NULL, N'R423A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (82, NULL, N'R424A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (83, NULL, N'R425A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (84, NULL, N'R426A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (85, NULL, N'R427A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (86, NULL, N'R428A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (87, NULL, N'R429A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (88, NULL, N'R430A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (89, NULL, N'R431A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (90, NULL, N'R432A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (91, NULL, N'R433A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (92, NULL, N'R433B', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (93, NULL, N'R433C', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (94, NULL, N'R434A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (95, NULL, N'R435A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (96, NULL, N'R436A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (97, NULL, N'R436B', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (98, NULL, N'R437A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (99, NULL, N'R438A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (100, NULL, N'R439A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (101, NULL, N'R440A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (102, NULL, N'R441A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (103, NULL, N'R442A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (104, NULL, N'R443A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (105, NULL, N'R444A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (106, NULL, N'R445A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (107, NULL, N'R500', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (108, NULL, N'R501', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (109, NULL, N'R502', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (110, NULL, N'R503', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (111, NULL, N'R504', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (112, NULL, N'R505', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (113, NULL, N'R506', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (114, NULL, N'R507A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (115, NULL, N'R508A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (116, NULL, N'R508B', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (117, NULL, N'R509A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (118, NULL, N'R510A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (119, NULL, N'R511A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (120, NULL, N'R512A', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (121, NULL, N'CFC-11/R11 = trichlorofluoromethane', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (122, NULL, N'CFC-12/R12 = dichlorodifluoromethane', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (123, NULL, N'CFC-13', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (124, NULL, N'CFC-113', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (125, NULL, N'CFC-114', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (126, NULL, N'CFC-115', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (127, NULL, N'Halon-1211', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (128, NULL, N'Halon-1301', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (129, NULL, N'Halon-2402', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (130, NULL, N'Carbon tetrachloride', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (131, NULL, N'Methyl bromide', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (132, NULL, N'Methyl chloroform', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (133, NULL, N'HCFC-22/R22 = chlorodifluoromethane', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (134, NULL, N'HCFC-123', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (135, NULL, N'HCFC-124', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (136, NULL, N'HCFC-141b', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (137, NULL, N'HCFC-142b', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (138, NULL, N'HCFC-225ca', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (139, NULL, N'HCFC-225cb', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (140, NULL, N'HCFC-21', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (141, NULL, N'HFE-125', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (142, NULL, N'HFE-134', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (143, NULL, N'HFE-143a', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (144, NULL, N'HCFE-235da2', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (145, NULL, N'HFE-245cb2', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (146, NULL, N'HFE-245fa2', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (147, NULL, N'HFE-254cb2', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (148, NULL, N'HFE-347mcc3', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (149, NULL, N'HFE-347pcf2', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (150, NULL, N'HFE-356pcc3', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (151, NULL, N'HFE-449sl (HFE-7100)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (152, NULL, N'HFE-569sf2 (HFE-7200)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (153, NULL, N'HFE-43-10pccc124 (H-Galden1040x)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (154, NULL, N'HFE-236ca12 (HG-10)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (155, NULL, N'HFE-338pcc13 (HG-01)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (156, NULL, N'Trifluoromethyl sulphur pentafluoride', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (157, NULL, N'PFPMIE', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (158, NULL, N'Dimethylether', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (159, NULL, N'Methylene chloride', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (160, NULL, N'Methyl chloride', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (161, NULL, N'R290 = propane', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (162, NULL, N'R600A = isobutane', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (163, NULL, N'R600 = butane', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (164, NULL, N'R601 = pentane', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (165, NULL, N'R601A = isopentane', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (166, NULL, N'R170 = ethane', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (167, NULL, N'R1270 = propene', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (168, NULL, N'R1234yf*', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (169, NULL, N'R1234ze*', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (170, 1, N'Small Car Petrol', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (171, 1, N'Medium Car Petrol', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (172, 1, N'Large Car Petrol', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (173, 1, N'Small car diesel', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (174, 1, N'Medium car diesel', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (175, 1, N'Large car diesel', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (176, 1, N'Small car hybrid', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (177, 1, N'Medium car hybrid', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (178, 1, N'Large car hybrid', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (179, 1, N'Small car electric', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (180, 1, N'Medium car electric', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (181, 1, N'Large car electric', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (182, 1, N'Small car plug in hybrid', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (183, 1, N'Medium car plug in hybrid', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (184, 1, N'Large car plug in hybrid', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (185, NULL, N'Class I Vans Petrol', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (186, NULL, N'Class II Vans Petrol', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (187, NULL, N'Class III Vans Petrol', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (188, NULL, N'Class I Vans Diesel', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (189, NULL, N'Class II Vans Diesel', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (190, NULL, N'Class III Vans Diesel', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (192, NULL, N'Class I Vans Battery Electric', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (193, NULL, N'Class II Vans Battery Electric', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (194, NULL, N'Class III Vans Battery Electric', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (195, NULL, N'HGVs - Rigid (>3.5-7.5t)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (196, NULL, N'HGVs - Rigid (>7.5-17t)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (197, NULL, N'HGVs - Rigid (>17t)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (198, NULL, N'HGVs - Avg Rigids', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (199, NULL, N'HGVs - Articulated (>3.5-33t)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (200, NULL, N'HGVs - Articulated (>33t)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (201, NULL, N'HGVs - Avg Artics', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (202, NULL, N'No of litre - Petrol', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (203, NULL, N'No of litre - Diesel', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (204, NULL, N'Amount spent on Petrol', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (205, NULL, N'Amount spent on Diesel', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (206, NULL, N'Amount spent on other fuel', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (207, 1, N'Average car petrol', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (208, 1, N'Average car diesel', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (209, 1, N'Average car hybrid', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (210, 1, N'Average  car plug-in hybrid', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (211, 1, N'Average car electric', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (212, 1, N'Average Motorbike', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (213, 1, N'Train - National', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (214, 1, N'Train - Underground', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (215, 1, N'Regular Taxi', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (216, 1, N'Local Bus', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (217, 1, N'Flight - Domestic Avg Passenger', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (218, 1, N'Flight - Short haul Avg Passenger', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (219, 1, N'Flight - Long haul Avg Passenger', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (220, 1, N'Cycling', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (221, 1, N'Walking', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (222, 2, N'Hotel stay', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (223, 3, N'Email sent', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (224, 3, N'Pages printed', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (225, 0, N'Motorbike - Small', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (226, NULL, N'Motorbike - Medium ', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (227, NULL, N'Motorbike  - Large ', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (228, NULL, N'Train - International ', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (229, NULL, N'Train - Metro and/or tram', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (230, NULL, N'Train (Amount spend)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (231, NULL, N'Taxi (Amount spend)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (232, NULL, N'Bus Coach', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (233, NULL, N'Bus (Amount spend) ', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (234, NULL, N'Average Passenger -Short-Haul Flights', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (235, NULL, N'Economy Class - Short-Haul Flights', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (236, NULL, N'Business Class - Short-Haul Flights', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (237, NULL, N'Average Passenger Long Haul', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (238, NULL, N'Economy Class  Long Haul', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (239, NULL, N'Premium Economy Class  Long Haul', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (240, NULL, N'Business Class  Long Haul', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (241, NULL, N'First Class  Long Haul', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (242, NULL, N'Flight (Amount spend)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (243, NULL, N'Hotel (Amount spend) ', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (244, NULL, N'General Recycling', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (245, NULL, N'Construction Waste', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (246, NULL, N'Domestic waste', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (247, NULL, N'Organic: food and drink waste', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (248, NULL, N'Organic: garden waste', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (249, NULL, N'Organic: mixed food and garden waste', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (250, NULL, N'Commercial and industrial waste', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (251, NULL, N'Aggregates, Asphalt, Bricks, Concrete and Insulation', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (252, NULL, N'Asbestos', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (253, NULL, N'Metals', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (254, NULL, N'Soils', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (255, NULL, N'Plasterboard', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (256, NULL, N'Wood', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (257, NULL, N'Glass, Metal, Plastics and Electrical Items', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (258, NULL, N'Clothing', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (259, NULL, N'Paper', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (260, NULL, N'Farms', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (261, NULL, N'Forestry, fishing, and related activities', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (262, NULL, N'Oil and gas extraction', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (263, NULL, N'Mining, except oil and gas', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (264, NULL, N'Support activities for mining', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (265, NULL, N'Utilities', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (266, NULL, N'Construction', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (267, NULL, N'Food and beverage and tobacco products', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (268, NULL, N'Textile mills and textile product mills', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (269, NULL, N'Apparel and leather and allied products', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (270, NULL, N'Wood products', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (271, NULL, N'Paper products', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (272, NULL, N'Printing and related support activities', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (273, NULL, N'Petroleum and coal products', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (274, NULL, N'Chemical products', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (275, NULL, N'Plastics and rubber products', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (276, NULL, N'Nonmetallic mineral products', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (277, NULL, N'Primary metals', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (278, NULL, N'Fabricated metal products', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (279, NULL, N'Machinery', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (280, NULL, N'Computer and electronic products', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (281, NULL, N'Electrical equipment, appliances, and components', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (282, NULL, N'Motor vehicles, bodies and trailers, and parts', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (283, NULL, N'Other transportation equipment', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (284, NULL, N'Furniture and related products', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (285, NULL, N'Miscellaneous manufacturing', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (286, NULL, N'Wholesale trade', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (287, NULL, N'Motor vehicle and parts dealers', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (288, NULL, N'Food and beverage stores', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (289, NULL, N'General merchandise stores', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (290, NULL, N'Air transportation', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (291, NULL, N'Rail transportation', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (292, NULL, N'Water transportation', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (293, NULL, N'Truck transportation', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (294, NULL, N'Transit and ground passenger transportation', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (295, NULL, N'Pipeline transportation', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (296, NULL, N'Other transportation and support activities', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (297, NULL, N'Warehousing and storage', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (298, NULL, N'Other retail', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (299, NULL, N'Publishing industries, except internet (includes software)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (300, NULL, N'Motion picture and sound recording industries', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (301, NULL, N'Broadcasting and telecommunications', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (302, NULL, N'Data processing, internet publishing, and other information services', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (303, NULL, N'Federal Reserve banks, credit intermediation, and related activities', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (304, NULL, N'Securities, commodity contracts, and investments', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (305, NULL, N'Insurance carriers and related activities', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (306, NULL, N'Funds, trusts, and other financial vehicles', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (307, NULL, N'Rental and leasing services and lessors of intangible assets', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (308, NULL, N'Legal services', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (309, NULL, N'Miscellaneous professional, scientific, and technical services', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (310, NULL, N'Computer systems design and related services', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (311, NULL, N'Management of companies and enterprises', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (312, NULL, N'Administrative and support services', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (313, NULL, N'Waste management and remediation services', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (314, NULL, N'Educational services', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (315, NULL, N'Ambulatory health care services', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (316, NULL, N'Hospitals', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (317, NULL, N'Nursing and residential care facilities', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (318, NULL, N'Social assistance', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (319, NULL, N'Performing arts, spectator sports, museums, and related activities', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (320, NULL, N'Amusements, gambling, and recreation industries', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (321, NULL, N'Accommodation', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (322, NULL, N'Food services and drinking places', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (323, NULL, N'Other services, except government', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (324, NULL, N'Housing', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (325, NULL, N'Other real estate', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (326, NULL, N'Butane', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (327, NULL, N'CNG', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (328, NULL, N'LNG', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (329, NULL, N'LPG', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (330, NULL, N'Natural gas', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (331, NULL, N'Natural gas (100% mineral blend)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (332, NULL, N'Other petroleum gas', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (333, NULL, N'Propane', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (334, NULL, N'Aviation spirit', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (335, NULL, N'Aviation turbine fuel', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (336, NULL, N'Burning oil', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (337, NULL, N'Diesel (average biofuel blend)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (338, NULL, N'Diesel (100% mineral diesel)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (339, NULL, N'Fuel oil', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (340, NULL, N'Gas oil', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (341, NULL, N'Lubricants', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (342, NULL, N'Naphtha', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (343, NULL, N'Petrol (average biofuel blend)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (344, NULL, N'Petrol (100% mineral petrol)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (345, NULL, N'Processed fuel oils - residual oil', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (346, NULL, N'Processed fuel oils - distillate oil', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (347, NULL, N'Refinery miscellaneous', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (348, NULL, N'Waste oils', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (349, NULL, N'Marine gas oil', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (350, NULL, N'Marine fuel oil', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (351, NULL, N'Coal (industrial)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (352, NULL, N'Coal (electricity generation)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (353, NULL, N'Coal (domestic)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (354, NULL, N'Coking coal', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (355, NULL, N'Petroleum coke', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (356, NULL, N'Coal (electricity generation - home produced coal only)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (357, NULL, N'Electricity for home working', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (358, NULL, N'Gas heating for home working', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (359, NULL, N'Oil heating for home working', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (360, NULL, N'Deliveries by Van', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (361, NULL, N'Deliveries by Truck', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (362, NULL, N'Deliveries by Rail', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (363, NULL, N'Deliveries by Short Haul', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (364, NULL, N'Deliveries by Long Haul', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (365, NULL, N'Deliveries by Sea Cargo', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (366, NULL, N'Deliveries Itemised Entry (multiple activities)', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (367, NULL, N'R22', NULL, 1)
GO
INSERT [Emissions].[EmissionActivity] ([id], [parentId], [name], [description], [active]) VALUES (368, NULL, N'R32', NULL, 1)
GO
SET IDENTITY_INSERT [Emissions].[EmissionActivity] OFF
GO
SET IDENTITY_INSERT [Emissions].[EmissionCategory] ON 
GO
INSERT [Emissions].[EmissionCategory] ([id], [name], [description], [parentId], [active]) VALUES (1, N'Travel', NULL, NULL, 1)
GO
INSERT [Emissions].[EmissionCategory] ([id], [name], [description], [parentId], [active]) VALUES (2, N'Accomodation', NULL, NULL, 1)
GO
INSERT [Emissions].[EmissionCategory] ([id], [name], [description], [parentId], [active]) VALUES (3, N'Other', NULL, NULL, 1)
GO
SET IDENTITY_INSERT [Emissions].[EmissionCategory] OFF
GO
SET IDENTITY_INSERT [Emissions].[EmissionFactor] ON 
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (1, 1, CAST(0.14900 AS Decimal(10, 5)), CAST(0.27200 AS Decimal(10, 5)), NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (2, 2, CAST(0.19340 AS Decimal(10, 5)), CAST(0.04630 AS Decimal(10, 5)), NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (3, 3, CAST(0.18292 AS Decimal(10, 5)), CAST(0.03021 AS Decimal(10, 5)), NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (5, 4, CAST(1.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (6, 5, CAST(25.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (7, 6, CAST(298.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (14, 7, CAST(14800.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (15, 8, CAST(675.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (16, 9, CAST(92.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (17, 10, CAST(3500.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (18, 11, CAST(1100.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (19, 12, CAST(1430.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (20, 13, CAST(353.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (21, 14, CAST(4470.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (22, 15, CAST(124.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (23, 16, CAST(3220.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (24, 17, CAST(9810.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (25, 18, CAST(1030.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (26, 19, CAST(1640.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (27, 20, CAST(7390.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (28, 21, CAST(12200.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (29, 22, CAST(8830.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (30, 23, CAST(10300.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (31, 24, CAST(8860.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (32, 25, CAST(9160.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (33, 26, CAST(9300.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (34, 27, CAST(7500.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (35, 28, CAST(17340.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (36, 29, CAST(22800.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (37, 30, CAST(53.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (38, 31, CAST(12.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (39, 32, CAST(1340.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (40, 33, CAST(1370.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (41, 34, CAST(693.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (42, 35, CAST(794.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (43, 36, CAST(17200.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (44, 37, CAST(1182.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (45, 38, CAST(1288.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (46, 39, CAST(933.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (47, 40, CAST(2788.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (48, 41, CAST(2416.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (49, 42, CAST(3124.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (50, 43, CAST(4457.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (51, 44, CAST(3922.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (52, 45, CAST(4716.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (53, 46, CAST(1943.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (54, 47, CAST(2107.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (55, 48, CAST(2804.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (56, 49, CAST(1774.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (57, 50, CAST(1627.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (58, 51, CAST(1552.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (59, 52, CAST(1825.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (60, 53, CAST(3152.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (61, 54, CAST(1585.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (62, 55, CAST(1560.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (63, 56, CAST(2088.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (64, 57, CAST(2229.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (65, 58, CAST(1597.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (66, 59, CAST(1705.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (67, 60, CAST(2286.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (68, 61, CAST(2053.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (69, 62, CAST(1478.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (70, 63, CAST(1362.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (71, 64, CAST(1507.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (72, 65, CAST(546.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (73, 66, CAST(1084.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (74, 67, CAST(2346.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (75, 68, CAST(3027.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (76, 69, CAST(1809.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (77, 70, CAST(1741.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (78, 71, CAST(2967.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (79, 72, CAST(2384.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (80, 73, CAST(1536.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (81, 74, CAST(2631.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (82, 75, CAST(3190.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (83, 76, CAST(3143.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (84, 77, CAST(2526.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (85, 78, CAST(3085.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (86, 79, CAST(2729.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (87, 80, CAST(2592.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (88, 81, CAST(2280.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (89, 82, CAST(2440.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (90, 83, CAST(1505.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (91, 84, CAST(1508.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (92, 85, CAST(2138.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (93, 86, CAST(3607.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (94, 87, CAST(14.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (95, 88, CAST(95.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (96, 89, CAST(38.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (97, 90, CAST(2.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (98, 91, CAST(3.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (99, 92, CAST(3.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (100, 93, CAST(3.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (101, 94, CAST(3245.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (102, 95, CAST(26.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (103, 96, CAST(3.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (104, 97, CAST(3.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (105, 98, CAST(1805.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (106, 99, CAST(2265.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (107, 100, CAST(1983.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (108, 101, CAST(144.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (109, 102, CAST(3.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (110, 103, CAST(1888.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (111, 104, CAST(2.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (112, 105, CAST(88.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (113, 106, CAST(130.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (114, 107, CAST(8077.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (115, 108, CAST(4083.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (116, 109, CAST(4657.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (117, 110, CAST(14560.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (118, 111, CAST(4143.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (119, 112, CAST(8502.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (120, 113, CAST(4490.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (121, 114, CAST(3985.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (122, 115, CAST(13214.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (123, 116, CAST(13396.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (124, 117, CAST(5741.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (125, 118, CAST(1.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (126, 119, CAST(9.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (127, 120, CAST(189.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (128, 121, CAST(4750.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (129, 122, CAST(10900.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (130, 123, CAST(14400.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (131, 124, CAST(6130.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (132, 125, CAST(10000.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (133, 126, CAST(7370.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (134, 127, CAST(1890.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (135, 128, CAST(7140.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (136, 129, CAST(1640.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (137, 130, CAST(1400.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (138, 131, CAST(5.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (139, 132, CAST(146.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (140, 133, CAST(1810.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (141, 134, CAST(77.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (142, 135, CAST(609.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (143, 136, CAST(725.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (144, 137, CAST(2310.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (145, 138, CAST(122.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (146, 139, CAST(595.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (147, 140, CAST(151.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (148, 141, CAST(14900.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (149, 142, CAST(6320.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (150, 143, CAST(756.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (151, 144, CAST(350.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (152, 145, CAST(708.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (153, 146, CAST(659.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (154, 147, CAST(359.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (155, 148, CAST(575.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (156, 149, CAST(580.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (157, 150, CAST(110.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (158, 151, CAST(297.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (159, 152, CAST(59.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (160, 153, CAST(1870.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (161, 154, CAST(2800.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (162, 155, CAST(1500.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (163, 156, CAST(17700.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (164, 157, CAST(10300.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (165, 158, CAST(1.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (166, 159, CAST(9.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (167, 160, CAST(13.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (168, 161, CAST(3.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (169, 162, CAST(3.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (170, 163, CAST(4.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (171, 164, CAST(5.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (172, 165, CAST(5.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (173, 166, CAST(6.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (174, 167, CAST(2.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (175, 168, CAST(1.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (176, 169, CAST(1.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 2022, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (181, 170, CAST(0.14652 AS Decimal(10, 5)), CAST(0.04186 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (182, 171, CAST(0.18470 AS Decimal(10, 5)), CAST(0.06737 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (183, 172, CAST(0.27639 AS Decimal(10, 5)), CAST(0.05266 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (184, 173, CAST(0.13989 AS Decimal(10, 5)), CAST(0.03344 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (185, 174, CAST(0.16800 AS Decimal(10, 5)), CAST(0.05381 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (186, 175, CAST(0.20953 AS Decimal(10, 5)), CAST(0.04018 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (187, 176, CAST(0.10332 AS Decimal(10, 5)), CAST(0.02808 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (188, 177, CAST(0.10999 AS Decimal(10, 5)), CAST(0.04519 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (189, 178, CAST(0.15491 AS Decimal(10, 5)), CAST(0.02857 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (190, 179, CAST(0.04416 AS Decimal(10, 5)), CAST(0.04625 AS Decimal(10, 5)), CAST(0.00369 AS Decimal(10, 5)), CAST(0.00423 AS Decimal(10, 5)), NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (191, 180, CAST(0.04878 AS Decimal(10, 5)), CAST(0.04625 AS Decimal(10, 5)), CAST(0.00596 AS Decimal(10, 5)), CAST(0.00423 AS Decimal(10, 5)), NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (192, 181, CAST(0.05550 AS Decimal(10, 5)), CAST(0.04625 AS Decimal(10, 5)), CAST(0.00410 AS Decimal(10, 5)), CAST(0.00423 AS Decimal(10, 5)), NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (193, 182, CAST(0.02163 AS Decimal(10, 5)), CAST(0.01317 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (194, 183, CAST(0.06144 AS Decimal(10, 5)), CAST(0.02220 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (195, 184, CAST(0.03884 AS Decimal(10, 5)), CAST(0.02635 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (196, 185, NULL, NULL, NULL, NULL, NULL, 1, 0)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (197, 185, CAST(0.19687 AS Decimal(10, 5)), CAST(0.05603 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (198, 186, CAST(0.20461 AS Decimal(10, 5)), CAST(0.05556 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (199, 187, CAST(0.32607 AS Decimal(10, 5)), CAST(0.08788 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (200, 188, CAST(0.14189 AS Decimal(10, 5)), CAST(0.03568 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (201, 189, CAST(0.17513 AS Decimal(10, 5)), CAST(0.04467 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (202, 190, CAST(0.25481 AS Decimal(10, 5)), CAST(0.06491 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (203, 192, CAST(0.00000 AS Decimal(10, 5)), CAST(0.01030 AS Decimal(10, 5)), CAST(0.00303 AS Decimal(10, 5)), NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (204, 193, CAST(0.00000 AS Decimal(10, 5)), CAST(0.01422 AS Decimal(10, 5)), CAST(0.00473 AS Decimal(10, 5)), NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (205, 194, CAST(0.00000 AS Decimal(10, 5)), CAST(0.01995 AS Decimal(10, 5)), CAST(0.00782 AS Decimal(10, 5)), NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (206, 195, CAST(0.49758 AS Decimal(10, 5)), CAST(0.11660 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (207, 196, CAST(0.60793 AS Decimal(10, 5)), CAST(0.14220 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (208, 197, CAST(0.99337 AS Decimal(10, 5)), CAST(0.23228 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (209, 198, CAST(0.84061 AS Decimal(10, 5)), CAST(0.19479 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (210, 199, CAST(0.78111 AS Decimal(10, 5)), CAST(0.18579 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (211, 200, CAST(0.93004 AS Decimal(10, 5)), CAST(0.22106 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (212, 201, CAST(0.92391 AS Decimal(10, 5)), CAST(0.21962 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (213, 202, NULL, NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (214, 203, NULL, NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (215, 204, NULL, NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (216, 205, NULL, NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (217, 206, NULL, NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (218, 207, CAST(0.17048 AS Decimal(10, 5)), CAST(0.04885 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (219, 208, CAST(0.17082 AS Decimal(10, 5)), CAST(0.04104 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (220, 209, CAST(0.12004 AS Decimal(10, 5)), CAST(0.03132 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (221, 210, CAST(0.06840 AS Decimal(10, 5)), CAST(0.00210 AS Decimal(10, 5)), CAST(0.00210 AS Decimal(10, 5)), NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (222, 211, CAST(0.00000 AS Decimal(10, 5)), CAST(0.01426 AS Decimal(10, 5)), CAST(0.00431 AS Decimal(10, 5)), NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (223, 212, NULL, NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (224, 213, CAST(0.03549 AS Decimal(10, 5)), CAST(0.00892 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (225, 214, CAST(0.02781 AS Decimal(10, 5)), CAST(0.00724 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (226, 215, CAST(0.14876 AS Decimal(10, 5)), CAST(0.03632 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (227, 216, CAST(0.09650 AS Decimal(10, 5)), CAST(0.02494 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (228, 217, CAST(0.24587 AS Decimal(10, 5)), CAST(0.02691 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (229, 218, CAST(0.15353 AS Decimal(10, 5)), CAST(0.01681 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (230, 219, CAST(0.19309 AS Decimal(10, 5)), CAST(0.02114 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (231, 220, CAST(0.00000 AS Decimal(10, 5)), CAST(0.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (232, 221, CAST(0.00000 AS Decimal(10, 5)), CAST(0.00000 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (233, 222, CAST(63.80000 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (234, 223, CAST(0.00300 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (235, 224, CAST(0.00423 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (236, 225, CAST(0.08306 AS Decimal(10, 5)), CAST(0.02277 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (237, 226, CAST(0.10090 AS Decimal(10, 5)), CAST(0.02765 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (238, 227, CAST(0.13245 AS Decimal(10, 5)), CAST(0.03678 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (239, 228, CAST(0.00446 AS Decimal(10, 5)), CAST(0.00116 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (240, 229, CAST(0.02861 AS Decimal(10, 5)), CAST(0.00745 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (241, 230, NULL, NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (242, 231, NULL, NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (243, 232, CAST(0.02733 AS Decimal(10, 5)), CAST(0.00646 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (244, 233, NULL, NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (245, 234, CAST(0.18592 AS Decimal(10, 5)), CAST(0.02286 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (246, 235, CAST(0.18287 AS Decimal(10, 5)), CAST(0.02249 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (247, 236, CAST(0.27430 AS Decimal(10, 5)), CAST(0.03373 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (248, 237, CAST(0.26128 AS Decimal(10, 5)), CAST(0.03213 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (249, 238, CAST(0.20011 AS Decimal(10, 5)), CAST(0.02461 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (250, 239, CAST(0.32016 AS Decimal(10, 5)), CAST(0.03937 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (251, 240, CAST(0.58029 AS Decimal(10, 5)), CAST(0.07137 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (252, 241, CAST(0.80040 AS Decimal(10, 5)), CAST(0.09844 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (253, 242, NULL, NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (254, 243, NULL, NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (255, 244, CAST(0.98500 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (256, 245, NULL, NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (257, 246, NULL, NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (258, 247, NULL, NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (259, 248, NULL, NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (260, 249, NULL, NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (261, 250, NULL, NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (262, 251, NULL, NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (263, 252, NULL, NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (264, 253, NULL, NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (265, 254, NULL, NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (266, 255, NULL, NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (267, 256, NULL, NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (268, 257, NULL, NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (269, 258, NULL, NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (270, 259, NULL, NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (271, 260, CAST(1.76300 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (272, 261, CAST(0.30000 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (273, 262, CAST(1.27300 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (274, 263, CAST(1.32900 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (275, 264, CAST(0.77400 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (276, 265, CAST(3.01900 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (277, 266, CAST(0.32900 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (278, 267, CAST(0.84100 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (279, 268, CAST(0.37700 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (280, 269, CAST(0.43500 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (281, 270, CAST(0.25300 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (282, 271, CAST(0.39600 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (283, 272, CAST(0.25900 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (284, 273, CAST(1.22800 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (285, 274, CAST(0.33000 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (286, 275, CAST(0.20900 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (287, 276, CAST(0.59200 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (288, 277, CAST(0.08100 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (289, 278, CAST(0.27200 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (290, 279, CAST(0.25300 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (291, 280, CAST(0.07900 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (292, 281, CAST(0.26800 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (293, 282, CAST(0.23200 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (294, 283, CAST(0.09500 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (295, 284, CAST(0.29200 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (296, 285, CAST(0.25700 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (297, 286, CAST(0.14100 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (298, 287, CAST(0.14700 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (299, 288, CAST(0.24800 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (300, 289, CAST(0.17700 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (301, 290, CAST(0.92300 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (302, 291, CAST(0.72200 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (303, 292, CAST(0.74200 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (304, 293, CAST(1.38900 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (305, 294, CAST(0.34300 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (306, 295, CAST(1.79100 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (307, 296, CAST(0.42600 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (308, 297, CAST(0.45500 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (309, 298, CAST(0.17500 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (310, 299, CAST(0.05700 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (311, 300, CAST(0.05600 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (312, 301, CAST(0.08400 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (313, 302, CAST(0.08500 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (314, 303, CAST(0.07000 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (315, 304, CAST(0.10300 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (316, 305, CAST(0.04300 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (317, 306, CAST(0.20900 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (318, 307, CAST(0.09300 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (319, 308, CAST(0.05900 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (320, 309, CAST(0.13800 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (321, 310, CAST(0.06400 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (322, 311, CAST(0.10400 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (323, 312, CAST(0.11700 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (324, 313, CAST(1.38700 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (325, 314, CAST(0.20400 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (326, 315, CAST(0.09100 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (327, 316, CAST(0.17200 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (328, 317, CAST(0.17000 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (329, 318, CAST(0.16400 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (330, 319, CAST(0.07400 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (331, 320, CAST(0.38000 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (332, 321, CAST(0.18500 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (333, 322, CAST(0.22500 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (334, 323, CAST(0.15300 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (335, 324, CAST(0.02200 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (336, 325, CAST(0.43400 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (337, 326, CAST(0.24110 AS Decimal(10, 5)), CAST(0.02719 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (338, 327, CAST(0.20230 AS Decimal(10, 5)), CAST(0.04282 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (339, 328, CAST(0.20390 AS Decimal(10, 5)), CAST(0.07055 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (340, 329, CAST(0.23030 AS Decimal(10, 5)), CAST(0.02719 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (341, 330, CAST(0.20230 AS Decimal(10, 5)), CAST(0.03446 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (342, 331, CAST(0.20390 AS Decimal(10, 5)), CAST(0.03446 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (343, 332, CAST(0.19920 AS Decimal(10, 5)), CAST(0.02352 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (344, 333, CAST(0.23260 AS Decimal(10, 5)), CAST(0.02719 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (345, 334, CAST(0.25660 AS Decimal(10, 5)), CAST(0.06552 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (346, 335, CAST(0.26090 AS Decimal(10, 5)), CAST(0.05400 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (347, 336, CAST(0.25980 AS Decimal(10, 5)), CAST(0.05400 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (348, 337, CAST(0.25630 AS Decimal(10, 5)), CAST(0.06109 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (349, 338, CAST(0.26940 AS Decimal(10, 5)), CAST(0.06264 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (350, 339, CAST(0.28530 AS Decimal(10, 5)), CAST(0.06264 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (351, 340, CAST(0.27320 AS Decimal(10, 5)), CAST(0.06264 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (352, 341, CAST(0.28100 AS Decimal(10, 5)), CAST(0.07280 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (353, 342, CAST(0.24900 AS Decimal(10, 5)), CAST(0.05076 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (354, 343, CAST(0.23960 AS Decimal(10, 5)), CAST(0.06774 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (355, 344, CAST(0.25430 AS Decimal(10, 5)), CAST(0.06552 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (356, 345, CAST(0.28530 AS Decimal(10, 5)), CAST(0.07384 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (357, 346, CAST(0.27320 AS Decimal(10, 5)), CAST(0.07010 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (358, 347, CAST(0.25970 AS Decimal(10, 5)), CAST(0.03058 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (359, 348, CAST(0.27500 AS Decimal(10, 5)), CAST(0.07029 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (360, 349, CAST(0.27490 AS Decimal(10, 5)), CAST(0.06264 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (361, 350, CAST(0.27910 AS Decimal(10, 5)), CAST(0.06264 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (362, 351, CAST(0.34170 AS Decimal(10, 5)), CAST(0.05571 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (363, 352, CAST(0.33820 AS Decimal(10, 5)), CAST(0.05571 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (364, 353, CAST(0.36280 AS Decimal(10, 5)), CAST(0.05571 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (365, 354, CAST(0.37680 AS Decimal(10, 5)), CAST(0.05571 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (366, 355, CAST(0.35890 AS Decimal(10, 5)), CAST(0.04231 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (367, 356, CAST(0.33820 AS Decimal(10, 5)), CAST(0.05571 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (368, 357, CAST(0.19338 AS Decimal(10, 5)), CAST(0.04625 AS Decimal(10, 5)), CAST(0.01769 AS Decimal(10, 5)), NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (369, 358, CAST(0.20000 AS Decimal(10, 5)), CAST(0.03446 AS Decimal(10, 5)), NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (370, 367, CAST(1810.00000 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
INSERT [Emissions].[EmissionFactor] ([id], [activityId], [ef], [wtt], [tnd], [tndWtt], [year], [emissionProfileId], [active]) VALUES (371, 368, CAST(677.00000 AS Decimal(10, 5)), NULL, NULL, NULL, NULL, 1, 1)
GO
SET IDENTITY_INSERT [Emissions].[EmissionFactor] OFF
GO
SET IDENTITY_INSERT [Emissions].[EmissionProfile] ON 
GO
INSERT [Emissions].[EmissionProfile] ([id], [name], [description], [active], [year]) VALUES (1, N'UAE 2022', NULL, 1, 2022)
GO
INSERT [Emissions].[EmissionProfile] ([id], [name], [description], [active], [year]) VALUES (2, N'UK 2022', NULL, 1, 2022)
GO
SET IDENTITY_INSERT [Emissions].[EmissionProfile] OFF
GO
SET IDENTITY_INSERT [Forms].[JotForm] ON 
GO
INSERT [Forms].[JotForm] ([id], [name], [description], [category], [formId], [active]) VALUES (1, N'Water v1.0', N'', N'Certifications', N'231921316591454', 1)
GO
INSERT [Forms].[JotForm] ([id], [name], [description], [category], [formId], [active]) VALUES (2, N'Electricity v1.0', N'', N'Certifications', N'231835207128453', 1)
GO
INSERT [Forms].[JotForm] ([id], [name], [description], [category], [formId], [active]) VALUES (3, N'Natural Gas v1.0', N'', N'Certifications', N'231761029921959', 1)
GO
INSERT [Forms].[JotForm] ([id], [name], [description], [category], [formId], [active]) VALUES (4, N'Refrigerents v1.0', NULL, N'Certifications', N'231953063487462', 1)
GO
INSERT [Forms].[JotForm] ([id], [name], [description], [category], [formId], [active]) VALUES (5, N'Company Vehicles', NULL, N'Certifications', N'232571467469467', 1)
GO
INSERT [Forms].[JotForm] ([id], [name], [description], [category], [formId], [active]) VALUES (6, N'ME Carbon Footprint Impact Survey', NULL, N'Events', N'233020948970862', 1)
GO
INSERT [Forms].[JotForm] ([id], [name], [description], [category], [formId], [active]) VALUES (7, N'Business Travel', NULL, N'Certifications', N'231702222306037', 1)
GO
INSERT [Forms].[JotForm] ([id], [name], [description], [category], [formId], [active]) VALUES (8, N'Waste and Recycling', NULL, N'Certifications', N'231998306100453', 1)
GO
INSERT [Forms].[JotForm] ([id], [name], [description], [category], [formId], [active]) VALUES (9, N'Purchased Goods and Services', NULL, N'Certifications', N'232013593953456', 1)
GO
INSERT [Forms].[JotForm] ([id], [name], [description], [category], [formId], [active]) VALUES (10, N'Other Fuels v1.0', NULL, N'Certifications', N'231951471518458', 1)
GO
INSERT [Forms].[JotForm] ([id], [name], [description], [category], [formId], [active]) VALUES (11, N'Commuting & Home Working', NULL, N'Certifications', N'232102389529457', 1)
GO
INSERT [Forms].[JotForm] ([id], [name], [description], [category], [formId], [active]) VALUES (12, N'Upstream deliveries', NULL, N'Certifications', N'232408584059461', 1)
GO
INSERT [Forms].[JotForm] ([id], [name], [description], [category], [formId], [active]) VALUES (13, N'Downstream deliveries', NULL, N'Certifications', N'232561815184457', 1)
GO
SET IDENTITY_INSERT [Forms].[JotForm] OFF
GO
SET IDENTITY_INSERT [Forms].[Question] ON 
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (1, N'q9_customerId', N'', 1, 1, 1, N'nvarchar', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (2, N'q44_haveYou', N'', NULL, 1, 1, N'nvarchar', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (3, N'q19_howWould19', N'', NULL, 1, 1, N'nvarchar', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (4, N'q5_howWould', N'', NULL, 1, 1, N'', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (5, N'q39_whichUnit', N'', 9, 1, 1, N'nvarchar', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (6, N'q4_typeA', N'', 5, 6, 1, N'decimal', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (7, N'q6_typeA6', N'', 6, 6, 1, N'decimal', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (8, N'q45_typeA45', N'', 7, 5, 1, N'string', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (9, N'q46_typeA46', N'', 4, 6, 1, N'decimal', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (10, N'q50_conversionFactor', N'', NULL, 6, 1, N'decimal', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (11, N'q27_doYou', N'', NULL, NULL, 1, N'', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (12, N'q47_reportingFrequency', N'', 2, NULL, 1, N'', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (13, N'q48_optinPreference', N'', 3, NULL, 1, N'', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (14, N'q49_managementBasedDecision', N'', 8, NULL, 1, N'', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (15, N'q50_conversionFactor', N'', 10, NULL, 1, N'', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (18, N'q9_customerId', N'', 1, NULL, 2, N'nvarchar', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (19, N'q40_haveYou', N'', NULL, 1, 2, N'nvarchar', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (20, N'q19_howWould19', N'', NULL, 1, 2, N'nvarchar', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (21, N'q41_typeA41', N'', 7, 1, 2, N'string', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (22, N'q42_typeA42', N'', 4, NULL, 2, N'decimal', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (23, N'q4_typeA', N'', 5, 1, 2, N'decimal', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (24, N'q6_typeA6', N'', 6, 1, 2, N'decimal', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (25, N'q24_areThere', N'', NULL, 1, 2, N'nvarchar', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (26, N'q5_howWould', N'', NULL, NULL, 2, N'nvarchar', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (27, N'q43_reportingFrequency', N'', 2, NULL, 2, N'int', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (28, N'q45_optinPreference', N'', 3, NULL, 2, N'int', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (29, N'q44_managementbaseddecision', N'', 8, NULL, 2, N'int', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (30, N'q46_conversionFactor', N'', 10, NULL, 2, N'decimal', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (31, N'q47_typeA47', N'', 9, NULL, 2, N'', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (32, N'q9_customerId', N'', 1, NULL, 3, N'nvarchar', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (33, N'q71_haveYou', N'', NULL, NULL, 3, N'', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (34, N'q28_howWould', N'', NULL, NULL, 3, N'', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (35, N'q45_wouldYou', N'', NULL, NULL, 3, N'', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (36, N'q44_monthlyUsage', N'', 5, 0, 3, N'decimal', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (37, N'q46_annualisedUsage', N'', 6, 0, 3, N'decimal', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (38, N'q67_selectMonth', N'', 7, 0, 3, N'string', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (39, N'q66_monthly', N'', 4, 0, 3, N'decimal', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (40, N'q72_reportingFrequency', N'', 2, NULL, 3, N'int', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (41, N'q73_optinPreference', N'', 3, NULL, 3, N'int', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (42, N'q74_managementbaseddecision', N'', 8, NULL, 3, N'int', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (43, N'q75_conversionFactor', N'', 10, NULL, 3, N'decimal', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (48, N'q9_customerId', NULL, 1, NULL, 4, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (49, N'q457_haveYou', NULL, NULL, NULL, 4, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (50, N'q458_howWould', NULL, NULL, NULL, 4, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (51, N'q459_reportingFrequency', NULL, 2, NULL, 4, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (52, N'q54_typeA54', N'Kyto Protocol - Monthly', 4, NULL, 4, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (53, N'q461_selectA', NULL, 7, NULL, 4, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (54, N'q462_annualiseEnter', N'Kyto Protocol - Annaul', 6, NULL, 4, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (55, N'q463_enterThe463', N'Kyto Protocol - Jan to Jun', 11, NULL, 4, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (56, N'q464_enterThe464', N'Kyto Protocol - Jul to Dec', 12, NULL, 4, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (57, N'q112_enterThe112', N'Blend - Monthly', 4, NULL, 4, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (58, N'q467_enterThe467', N'Blend - Annual', 6, NULL, 4, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (59, N'q468_enterThe468', N'Blend - Jan to Jun', 11, NULL, 4, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (60, N'q469_enterThe469', N'Blend - Jul to Dec', 12, NULL, 4, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (61, N'q361_typeA', N'Montreal protocol - Monthly', 4, NULL, 4, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (62, N'q470_enterThe470', N'Montreal protocol - Annually', 6, NULL, 4, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (63, N'q471_annualisemonthly471', N'Montreal protocol - Jan to Jun', 11, NULL, 4, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (64, N'q472_annualisemonthly472', N'Montreal protocol - Jul to Dec', 12, NULL, 4, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (65, N'q407_typeA407', N'Fluorinated ethers - Monthly', 4, NULL, 4, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (66, N'q473_enterThe', N'Fluorinated ethers - Annually', 6, NULL, 4, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (67, N'q474_enterThe474', N'Fluorinated ethers - Jan to Jun', 11, NULL, 4, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (68, N'q475_enterThe475', N'Fluorinated ethers - Jul to Dec', 12, NULL, 4, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (69, N'q439_typeA439', N'Other products - Monthly', 4, NULL, 4, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (70, N'q478_enterThe478', N'Other products - Annually', 6, NULL, 4, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (71, N'q479_enterThe479', N'Other products - Jan to Jun', 11, NULL, 4, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (72, N'q480_enterThe480', N'Other products - Jul to Dec', 12, NULL, 4, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (73, N'q76_dataunit', NULL, 9, NULL, 3, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (74, N'q489_optInPreference', NULL, 3, NULL, 4, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (75, N'q490_dataUnit', NULL, 9, NULL, 4, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (76, N'q379_pleaseEnter', NULL, 1, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (77, N'q470_howWould470', NULL, NULL, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (78, N'q471_reportingFrequency', NULL, 2, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (79, N'q473_selectA', NULL, 7, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (80, N'q584_conversionFactor', NULL, 10, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (81, N'q342_whichUnit342', NULL, 9, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (82, N'q585_optinPreference', NULL, 3, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (83, N'q85_enterMonthly', N'Passenger car petrol - Monthly', 4, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (84, N'q484_enterAnnual', N'Passenger car petrol - Annually', 6, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (85, N'q472_enterAnnual472', N'Passenger car petrol - AnnaulByMonths', 5, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (86, N'q110_travelUnits110', N'Passenger car diesel - Monthly', 4, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (87, N'q485_enterAnnual485', N'Passenger car diesel - Annually', 6, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (88, N'q474_enterDistance474', N'Passenger car diesel - AnnaulByMonths', 5, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (89, N'q159_enterMonthly159', N'Passenger car Hybrid - Monthly', 4, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (90, N'q486_enterAnnual486', N'Passenger car Hybrid - Annually', 6, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (91, N'q475_enterDistance475', N'Passenger car Hybrid - AnnaulByMonths', 5, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (92, N'q181_enterMonthly181', N'Passenger car Electric - Monthly', 4, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (93, N'q487_enterAnnual487', N'Passenger car Electric - Annually', 6, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (94, N'q477_enterDistance477', N'Passenger car Electric - AnnaulByMonths', 5, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (95, N'q563_enterMonthly563', N'Passenger car Hybrid Electric - Monthly', 4, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (96, N'q564_enterAnnual564', N'Passenger car Hybrid Electric - Annually', 6, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (97, N'q565_enterAnnual565', N'Passenger car Hybrid Electric - AnnaulByMonths', 5, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (98, N'q538_enterMonthly538', N'Vans Petrol Monthly', 4, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (99, N'q539_enterAnnual539', N'Vans Petrol Annually', 6, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (100, N'q540_enterAnnual540', N'Vans Petrol Annual By Months', 5, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (101, N'q548_enterMonthly548', N'Vans Diesel Monthly', 4, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (102, N'q549_enterAnnual549', N'Vans Diesel Annually', 6, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (103, N'q550_enterAnnual550', N'Vans Diesel Annual By Months', 5, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (105, N'q552_enterMonthly552', N'Vans Batter Electric Monthly', 4, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (106, N'q553_enterAnnual553', N'Vans Batter Electric Annually', 6, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (107, N'q554_enterAnnual554', N'Vans Batter Electric Annual By Months', 5, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (108, N'q543_enterMonthly543', N'HGVs Montly', 4, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (109, N'q544_enterAnnual544', N'HGVs Annually', 6, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (110, N'q545_enterAnnual545', N'HGVs Annual By Months', 5, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (111, N'q391_enterMonthly391', N'No of litre Petrol Monthly', 4, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (112, N'q489_passengerCar489', N'No of litre Petrol Annual', 6, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (114, N'q480_enterDistance480', N'No of litre Petrol Annual By Months', 5, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (115, N'q407_enterMonthly407', N'No of litre Diesel Monthly', 4, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (116, N'q490_enterAnnual490', N'No of litre Diesel Annual', 6, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (117, N'q481_enterDistance481', N'No of litre Diesel Annual By Months', 5, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (118, N'q414_enterMonthly414', N'Amount spent on Petrol', 4, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (119, N'q491_enterPassenger491', N'Amount spent on Petrol', 6, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (120, N'q482_enterDistance482', N'Amount spent on Petrol', 5, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (121, N'q529_enterMonthly529', N'Amount spent on Diesel', 4, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (122, N'q530_enterAnnual530', N'Amount spent on Diesel', 6, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (123, N'q531_enterAnnual531', N'Amount spent on Diesel', 5, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (124, N'q534_enterMonthly534', N'Amount spent on other fuel', 4, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (125, N'q535_enterAnnual535', N'Amount spent on other fuel', 6, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (126, N'q536_enterAnnual536', N'Amount spent on other fuel', 5, NULL, 5, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (127, N'q96_eId', NULL, 1, NULL, 6, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (128, N'q3_yourName', N'user name', NULL, NULL, 6, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (129, N'q4_email', N'user email', NULL, NULL, 6, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (130, N'q10_travel', N'Travel data', 6, NULL, 6, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (131, N'q17_hotels', N'Hotel data', 6, NULL, 6, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (132, N'q112_noofemailsent', N'Emails sent', 13, NULL, 6, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (133, N'q113_noofpagesprinted', N'Pages printed', 13, NULL, 6, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (134, N'q379_pleaseEnter', N'Customer Reference', 1, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (135, N'q532_optinPreference', N'Optin Preference', 3, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (138, N'q470_howWould470', N'Reporting Frequency', NULL, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (140, N'q471_reportingFrequency', N'Reporting Frequency Id', 2, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (141, N'q473_selectA', N'Select month', 7, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (142, N'q350_howWould350', N'Distance travelled', NULL, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (143, N'q351_whichUnit351', N'Regular Taxi Data Unit ', 9, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (144, N'q130_enterMonthly130', N'Regular Taxi Monthly Input', 4, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q351_whichUnit351", "questionTypeId": 9},{"reference": "q535_conversionFactor535", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (150, N'q341_howWould', N'How would you like to provide the information for Passenger Cars?', NULL, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (152, N'q85_enterMonthly', N'Passenger Car Petrol - Monthly', 4, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q342_whichUnit342", "questionTypeId": 9},{"reference": "q533_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (159, N'q484_enterAnnual', N'passenger Car Petrol - Annually', 6, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q342_whichUnit342", "questionTypeId": 9},{"reference": "q533_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (161, N'q472_enterAnnual472', N'Passenger Car Petrol -AnnualByMonth', 5, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q342_whichUnit342", "questionTypeId": 9},{"reference": "q533_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (163, N'q110_travelUnits110', N'Passenger Car - Diesel_ Monthly', 4, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q342_whichUnit342", "questionTypeId": 9},{"reference": "q533_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (164, N'q485_enterAnnual485', N'Passenger Car - Diesel_Annualy', 6, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q342_whichUnit342", "questionTypeId": 9},{"reference": "q533_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (168, N'q474_enterDistance474', N'Passenger Car - Diesel_AnnualyByMonth', 5, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q342_whichUnit342", "questionTypeId": 9},{"reference": "q533_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (171, N'q159_enterMonthly159', N'Passenger Car - Hybrid_Monthly', 4, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q342_whichUnit342", "questionTypeId": 9},{"reference": "q533_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (172, N'q486_enterAnnual486', N'Passenger Car -  Hybrid_Annual', 6, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q342_whichUnit342", "questionTypeId": 9},{"reference": "q533_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (173, N'q475_enterDistance475', N'Passenger Car -Hybrid_AnnualByMonth', 5, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q342_whichUnit342", "questionTypeId": 9},{"reference": "q533_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (174, N'q181_enterMonthly181', N'Passenger Car - Electric_Monthly', 4, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q342_whichUnit342", "questionTypeId": 9},{"reference": "q533_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (175, N'q487_enterAnnual487', N'Passenger Car - Electric_Annual', 6, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q342_whichUnit342", "questionTypeId": 9},{"reference": "q533_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (176, N'q477_enterDistance477', N'Passenger Car - Electric_AnnualByMonth', 5, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q342_whichUnit342", "questionTypeId": 9},{"reference": "q533_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (177, N'q222_enterMonthly222', N'Motorbike_Monthly', 4, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q342_whichUnit342", "questionTypeId": 9},{"reference": "q533_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (178, N'q488_enterAnnual488', N'Motorbike_Annual', 6, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q342_whichUnit342", "questionTypeId": 9},{"reference": "q533_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (179, N'q479_enterDistance479', N'Motorbike_AnnualByMonth', 5, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q342_whichUnit342", "questionTypeId": 9},{"reference": "q533_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (180, N'q391_enterMonthly391', N'Passenger Car - Petrol (no of litre)_Monthly', 4, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (181, N'q489_passengerCar489', N'Passenger Car - Petrol (no of litre)_Annual', 6, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (182, N'q480_enterDistance480', N'Passenger Car - Petrol (no of litre)_AnnualByMonth', 5, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (183, N'q407_enterMonthly407', N'Passenger Car - Diesel (no of litre) - Monthly', 4, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (184, N'q490_enterAnnual490', N'Passenger Car - Diesel (no of litre) - Annual', 6, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (185, N'q481_enterDistance481', N'Passenger Car - Diesel (no of litre) - AnnualByMonth', 5, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (186, N'q414_enterMonthly414', N'Passenger Car (Amount spend) - monthly', 4, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (188, N'q491_enterPassenger491', N'Passenger Car (Amount spend) - Annual', 6, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (190, N'q482_enterDistance482', N'Passenger Car (Amount spend) - AnnualByMonth', 5, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (191, N'q254_enterMonthly254', N'Train - Monthly', 4, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q347_whichUnit347", "questionTypeId": 9},{"reference": "q534_conversionFactor534", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (193, N'q492_enterAnnual492', N'Train - Annual', 6, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q347_whichUnit347", "questionTypeId": 9},{"reference": "q534_conversionFactor534", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (194, N'q483_enterDistance483', N'Train - AnnualByMonth', 5, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q347_whichUnit347", "questionTypeId": 9},{"reference": "q534_conversionFactor534", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (197, N'q422_enterMonthly422', N'Train (Amount spend) - Monthly', 4, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (198, N'q515_enterTrain515', N'Train (Amount spend) - Annual', 6, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (199, N'q493_enterDistance493', N'Train (Amount spend) - AnnualByMonth', 5, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (200, N'q516_enterAnnual516', N'Taxi - Annual', 6, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q351_whichUnit351", "questionTypeId": 9},{"reference": "q535_conversionFactor535", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (201, N'q494_enterDistance494', N'Taxi - AnnualByMonth', 5, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q351_whichUnit351", "questionTypeId": 9},{"reference": "q535_conversionFactor535", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (202, N'q430_trainUnits430', N'Taxi (Amount spend) - Monthly', 4, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (203, N'q517_enterTaxi517', N'Taxi (Amount spend) - Annual', 6, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (204, N'q495_enterDistance495', N'Taxi (Amount spend) - AnnualByMonth', 5, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (205, N'q139_travelUnits139', N'Local Bus - Monthly', 4, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q355_whichUnit355", "questionTypeId": 9},{"reference": "q536_conversionFactor536", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (206, N'q518_enterAnnual518', N'Local Bus - Annual', 6, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q355_whichUnit355", "questionTypeId": 9},{"reference": "q536_conversionFactor536", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (207, N'q496_enterDistance496', N'Local Bus - AnnualByMonth', 5, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q355_whichUnit355", "questionTypeId": 9},{"reference": "q536_conversionFactor536", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (209, N'q147_travelUnits147', N'Coach Bus - Monthly', 4, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q355_whichUnit355", "questionTypeId": 9},{"reference": "q536_conversionFactor536", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (210, N'q519_enterAnnual519', N'Coach Bus - Annual', 6, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q355_whichUnit355", "questionTypeId": 9},{"reference": "q536_conversionFactor536", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (212, N'q497_enterDistance497', N'Coach Bus - AnnualByMonth', 5, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q355_whichUnit355", "questionTypeId": 9},{"reference": "q536_conversionFactor536", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (213, N'q438_enterMonthly438', N'Bus (Amount spend) - Monthly', 4, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (214, N'q520_enterAnnual520', N'Bus (Amount spend) - Annual', 6, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (215, N'q498_enterDistance498', N'Bus (Amount spend) - AnnualByMonth', 5, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (216, N'q283_travelUnits283', N'Domestic Flights - Monthly', 4, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q359_whichUnit359", "questionTypeId": 9},{"reference": "q537_conversionFactor537", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (218, N'q521_enterAnnual521', N'Domestic Flights - Annual', 6, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q359_whichUnit359", "questionTypeId": 9},{"reference": "q537_conversionFactor537", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (219, N'q499_enterDistance499', N'Domestic Flights - Annual', 5, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q359_whichUnit359", "questionTypeId": 9},{"reference": "q537_conversionFactor537", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (220, N'q291_travelUnits291', N'Short-Haul Flights - Month', 4, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q359_whichUnit359", "questionTypeId": 9},{"reference": "q537_conversionFactor537", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (222, N'q522_enterAnnual522', N'Short-Haul Flights - Annual', 6, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q359_whichUnit359", "questionTypeId": 9},{"reference": "q537_conversionFactor537", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (223, N'q500_enterDistance500', N'Short-Haul Flights - AnnualByMonth', 5, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q359_whichUnit359", "questionTypeId": 9},{"reference": "q537_conversionFactor537", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (225, N'q315_travelUnits315', N'Long-Haul Flights - Month', 4, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q359_whichUnit359", "questionTypeId": 9},{"reference": "q537_conversionFactor537", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (226, N'q523_enterAnnual523', N'Long-Haul Flights  - Annualy', 6, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q359_whichUnit359", "questionTypeId": 9},{"reference": "q537_conversionFactor537", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (227, N'q501_enterDistance501', N'Long-Haul Flights  - AnnualyByMonth', 5, NULL, 7, NULL, N'{"linkedQuestions": [{"reference": "q359_whichUnit359", "questionTypeId": 9},{"reference": "q537_conversionFactor537", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (228, N'q446_enterMonthly446', N'Flight (Amount spend) - Monthly', 4, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (229, N'q524_enterAnnual524', N'Flight (Amount spend) - Annualy', 6, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (230, N'q507_enterDistance507', N'Flight (Amount spend) - AnnualyByMonth', 5, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (231, N'q368_enterMonthly368', N'Hotel  - Monthly', 4, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (232, N'q528_enterAnnual528', N'Hotel - Annual', 6, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (233, N'q511_enterDistance511', N'Hotel - AnnualByMonth', 5, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (234, N'q454_enterMonthly454', N'Hotel (Amount spend) - Monthly', 4, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (235, N'q527_enterAnnual527', N'Hotel (Amount spend) - Annualy', 6, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (236, N'q513_enterDistance513', N'Hotel (Amount spend) - AnnualyByMont', 5, NULL, 7, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (237, N'q9_customerId', NULL, 1, NULL, 8, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (238, N'q49_enterThe', N'Construction Waste - AnnualByMonth', 5, NULL, 8, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (239, N'q50_enterThe', N'Construction Waste - Annual', 6, NULL, 8, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (240, N'q67_monthly', N'Construction Waste - Month', 4, NULL, 8, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (241, N'q77_monthlyData77', N'Landfill - AnnualByMonth - JAN_JUN', 11, NULL, 8, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (242, N'q79_enterWaste', N'Landfill - AnnualByMonth - JUL_DEC', 12, NULL, 8, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (243, N'q129_reportingFrequency', NULL, 2, NULL, 8, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (245, N'q132_managementbaseddecision', NULL, 8, NULL, 8, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (246, N'q74_enterAnnual', N'Landfill - Annual', 6, NULL, 8, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (247, N'q76_enterData', N'Landfill - Month', 4, NULL, 8, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (248, N'q4_typeA', N'General Recycling - AnnualByMonth', 5, NULL, 8, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (249, N'q6_typeA6', N'General Recycling - Annual', 6, NULL, 8, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (250, N'q65_typeA65', N'General Recycling - Monthly', 4, NULL, 8, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (251, N'q9_customerId', NULL, 1, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (254, N'q317_reportingFrequency317', NULL, 2, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (255, N'q318_totalHousing318', NULL, 3, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (256, N'q319_totalHousing319', NULL, 8, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (257, N'q320_totalHousing320', NULL, 10, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (258, N'q6_typeA6', N'Agriculture - month', 4, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (259, N'q290_enterAnnual290', N'Agriculture -Annual', 6, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (260, N'q271_enterAnnual271', N'Agriculture -AnnualByMonth', 5, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (261, N'q72_typeA', N'Energy  and Extractive Industries - Month', 4, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (262, N'q291_enterAnnual291', N'Energy  and Extractive Industries - Annual', 6, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (263, N'q272_enterAnnual272', N'Energy  and Extractive Industries - AnnualByMonth', 5, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (264, N'q80_enterMonthly', N'Utilities - Month', 4, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (266, N'q292_enterAnnual292', N'Utilities - Annual', 6, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (267, N'q273_enterAnnual273', N'Utilities - AnnualBymonth', 5, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (268, N'q112_inputTable112', N'Construction - Month', 4, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (269, N'q293_enterAnnual293', N'Construction - Annual', 6, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (270, N'q274_enterAnnual274', N'Construction - AnnualByMonth', 5, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (271, N'q115_manufacturing115', N'Wholesale and Retail Trade - Month', 4, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (272, N'q294_enterAnnual294', N'Wholesale and Retail Trade - Annual', 6, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (275, N'q267_enterThe267', N'Wholesale and Retail Trade - AnnualByMonth - JAN_JUN', 11, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (276, N'q269_enterThe269', N'Wholesale and Retail Trade - AnnualByMonth - JUL_DEC', 12, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (277, N'q124_inputTable124', N'Transportation and Warehousing - Monthly', 4, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (278, N'q295_enterAnnual295', N'Transportation and Warehousing - Annual', 6, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (279, N'q275_enterUtilities275', N'Transportation and Warehousing - AnnualByMonth JAN_JUN', 11, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (280, N'q286_enterThe', N'Transportation and Warehousing - AnnualByMonth JUL_DEC', 12, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (281, N'q130_inputTable130', N'Publishing, Media, and Telecommunications - Monthly', 4, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (283, N'q296_enterAnnual296', N'Publishing, Media, and Telecommunications - Annual', 6, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (284, N'q276_enterAnnual276', N'Publishing, Media, and Telecommunications - AnnualByMonth', 5, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (285, N'q133_inputTable133', N'Information Services - Monthly', 4, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (286, N'q297_enterAnnual297', N'Information Services - Annaul', 6, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (287, N'q277_enterConstruction277', N'Information Services - AnnaulByMonth', 5, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (288, N'q157_inputTable157', N'Financial Services - Monthly', 4, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (289, N'q298_enterAnnual298', N'Financial Services - Annual', 6, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (290, N'q278_enterConstruction278', N'Financial Services - AnnualByMonth', 5, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (291, N'q136_inputTable136', N'Rental and Leasing - Monthly', 4, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (292, N'q299_enterAnnual299', N'Rental and Leasing - Annual', 6, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (293, N'q279_enterConstruction279', N'Rental and Leasing - AnnualBymonth', 5, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (294, N'q139_inputTable139', N'Professional and Business Services - Month', 4, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (295, N'q300_enterAnnual300', N'Professional and Business Services - Annual', 6, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (296, N'enterConstruction280', N'Professional and Business Services - AnnualByMonth', 5, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (297, N'q142_inputTable142', N'Waste & Environmental Services - Month', 4, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (298, N'q301_enterAnnual301', N'Waste & Environmental Services - Annual', 6, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (299, N'q281_enterConstruction281', N'Waste & Environmental Services - AnnualByMonth', 5, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (300, N'q145_inputTable145', N'Education and Healthcare - Month', 4, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (304, N'q302_enterAnnual302', N'Education and Healthcare - Annual', 6, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (305, N'q282_enterConstruction282', N'Education and Healthcare - AnnaulByMonth', 5, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (306, N'q148_inputTable148', N'Arts, Entertainment, and Recreation - Month', 4, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (307, N'q303_enterAnnual303', N'Arts, Entertainment, and Recreation - Annual', 6, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (309, N'q283_enterConstruction283', N'Arts, Entertainment, and Recreation - AnnualByMonth', 5, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (310, N'q151_enterThe151', N'Accommodation - Month', 4, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (311, N'q304_enterAnnual304', N'Accommodation - Annual', 6, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (312, N'q284_enterConstruction284', N'Accommodation - AnnualByMonth', 5, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (313, N'q154_enterThe154', N' Real Estate - Month', 4, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (314, N'q305_enterAnnual305', N' Real Estate - Annual', 6, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (315, N'q285_enterConstruction285', N' Real Estate - AnnualByMonth', 5, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (316, N'q310_enterMonthly310', N'Manufacturing - Month', 4, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (317, N'q311_enterAnnual', N'Manufacturing - Annual', 6, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (319, N'q314_enterThe314', N'Manufacturing - AnnualByMonth JAN_JUN', 11, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (320, N'q316_enterThe316', N'Manufacturing - AnnualByMonth JUL_DEC', 12, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (321, N'q321_typeA321', N'spend - Data Unit', 9, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (322, N'q265_selectA', NULL, 7, NULL, 9, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (323, N'q9_customerId', NULL, 1, NULL, 10, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (325, N'q261_selectA', NULL, 7, NULL, 10, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (327, N'q293_totalCoal293', N'', 2, NULL, 10, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (328, N'q294_optinPreference', NULL, 3, NULL, 10, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (329, N'q296_reportingFrequency296', NULL, 10, NULL, 10, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (330, N'q54_pleaseEnter', N'Gaseous fuels - Monthly', 4, NULL, 10, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (331, N'q246_pleaseEnter246', N'Gaseous fuels - Annual', 6, NULL, 10, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (332, N'q247_pleaseEnter247', N'Gaseous fuels - AnnualByMonth JAN_JUN', 11, NULL, 10, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (333, N'q248_pleaseEnter248', N'Gaseous fuels - AnnualByMonth JUL_DEC', 12, NULL, 10, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (334, N'q128_pleaseEnter128', N'Liquid fuels - Monthly', 4, NULL, 10, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (335, N'q251_pleaseEnter251', N'Liquid fuels - Annual', 6, NULL, 10, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (336, N'q252_pleaseEnter252', N'Liquid fuels - JAN_JUN', 11, NULL, 10, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (337, N'q253_pleaseEnter253', N'Liquid fuels - JUL_DEC', 12, NULL, 10, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (339, N'q211_typeA211', N'Solid fuels - Monthly', 4, NULL, 10, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (340, N'q256_pleaseEnter256', N'Solid fuels - Annual', 6, NULL, 10, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (341, N'q257_pleaseEnter257', N'Solid fuels - JAN_JUN', 11, NULL, 10, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (342, N'q258_pleaseEnter258', N'Solid fuels - JUL_DEC', 12, NULL, 10, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (344, N'q297_dataunit', N'Data Unit', 9, NULL, 10, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (345, N'q138_selectMonth', N'Month', 7, NULL, 8, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (346, N'q136_typeA136', N'Data Unit', 9, NULL, 8, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (347, N'q283_name', N'Name', NULL, NULL, 11, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (348, N'q284_workEmail', N'Email', NULL, NULL, 11, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (349, N'q9_cId', N'Customer Reference', 1, NULL, 11, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (350, N'q247_doYou247', N'Do you commute to work, work from home, or a bit of both? Please select one or both options as applicable', NULL, NULL, 11, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (351, N'q172_typeA172', N'How do you commute to your workplace? (Chose more than one if required)', NULL, NULL, 11, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (352, N'q84_calculation', N'Small Petrol car total Kms', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q74_typeOf", "questionTypeId": 9}, {"reference": "q459_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (353, N'q92_smallCar92', N'Medium Petrol car total Kms', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q74_typeOf", "questionTypeId": 9}, {"reference": "q459_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (354, N'q96_largeCar', N'Large Petrol car total kms', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q74_typeOf", "questionTypeId": 9}, {"reference": "q459_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (356, N'q108_smallCar108', N'Small diesel car total kms', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q74_typeOf", "questionTypeId": 9}, {"reference": "q459_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (357, N'q112_mediumCar112', N'Medium diesel car total kms', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q74_typeOf", "questionTypeId": 9}, {"reference": "q459_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (358, N'q116_largeCar116', N'Large diesel car total kms', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q74_typeOf", "questionTypeId": 9}, {"reference": "q459_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (359, N'q128_smallCar128', N'Small Hybrid car total kms', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q74_typeOf", "questionTypeId": 9}, {"reference": "q459_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (360, N'q132_mediumCar132', N'Medium Hybrid car total kms', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q74_typeOf", "questionTypeId": 9}, {"reference": "q459_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (361, N'q136_largeCar136', N'Large Hybrid car total kms', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q74_typeOf", "questionTypeId": 9}, {"reference": "q459_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (362, N'q148_smallCar148', N'Small Electric car total kms', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q74_typeOf", "questionTypeId": 9}, {"reference": "q459_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (363, N'q160_mediumCar160', N'Medium Electric car total kms', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q74_typeOf", "questionTypeId": 9}, {"reference": "q459_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (364, N'q166_largeCar166', N'Large Electric car total kms', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q74_typeOf", "questionTypeId": 9}, {"reference": "q459_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (365, N'q322_smallCar322', N'Small car Plug In Ele Total Kms', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q74_typeOf", "questionTypeId": 9}, {"reference": "q459_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (366, N'q328_mediumCar328', N'Med car Plug In Ele Total Kms', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q74_typeOf", "questionTypeId": 9}, {"reference": "q459_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (367, N'q334_largeCar334', N'Large car Plug In Ele Total Kms', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q74_typeOf", "questionTypeId": 9}, {"reference": "q459_conversionFactor", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (368, N'q185_nationalRail185', N'National rail', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q174_whichUnit", "questionTypeId": 9}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (369, N'q193_lightRail193', N'Metro and/or tram', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q174_whichUnit", "questionTypeId": 9}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (370, N'q198_londonUnderground198', N'Underground', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q174_whichUnit", "questionTypeId": 9}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (371, N'q214_regularTaxi214', N'Regular taxi', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q203_whichUnit203", "questionTypeId": 9}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (372, N'q225_localBus225', N'Local Bus', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q220_whichUnit220", "questionTypeId": 9}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (373, N'q275_totalCycling', N'Cycling', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q273_whichUnit273", "questionTypeId": 9}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (374, N'q279_totalWalking', N'Walking', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q277_whichUnit277", "questionTypeId": 9}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (375, N'q441_petrolVan', N'Petrol Van Class I Total Kms', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q376_whichUnit376", "questionTypeId": 9},{"reference": "q468_conversionFactor468", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (376, N'q442_petrolVan442', N'Petrol Van Class II Total Kms', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q376_whichUnit376", "questionTypeId": 9},{"reference": "q468_conversionFactor468", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (377, N'q443_petrolVan443', N'Petrol Van Class III Total Kms', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q376_whichUnit376", "questionTypeId": 9},{"reference": "q468_conversionFactor468", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (378, N'q444_dieselVan', N'Diesel Van Class I Total Kms', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q376_whichUnit376", "questionTypeId": 9},{"reference": "q468_conversionFactor468", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (379, N'q445_dieselVan445', N'Diesel Van Class II Total Kms', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q376_whichUnit376", "questionTypeId": 9},{"reference": "q468_conversionFactor468", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (380, N'q446_dieselVan446', N'Diesel Van Class III Total Kms', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q376_whichUnit376", "questionTypeId": 9},{"reference": "q468_conversionFactor468", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (381, N'q447_electricVan', N'Electric Van Class I Total Kms', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q376_whichUnit376", "questionTypeId": 9},{"reference": "q468_conversionFactor468", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (382, N'q448_electricVan448', N'Electric Van Class II Total Kms', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q376_whichUnit376", "questionTypeId": 9},{"reference": "q468_conversionFactor468", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (383, N'q449_electricVan449', N'Electric Van Class III Total Kms', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q376_whichUnit376", "questionTypeId": 9},{"reference": "q468_conversionFactor468", "questionTypeId": 10}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (384, N'q450_electricityTotal', N'Electricity Total', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q452_dataUnit", "questionTypeId": 9}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (385, N'q451_gasTotal', N'Gas Total', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q452_dataUnit", "questionTypeId": 9}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (386, N'q9_customerId', N'Customer Reference', 1, NULL, 12, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (387, N'q329_optinPreference', N'OptIn Preference', 3, NULL, 12, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (388, N'q262_totalOf', N'Total of Vans', 13, NULL, 12, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (389, N'q308_totalOf308', N'Total of Truck', 13, NULL, 12, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (390, N'q276_totalOf276', N'Total of Rail', 13, NULL, 12, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (392, N'q270_totalOf270', N'Total of Short Haul', 13, NULL, 12, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (393, N'q314_totalOf314', N'Total of Long Haul', 13, NULL, 12, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (394, N'q298_totalCoal298', N'Total of Cargo Sea Freight', 13, NULL, 12, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (395, N'q9_customerId', N'Customer Reference', 1, NULL, 13, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (396, N'q328_optinPreference', N'OptIn Preference', 3, NULL, 13, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (397, N'q262_totalOf', N'Total of Vans', 13, NULL, 13, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (398, N'q308_totalOf308', N'Total of Truck', 13, NULL, 13, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (399, N'q276_totalOf276', N'Total of Rail', 13, NULL, 13, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (400, N'q270_totalOf270', N'Total of Short Haul', 13, NULL, 13, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (401, N'q314_totalOf314', N'Total of Long Haul', 13, NULL, 13, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (402, N'q298_totalCoal298', N'Total of Cargo Sea Freight', 13, NULL, 13, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (403, N'q326_typeA326', N'Itemised Entries', 14, NULL, 13, NULL, N'{"vehicleEmissions": [{ "type": "Van", "emissionActivityId": 360 },{ "type": "Truck", "emissionActivityId": 361 },{ "type": "Rail", "emissionActivityId": 362 },{ "type": "Short Haul", "emissionActivityId": 363 },{ "type": "Long Haul", "emissionActivityId": 364 },{ "type": "Cargo", "emissionActivityId": 365 }]}
', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (404, N'q326_typeA326', N'Itemised Entries', 14, NULL, 12, N'', N'{"vehicleEmissions": [{ "type": "Van", "emissionActivityId": 360 },{ "type": "Truck", "emissionActivityId": 361 },{ "type": "Rail", "emissionActivityId": 362 },{ "type": "Short Haul", "emissionActivityId": 363 },{ "type": "Long Haul", "emissionActivityId": 364 },{ "type": "Cargo", "emissionActivityId": 365 }]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (411, N'q460_howMany460', N'How many days a week do you work at office?', NULL, NULL, 11, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (412, N'q461_howMany461', N'How many hours a day do you work when at office?', NULL, NULL, 11, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (413, N'q465_oilTotal', N'Oil heating total hours', 13, NULL, 11, NULL, N'{"linkedQuestions": [{"reference": "q452_dataUnit", "questionTypeId": 9}]}', 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (414, N'q54_email', NULL, 15, NULL, 1, NULL, NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (415, N'q49_email', N'', 15, NULL, 2, N'', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (416, N'q80_email', N'', 15, NULL, 3, N'', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (417, N'q493_email', N'', 15, NULL, 4, N'', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (418, N'q588_email', N'', 15, NULL, 5, N'', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (419, N'q538_email', N'', 15, NULL, 7, N'', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (420, N'q140_email', N'', 15, NULL, 8, N'', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (421, N'q322_email', N'', 15, NULL, 9, N'', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (422, N'q299_email', N'', 15, NULL, 10, N'', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (423, N'q331_email', N'', 15, NULL, 12, N'', NULL, 1)
GO
INSERT [Forms].[Question] ([id], [reference], [displayText], [questionTypeId], [inputTypeId], [formId], [dataType], [properties], [active]) VALUES (424, N'q330_email', N'', 15, NULL, 13, N'', NULL, 1)
GO
SET IDENTITY_INSERT [Forms].[Question] OFF
GO
SET IDENTITY_INSERT [Forms].[QuestionEmissionActivity] ON 
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1, 52, 4, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (2, 52, 5, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (3, 52, 6, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (4, 52, 7, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (5, 52, 8, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (6, 52, 9, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (7, 52, 10, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (8, 52, 11, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (9, 52, 12, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (10, 52, 13, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (11, 52, 14, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (12, 52, 15, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (13, 52, 16, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (14, 52, 17, 13, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (15, 52, 18, 14, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (16, 52, 19, 15, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (17, 52, 20, 16, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (18, 52, 21, 17, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (19, 52, 22, 18, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (20, 52, 23, 19, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (21, 52, 24, 20, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (22, 52, 25, 21, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (23, 52, 26, 22, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (24, 52, 27, 23, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (25, 52, 28, 24, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (26, 52, 29, 25, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (27, 52, 30, 26, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (28, 52, 31, 27, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (29, 52, 32, 28, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (30, 52, 33, 29, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (31, 52, 34, 30, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (32, 52, 35, 31, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (33, 52, 36, 32, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (34, 54, 4, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (35, 54, 5, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (36, 54, 6, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (37, 54, 7, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (38, 54, 8, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (39, 54, 9, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (40, 54, 10, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (41, 54, 11, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (42, 54, 12, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (43, 54, 13, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (44, 54, 14, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (45, 54, 15, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (46, 54, 16, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (47, 54, 17, 13, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (48, 54, 18, 14, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (49, 54, 19, 15, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (50, 54, 20, 16, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (51, 54, 21, 17, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (52, 54, 22, 18, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (53, 54, 23, 19, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (54, 54, 24, 20, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (55, 54, 25, 21, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (56, 54, 26, 22, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (57, 54, 27, 23, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (58, 54, 28, 24, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (59, 54, 29, 25, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (60, 54, 30, 26, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (61, 54, 31, 27, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (62, 54, 32, 28, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (63, 54, 33, 29, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (64, 54, 34, 30, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (65, 54, 35, 31, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (66, 54, 36, 32, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (67, 55, 4, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (68, 55, 5, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (69, 55, 6, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (70, 55, 7, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (71, 55, 8, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (72, 55, 9, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (73, 55, 10, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (74, 55, 11, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (75, 55, 12, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (76, 55, 13, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (77, 55, 14, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (78, 55, 15, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (79, 55, 16, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (80, 55, 17, 13, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (81, 55, 18, 14, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (82, 55, 19, 15, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (83, 55, 20, 16, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (84, 55, 21, 17, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (85, 55, 22, 18, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (86, 55, 23, 19, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (87, 55, 24, 20, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (88, 55, 25, 21, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (89, 55, 26, 22, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (90, 55, 27, 23, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (91, 55, 28, 24, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (92, 55, 29, 25, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (93, 55, 30, 26, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (94, 55, 31, 27, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (95, 55, 32, 28, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (96, 55, 33, 29, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (97, 55, 34, 30, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (98, 55, 35, 31, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (99, 55, 36, 32, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (100, 56, 4, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (101, 56, 5, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (102, 56, 6, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (103, 56, 7, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (104, 56, 8, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (105, 56, 9, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (106, 56, 10, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (107, 56, 11, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (108, 56, 12, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (109, 56, 13, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (110, 56, 14, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (111, 56, 15, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (112, 56, 16, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (113, 56, 17, 13, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (114, 56, 18, 14, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (115, 56, 19, 15, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (116, 56, 20, 16, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (117, 56, 21, 17, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (118, 56, 22, 18, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (119, 56, 23, 19, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (120, 56, 24, 20, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (121, 56, 25, 21, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (122, 56, 26, 22, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (123, 56, 27, 23, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (124, 56, 28, 24, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (125, 56, 29, 25, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (126, 56, 30, 26, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (127, 56, 31, 27, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (128, 56, 32, 28, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (129, 56, 33, 29, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (130, 56, 34, 30, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (131, 56, 35, 31, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (132, 56, 36, 32, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (133, 57, 37, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (134, 57, 38, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (135, 57, 39, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (136, 57, 40, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (137, 57, 41, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (138, 57, 42, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (139, 57, 43, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (140, 57, 44, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (141, 57, 45, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (142, 57, 46, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (143, 57, 47, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (144, 57, 48, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (145, 57, 49, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (146, 57, 50, 13, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (147, 57, 51, 14, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (148, 57, 52, 15, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (149, 57, 53, 16, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (150, 57, 54, 17, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (151, 57, 55, 18, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (152, 57, 56, 19, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (153, 57, 57, 20, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (154, 57, 58, 21, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (155, 57, 59, 22, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (156, 57, 60, 23, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (157, 57, 61, 24, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (158, 57, 62, 25, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (159, 57, 63, 26, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (160, 57, 64, 27, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (161, 57, 65, 28, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (162, 57, 66, 29, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (163, 57, 67, 30, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (164, 57, 68, 31, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (165, 57, 69, 32, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (166, 57, 70, 33, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (167, 57, 71, 34, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (168, 57, 72, 35, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (169, 57, 73, 36, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (170, 57, 74, 37, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (171, 57, 75, 38, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (172, 57, 76, 39, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (173, 57, 77, 40, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (174, 57, 78, 41, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (175, 57, 79, 42, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (176, 57, 80, 43, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (177, 57, 81, 44, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (178, 57, 82, 45, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (179, 57, 83, 46, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (180, 57, 84, 47, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (181, 57, 85, 48, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (182, 57, 86, 49, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (183, 57, 87, 50, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (184, 57, 88, 51, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (185, 57, 89, 52, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (186, 57, 90, 53, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (187, 57, 91, 54, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (188, 57, 92, 55, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (189, 57, 93, 56, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (190, 57, 94, 57, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (191, 57, 95, 58, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (192, 57, 96, 59, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (193, 57, 97, 60, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (194, 57, 98, 61, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (195, 57, 99, 62, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (196, 57, 100, 63, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (197, 57, 101, 64, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (198, 57, 102, 65, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (199, 57, 103, 66, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (200, 57, 104, 67, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (201, 57, 105, 68, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (202, 57, 106, 69, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (203, 57, 107, 70, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (204, 57, 108, 71, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (205, 57, 109, 72, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (206, 57, 110, 73, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (207, 57, 111, 74, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (208, 57, 112, 75, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (209, 57, 113, 76, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (210, 57, 114, 77, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (211, 57, 115, 78, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (212, 57, 116, 79, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (213, 57, 117, 80, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (214, 57, 118, 81, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (215, 58, 37, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (216, 58, 38, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (217, 58, 39, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (218, 58, 40, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (219, 58, 41, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (220, 58, 42, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (221, 58, 43, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (222, 58, 44, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (223, 58, 45, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (224, 58, 46, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (225, 58, 47, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (226, 58, 48, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (227, 58, 49, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (228, 58, 50, 13, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (229, 58, 51, 14, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (230, 58, 52, 15, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (231, 58, 53, 16, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (232, 58, 54, 17, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (233, 58, 55, 18, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (234, 58, 56, 19, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (235, 58, 57, 20, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (236, 58, 58, 21, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (237, 58, 59, 22, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (238, 58, 60, 23, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (239, 58, 61, 24, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (240, 58, 62, 25, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (241, 58, 63, 26, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (242, 58, 64, 27, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (243, 58, 65, 28, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (244, 58, 66, 29, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (245, 58, 67, 30, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (246, 58, 68, 31, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (247, 58, 69, 32, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (248, 58, 70, 33, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (249, 58, 71, 34, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (250, 58, 72, 35, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (251, 58, 73, 36, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (252, 58, 74, 37, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (253, 58, 75, 38, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (254, 58, 76, 39, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (255, 58, 77, 40, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (256, 58, 78, 41, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (257, 58, 79, 42, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (258, 58, 80, 43, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (259, 58, 81, 44, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (260, 58, 82, 45, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (261, 58, 83, 46, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (262, 58, 84, 47, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (263, 58, 85, 48, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (264, 58, 86, 49, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (265, 58, 87, 50, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (266, 58, 88, 51, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (267, 58, 89, 52, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (268, 58, 90, 53, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (269, 58, 91, 54, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (270, 58, 92, 55, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (271, 58, 93, 56, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (272, 58, 94, 57, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (273, 58, 95, 58, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (274, 58, 96, 59, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (275, 58, 97, 60, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (276, 58, 98, 61, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (277, 58, 99, 62, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (278, 58, 100, 63, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (279, 58, 101, 64, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (280, 58, 102, 65, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (281, 58, 103, 66, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (282, 58, 104, 67, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (283, 58, 105, 68, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (284, 58, 106, 69, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (285, 58, 107, 70, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (286, 58, 108, 71, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (287, 58, 109, 72, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (288, 58, 110, 73, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (289, 58, 111, 74, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (290, 58, 112, 75, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (291, 58, 113, 76, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (292, 58, 114, 77, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (293, 58, 115, 78, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (294, 58, 116, 79, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (295, 58, 117, 80, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (296, 58, 118, 81, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (297, 58, 119, 82, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (298, 58, 120, 83, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (299, 59, 37, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (300, 59, 38, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (301, 59, 39, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (302, 59, 40, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (303, 59, 41, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (304, 59, 42, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (305, 59, 43, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (306, 59, 44, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (307, 59, 45, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (308, 59, 46, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (309, 59, 47, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (310, 59, 48, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (311, 59, 49, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (312, 59, 50, 13, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (313, 59, 51, 14, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (314, 59, 52, 15, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (315, 59, 53, 16, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (316, 59, 54, 17, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (317, 59, 55, 18, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (318, 59, 56, 19, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (319, 59, 57, 20, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (320, 59, 58, 21, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (321, 59, 59, 22, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (322, 59, 60, 23, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (323, 59, 61, 24, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (324, 59, 62, 25, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (325, 59, 63, 26, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (326, 59, 64, 27, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (327, 59, 65, 28, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (328, 59, 66, 29, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (329, 59, 67, 30, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (330, 59, 68, 31, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (331, 59, 69, 32, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (332, 59, 70, 33, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (333, 59, 71, 34, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (334, 59, 72, 35, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (335, 59, 73, 36, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (336, 59, 74, 37, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (337, 59, 75, 38, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (338, 59, 76, 39, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (339, 59, 77, 40, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (340, 59, 78, 41, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (341, 59, 79, 42, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (342, 59, 80, 43, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (343, 59, 81, 44, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (344, 59, 82, 45, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (345, 59, 83, 46, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (346, 59, 84, 47, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (347, 59, 85, 48, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (348, 59, 86, 49, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (349, 59, 87, 50, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (350, 59, 88, 51, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (351, 59, 89, 52, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (352, 59, 90, 53, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (353, 59, 91, 54, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (354, 59, 92, 55, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (355, 59, 93, 56, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (356, 59, 94, 57, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (357, 59, 95, 58, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (358, 59, 96, 59, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (359, 59, 97, 60, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (360, 59, 98, 61, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (361, 59, 99, 62, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (362, 59, 100, 63, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (363, 59, 101, 64, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (364, 59, 102, 65, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (365, 59, 103, 66, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (366, 59, 104, 67, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (367, 59, 105, 68, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (368, 59, 106, 69, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (369, 59, 107, 70, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (370, 59, 108, 71, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (371, 59, 109, 72, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (372, 59, 110, 73, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (373, 59, 111, 74, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (374, 59, 112, 75, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (375, 59, 113, 76, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (376, 59, 114, 77, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (377, 59, 115, 78, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (378, 59, 116, 79, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (379, 59, 117, 80, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (380, 59, 118, 81, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (381, 59, 119, 82, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (382, 59, 120, 83, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (383, 60, 37, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (384, 60, 38, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (385, 60, 39, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (386, 60, 40, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (387, 60, 41, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (388, 60, 42, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (389, 60, 43, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (390, 60, 44, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (391, 60, 45, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (392, 60, 46, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (393, 60, 47, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (394, 60, 48, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (395, 60, 49, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (396, 60, 50, 13, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (397, 60, 51, 14, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (398, 60, 52, 15, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (399, 60, 53, 16, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (400, 60, 54, 17, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (401, 60, 55, 18, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (402, 60, 56, 19, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (403, 60, 57, 20, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (404, 60, 58, 21, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (405, 60, 59, 22, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (406, 60, 60, 23, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (407, 60, 61, 24, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (408, 60, 62, 25, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (409, 60, 63, 26, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (410, 60, 64, 27, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (411, 60, 65, 28, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (412, 60, 66, 29, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (413, 60, 67, 30, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (414, 60, 68, 31, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (415, 60, 69, 32, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (416, 60, 70, 33, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (417, 60, 71, 34, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (418, 60, 72, 35, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (419, 60, 73, 36, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (420, 60, 74, 37, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (421, 60, 75, 38, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (422, 60, 76, 39, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (423, 60, 77, 40, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (424, 60, 78, 41, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (425, 60, 79, 42, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (426, 60, 80, 43, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (427, 60, 81, 44, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (428, 60, 82, 45, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (429, 60, 83, 46, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (430, 60, 84, 47, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (431, 60, 85, 48, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (432, 60, 86, 49, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (433, 60, 87, 50, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (434, 60, 88, 51, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (435, 60, 89, 52, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (436, 60, 90, 53, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (437, 60, 91, 54, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (438, 60, 92, 55, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (439, 60, 93, 56, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (440, 60, 94, 57, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (441, 60, 95, 58, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (442, 60, 96, 59, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (443, 60, 97, 60, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (444, 60, 98, 61, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (445, 60, 99, 62, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (446, 60, 100, 63, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (447, 60, 101, 64, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (448, 60, 102, 65, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (449, 60, 103, 66, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (450, 60, 104, 67, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (451, 60, 105, 68, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (452, 60, 106, 69, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (453, 60, 107, 70, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (454, 60, 108, 71, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (455, 60, 109, 72, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (456, 60, 110, 73, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (457, 60, 111, 74, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (458, 60, 112, 75, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (459, 60, 113, 76, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (460, 60, 114, 77, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (461, 60, 115, 78, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (462, 60, 116, 79, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (463, 60, 117, 80, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (464, 60, 118, 81, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (465, 60, 119, 82, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (466, 60, 120, 83, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (467, 61, 121, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (468, 61, 122, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (469, 61, 123, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (470, 61, 124, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (471, 61, 125, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (472, 61, 126, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (473, 61, 127, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (474, 61, 128, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (475, 61, 129, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (476, 61, 130, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (477, 61, 131, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (478, 61, 132, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (479, 61, 133, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (480, 61, 134, 13, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (481, 61, 135, 14, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (482, 61, 136, 15, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (483, 61, 137, 16, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (484, 61, 138, 17, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (485, 61, 139, 18, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (486, 61, 140, 19, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (487, 62, 121, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (488, 62, 122, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (489, 62, 123, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (490, 62, 124, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (491, 62, 125, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (492, 62, 126, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (493, 62, 127, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (494, 62, 128, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (495, 62, 129, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (496, 62, 130, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (497, 62, 131, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (498, 62, 132, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (499, 62, 133, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (500, 62, 134, 13, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (501, 62, 135, 14, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (502, 62, 136, 15, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (503, 62, 137, 16, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (504, 62, 138, 17, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (505, 62, 139, 18, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (506, 62, 140, 19, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (507, 63, 121, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (508, 63, 122, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (509, 63, 123, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (510, 63, 124, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (511, 63, 125, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (512, 63, 126, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (513, 63, 127, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (514, 63, 128, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (515, 63, 129, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (516, 63, 130, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (517, 63, 131, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (518, 63, 132, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (519, 63, 133, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (520, 63, 134, 13, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (521, 63, 135, 14, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (522, 63, 136, 15, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (523, 63, 137, 16, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (524, 63, 138, 17, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (525, 63, 139, 18, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (526, 63, 140, 19, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (527, 64, 121, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (528, 64, 122, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (529, 64, 123, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (530, 64, 124, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (531, 64, 125, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (532, 64, 126, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (533, 64, 127, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (534, 64, 128, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (535, 64, 129, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (536, 64, 130, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (537, 64, 131, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (538, 64, 132, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (539, 64, 133, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (540, 64, 134, 13, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (541, 64, 135, 14, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (542, 64, 136, 15, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (543, 64, 137, 16, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (544, 64, 138, 17, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (545, 64, 139, 18, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (546, 64, 140, 19, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (547, 65, 141, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (548, 65, 142, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (549, 65, 143, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (550, 65, 144, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (551, 65, 145, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (552, 65, 146, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (553, 65, 147, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (554, 65, 148, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (555, 65, 149, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (556, 65, 150, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (557, 66, 141, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (558, 66, 142, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (559, 66, 143, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (560, 66, 144, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (561, 66, 145, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (562, 66, 146, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (563, 66, 147, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (564, 66, 148, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (565, 66, 149, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (566, 66, 150, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (567, 67, 141, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (568, 67, 142, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (569, 67, 143, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (570, 67, 144, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (571, 67, 145, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (572, 67, 146, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (573, 67, 147, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (574, 67, 148, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (575, 67, 149, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (576, 67, 150, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (577, 68, 141, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (578, 68, 142, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (579, 68, 143, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (580, 68, 144, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (581, 68, 145, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (582, 68, 146, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (583, 68, 147, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (584, 68, 148, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (585, 68, 149, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (586, 68, 150, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (587, 69, 156, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (588, 69, 157, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (589, 69, 158, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (590, 69, 159, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (591, 69, 160, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (592, 69, 161, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (593, 69, 162, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (594, 69, 163, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (595, 69, 164, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (596, 69, 165, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (597, 69, 166, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (598, 69, 167, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (599, 69, 168, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (600, 69, 169, 13, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (601, 70, 156, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (602, 70, 157, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (603, 70, 158, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (604, 70, 159, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (605, 70, 160, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (606, 70, 161, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (607, 70, 162, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (608, 70, 163, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (609, 70, 164, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (610, 70, 165, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (611, 70, 166, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (612, 70, 167, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (613, 70, 168, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (614, 70, 169, 13, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (615, 71, 156, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (616, 71, 157, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (617, 71, 158, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (618, 71, 159, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (619, 71, 160, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (620, 71, 161, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (621, 71, 162, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (622, 71, 163, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (623, 71, 164, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (624, 71, 165, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (625, 71, 166, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (626, 71, 167, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (627, 71, 168, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (628, 71, 169, 13, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (629, 72, 156, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (630, 72, 157, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (631, 72, 158, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (632, 72, 159, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (633, 72, 160, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (634, 72, 161, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (635, 72, 162, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (636, 72, 163, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (637, 72, 164, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (638, 72, 165, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (639, 72, 166, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (640, 72, 167, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (641, 72, 168, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (642, 72, 169, 13, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (643, 6, 1, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (644, 7, 1, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (645, 9, 1, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (646, 22, 2, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (647, 23, 2, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (648, 24, 2, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (649, 36, 3, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (650, 37, 3, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (651, 39, 3, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (652, 83, 170, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (653, 83, 171, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (654, 83, 172, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (655, 86, 173, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (656, 86, 174, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (657, 86, 175, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (658, 89, 176, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (659, 89, 177, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (660, 89, 178, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (661, 92, 179, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (662, 92, 180, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (663, 92, 181, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (664, 95, 182, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (665, 95, 183, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (666, 95, 184, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (667, 98, 185, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (668, 98, 186, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (669, 98, 187, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (670, 101, 188, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (671, 101, 189, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (672, 101, 190, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (673, 105, 192, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (674, 105, 193, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (675, 105, 194, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (676, 108, 195, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (677, 108, 196, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (678, 108, 197, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (679, 108, 198, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (680, 108, 199, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (681, 108, 200, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (682, 108, 201, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (683, 111, 202, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (684, 115, 203, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (685, 118, 204, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (686, 121, 205, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (687, 124, 206, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (688, 84, 170, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (689, 84, 171, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (690, 84, 172, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (691, 87, 173, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (692, 87, 174, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (693, 87, 175, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (694, 90, 176, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (695, 90, 177, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (696, 90, 178, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (697, 93, 179, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (698, 93, 180, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (699, 93, 181, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (700, 96, 182, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (701, 96, 183, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (702, 96, 184, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (703, 99, 185, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (704, 99, 186, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (705, 99, 187, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (706, 102, 188, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (707, 102, 189, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (708, 102, 190, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (709, 106, 192, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (710, 106, 193, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (711, 106, 194, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (712, 109, 195, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (713, 109, 196, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (714, 109, 197, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (715, 109, 198, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (716, 109, 199, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (717, 109, 200, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (718, 109, 201, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (719, 112, 202, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (720, 116, 203, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (721, 119, 204, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (722, 122, 205, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (723, 125, 206, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (724, 85, 170, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (725, 85, 171, 0, 1)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (726, 85, 172, 0, 2)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (727, 88, 173, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (728, 88, 174, 0, 1)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (729, 88, 175, 0, 2)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (730, 91, 176, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (731, 91, 177, 0, 1)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (732, 91, 178, 0, 2)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (733, 94, 179, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (734, 94, 180, 0, 1)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (735, 94, 181, 0, 2)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (736, 97, 182, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (737, 97, 183, 0, 1)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (738, 97, 184, 0, 2)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (739, 100, 185, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (740, 100, 186, 0, 1)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (741, 100, 187, 0, 2)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (742, 103, 188, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (743, 103, 189, 0, 1)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (744, 103, 190, 0, 2)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (745, 107, 192, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (746, 107, 193, 0, 1)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (747, 107, 194, 0, 2)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (748, 110, 195, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (749, 110, 196, 0, 1)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (750, 110, 197, 0, 2)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (751, 110, 198, 0, 3)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (752, 110, 199, 0, 4)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (753, 110, 200, 0, 5)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (754, 110, 201, 0, 6)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (755, 114, 202, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (756, 117, 203, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (757, 120, 204, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (758, 123, 205, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (759, 126, 206, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (761, 130, 172, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (762, 130, 171, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (763, 130, 208, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (764, 130, 209, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (765, 130, 211, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (766, 130, 212, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (767, 130, 213, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (768, 130, 214, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (769, 130, 215, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (770, 130, 216, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (771, 130, 217, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (772, 130, 218, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (773, 130, 219, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (774, 130, 220, 13, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (775, 130, 221, 14, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (776, 131, 222, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (777, 132, 223, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (778, 133, 224, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (788, 144, 215, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (789, 152, 170, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (790, 152, 171, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (791, 152, 172, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (792, 159, 170, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (793, 159, 171, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (794, 159, 172, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (795, 161, 170, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (796, 161, 171, 0, 1)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (797, 161, 172, 0, 2)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (798, 163, 173, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (799, 163, 174, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (800, 163, 175, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (801, 164, 173, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (802, 164, 174, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (803, 164, 175, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (804, 168, 173, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (805, 168, 174, 0, 1)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (806, 168, 175, 0, 2)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (807, 171, 176, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (808, 171, 177, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (809, 171, 178, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (810, 172, 176, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (811, 172, 177, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (812, 172, 178, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (813, 173, 176, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (814, 173, 177, 0, 1)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (815, 173, 178, 0, 2)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (816, 174, 179, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (817, 174, 180, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (818, 174, 181, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (819, 175, 179, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (820, 175, 180, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (821, 175, 181, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (822, 176, 179, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (823, 176, 180, 0, 1)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (824, 176, 181, 0, 2)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (825, 177, 225, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (826, 177, 226, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (827, 177, 227, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (828, 178, 225, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (829, 178, 226, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (830, 178, 227, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (831, 179, 225, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (832, 179, 226, 0, 1)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (833, 179, 227, 0, 2)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (834, 180, 202, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (835, 181, 202, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (836, 182, 202, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (837, 183, 203, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (838, 184, 203, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (839, 185, 203, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (840, 186, 204, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (841, 188, 204, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (842, 190, 204, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (843, 191, 213, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (844, 191, 228, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (845, 191, 229, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (846, 191, 214, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (847, 193, 213, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (848, 193, 228, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (849, 193, 229, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (850, 193, 214, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (851, 194, 213, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (852, 194, 228, 0, 1)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (853, 194, 229, 0, 2)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (854, 194, 214, 0, 3)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (855, 197, 230, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (856, 198, 230, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (857, 199, 230, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (858, 200, 215, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (859, 201, 215, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (860, 202, 231, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (861, 203, 231, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (862, 205, 216, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (863, 206, 216, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (864, 209, 232, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (865, 210, 232, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (866, 212, 232, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (867, 213, 233, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (868, 214, 233, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (869, 215, 233, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (870, 216, 217, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (871, 218, 217, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (872, 219, 217, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (873, 220, 234, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (874, 220, 235, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (875, 220, 236, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (876, 222, 234, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (877, 222, 235, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (878, 222, 236, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (879, 223, 234, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (880, 223, 235, 0, 1)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (881, 223, 236, 0, 2)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (882, 225, 237, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (883, 225, 238, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (884, 225, 239, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (885, 225, 240, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (886, 225, 241, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (887, 226, 237, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (888, 226, 238, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (889, 226, 239, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (890, 226, 240, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (891, 226, 241, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (892, 227, 237, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (893, 227, 238, 0, 1)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (894, 227, 239, 0, 2)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (895, 227, 240, 0, 3)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (896, 227, 241, 0, 4)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (897, 228, 242, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (898, 229, 242, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (899, 230, 242, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (900, 231, 222, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (901, 232, 222, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (902, 233, 222, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (903, 234, 243, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (904, 235, 243, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (905, 236, 243, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (906, 238, 245, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (907, 239, 245, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (908, 240, 245, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (909, 241, 246, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (910, 241, 247, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (911, 241, 248, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (912, 241, 249, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (913, 241, 250, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (914, 241, 251, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (915, 241, 252, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (916, 241, 253, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (917, 241, 254, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (918, 241, 255, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (919, 241, 256, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (920, 241, 257, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (921, 241, 258, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (922, 241, 259, 13, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (923, 242, 246, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (924, 242, 247, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (925, 242, 248, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (926, 242, 249, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (927, 242, 250, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (928, 242, 251, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (929, 242, 252, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (930, 242, 253, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (931, 242, 254, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (932, 242, 255, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (933, 242, 256, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (934, 242, 257, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (935, 242, 258, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (936, 242, 259, 13, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (937, 246, 246, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (938, 246, 247, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (939, 246, 248, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (940, 246, 249, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (941, 246, 250, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (942, 246, 251, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (943, 246, 252, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (944, 246, 253, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (945, 246, 254, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (946, 246, 255, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (947, 246, 256, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (948, 246, 257, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (949, 246, 258, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (950, 246, 259, 13, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (951, 247, 246, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (952, 247, 247, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (953, 247, 248, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (954, 247, 249, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (955, 247, 250, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (956, 247, 251, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (957, 247, 252, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (958, 247, 253, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (959, 247, 254, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (960, 247, 255, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (961, 247, 256, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (962, 247, 257, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (963, 247, 258, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (964, 247, 259, 13, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (965, 248, 244, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (966, 249, 244, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (967, 250, 244, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (968, 258, 260, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (969, 258, 261, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (970, 259, 260, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (971, 259, 261, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (972, 260, 260, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (973, 260, 261, 0, 1)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (974, 261, 262, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (975, 261, 263, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (976, 261, 264, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (977, 262, 262, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (978, 262, 263, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (979, 262, 264, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (980, 263, 262, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (981, 263, 263, 0, 1)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (982, 263, 264, 0, 2)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (983, 264, 265, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (984, 266, 265, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (985, 267, 265, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (986, 268, 266, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (987, 269, 266, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (988, 270, 266, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (989, 271, 280, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (990, 271, 281, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (991, 271, 282, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (992, 271, 283, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (993, 271, 284, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (994, 271, 285, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (995, 271, 286, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (996, 271, 287, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (997, 271, 288, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (998, 271, 289, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (999, 271, 298, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1000, 271, 322, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1001, 272, 280, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1002, 272, 281, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1003, 272, 282, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1004, 272, 283, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1005, 272, 284, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1006, 272, 285, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1007, 272, 286, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1008, 272, 287, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1009, 272, 288, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1010, 272, 289, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1011, 272, 298, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1012, 272, 322, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1015, 275, 280, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1016, 275, 281, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1017, 275, 282, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1018, 275, 283, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1019, 275, 284, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1020, 275, 285, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1021, 275, 286, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1022, 275, 287, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1023, 275, 288, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1024, 275, 289, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1025, 275, 298, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1026, 275, 322, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1027, 276, 280, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1028, 276, 281, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1029, 276, 282, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1030, 276, 283, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1031, 276, 284, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1032, 276, 285, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1033, 276, 286, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1034, 276, 287, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1035, 276, 288, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1036, 276, 289, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1037, 276, 298, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1038, 276, 322, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1039, 277, 290, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1040, 277, 291, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1041, 277, 292, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1042, 277, 293, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1043, 277, 294, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1044, 277, 295, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1045, 277, 296, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1046, 277, 297, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1047, 278, 290, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1048, 278, 291, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1049, 278, 292, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1050, 278, 293, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1051, 278, 294, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1052, 278, 295, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1053, 278, 296, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1054, 278, 297, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1055, 279, 290, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1056, 279, 291, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1057, 279, 292, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1058, 279, 293, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1059, 279, 294, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1060, 279, 295, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1061, 279, 296, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1062, 279, 297, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1063, 280, 290, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1064, 280, 291, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1065, 280, 292, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1066, 280, 293, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1067, 280, 294, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1068, 280, 295, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1069, 280, 296, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1070, 280, 297, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1071, 281, 299, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1072, 281, 300, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1073, 281, 301, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1074, 283, 299, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1075, 283, 300, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1076, 283, 301, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1077, 284, 299, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1078, 284, 300, 0, 1)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1079, 284, 301, 0, 2)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1134, 285, 302, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1135, 286, 302, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1137, 287, 302, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1138, 288, 303, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1139, 288, 304, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1140, 288, 305, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1141, 288, 306, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1142, 289, 303, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1143, 289, 304, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1144, 289, 305, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1145, 289, 306, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1146, 290, 303, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1147, 290, 304, 0, 1)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1148, 290, 305, 0, 2)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1149, 290, 306, 0, 3)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1150, 291, 307, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1151, 292, 307, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1152, 293, 307, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1153, 294, 308, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1154, 294, 309, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1155, 294, 310, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1156, 294, 311, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1157, 294, 312, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1158, 294, 323, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1159, 295, 308, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1160, 295, 309, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1161, 295, 310, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1162, 295, 311, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1163, 295, 312, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1164, 295, 323, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1165, 296, 308, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1166, 296, 309, 0, 1)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1167, 296, 310, 0, 2)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1168, 296, 311, 0, 3)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1169, 296, 312, 0, 4)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1170, 296, 323, 0, 5)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1171, 297, 313, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1172, 298, 313, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1173, 299, 313, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1174, 300, 314, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1175, 300, 315, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1176, 300, 316, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1177, 300, 317, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1178, 300, 318, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1179, 304, 314, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1180, 304, 315, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1181, 304, 316, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1182, 304, 317, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1183, 304, 318, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1184, 305, 314, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1185, 305, 315, 0, 1)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1186, 305, 316, 0, 2)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1187, 305, 317, 0, 3)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1188, 305, 318, 0, 4)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1189, 306, 319, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1190, 306, 320, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1191, 307, 319, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1192, 307, 320, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1193, 309, 319, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1194, 309, 320, 0, 1)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1195, 310, 321, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1196, 311, 321, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1197, 312, 321, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1198, 313, 324, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1199, 313, 325, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1200, 314, 324, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1201, 314, 325, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1202, 315, 324, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1203, 315, 325, 0, 1)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1204, 316, 267, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1205, 316, 268, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1206, 316, 269, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1207, 316, 270, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1208, 316, 271, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1209, 316, 272, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1210, 316, 273, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1211, 316, 274, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1212, 316, 275, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1213, 316, 276, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1214, 316, 277, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1215, 316, 278, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1216, 316, 279, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1217, 317, 267, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1218, 317, 268, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1219, 317, 269, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1220, 317, 270, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1221, 317, 271, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1222, 317, 272, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1223, 317, 273, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1224, 317, 274, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1225, 317, 275, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1226, 317, 276, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1227, 317, 277, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1228, 317, 278, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1229, 317, 279, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1230, 319, 267, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1231, 319, 268, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1232, 319, 269, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1233, 319, 270, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1234, 319, 271, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1235, 319, 272, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1236, 319, 273, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1237, 319, 274, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1238, 319, 275, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1239, 319, 276, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1240, 319, 277, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1241, 319, 278, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1242, 319, 279, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1243, 320, 267, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1244, 320, 268, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1245, 320, 269, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1246, 320, 270, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1247, 320, 271, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1248, 320, 272, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1249, 320, 273, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1250, 320, 274, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1251, 320, 275, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1252, 320, 276, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1253, 320, 277, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1254, 320, 278, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1255, 320, 279, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1256, 330, 326, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1257, 330, 327, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1258, 330, 328, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1259, 330, 329, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1260, 330, 330, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1261, 330, 331, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1262, 330, 332, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1263, 330, 333, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1264, 331, 326, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1265, 331, 327, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1266, 331, 328, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1267, 331, 329, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1268, 331, 330, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1269, 331, 331, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1270, 331, 332, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1271, 331, 333, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1272, 332, 326, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1273, 332, 327, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1274, 332, 328, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1275, 332, 329, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1276, 332, 330, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1277, 332, 331, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1278, 332, 332, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1279, 332, 333, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1280, 333, 326, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1281, 333, 327, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1282, 333, 328, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1283, 333, 329, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1284, 333, 330, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1285, 333, 331, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1286, 333, 332, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1287, 333, 333, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1288, 334, 334, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1289, 334, 335, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1290, 334, 336, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1291, 334, 337, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1292, 334, 338, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1293, 334, 339, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1294, 334, 340, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1295, 334, 341, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1296, 334, 342, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1297, 334, 343, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1298, 334, 344, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1299, 334, 345, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1300, 334, 346, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1301, 334, 347, 13, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1302, 334, 348, 14, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1303, 334, 349, 15, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1304, 334, 350, 16, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1305, 335, 334, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1306, 335, 335, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1307, 335, 336, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1308, 335, 337, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1309, 335, 338, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1310, 335, 339, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1311, 335, 340, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1312, 335, 341, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1313, 335, 342, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1314, 335, 343, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1315, 335, 344, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1316, 335, 345, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1317, 335, 346, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1318, 335, 347, 13, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1319, 335, 348, 14, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1320, 335, 349, 15, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1321, 335, 350, 16, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1322, 336, 334, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1323, 336, 335, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1324, 336, 336, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1325, 336, 337, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1326, 336, 338, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1327, 336, 339, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1328, 336, 340, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1329, 336, 341, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1330, 336, 342, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1331, 336, 343, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1332, 336, 344, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1333, 336, 345, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1334, 336, 346, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1335, 336, 347, 13, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1336, 336, 348, 14, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1337, 336, 349, 15, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1338, 336, 350, 16, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1339, 337, 334, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1340, 337, 335, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1341, 337, 336, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1342, 337, 337, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1343, 337, 338, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1344, 337, 339, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1345, 337, 340, 6, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1346, 337, 341, 7, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1347, 337, 342, 8, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1348, 337, 343, 9, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1349, 337, 344, 10, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1350, 337, 345, 11, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1351, 337, 346, 12, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1352, 337, 347, 13, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1353, 337, 348, 14, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1354, 337, 349, 15, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1355, 337, 350, 16, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1356, 339, 351, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1357, 339, 352, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1358, 339, 353, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1359, 339, 354, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1360, 339, 355, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1361, 339, 356, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1362, 340, 351, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1363, 340, 352, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1364, 340, 353, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1365, 340, 354, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1366, 340, 355, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1367, 340, 356, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1368, 341, 351, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1369, 341, 352, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1370, 341, 353, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1371, 341, 354, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1372, 341, 355, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1373, 341, 356, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1374, 342, 351, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1375, 342, 352, 1, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1376, 342, 353, 2, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1377, 342, 354, 3, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1378, 342, 355, 4, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1379, 342, 356, 5, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1380, 207, 216, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1381, 352, 170, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1382, 353, 171, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1383, 354, 172, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1384, 356, 173, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1385, 357, 174, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1386, 358, 175, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1387, 359, 176, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1388, 360, 177, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1389, 361, 178, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1390, 362, 179, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1391, 363, 180, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1392, 364, 181, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1393, 365, 182, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1394, 366, 183, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1395, 367, 184, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1396, 368, 213, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1397, 369, 229, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1398, 370, 214, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1399, 371, 215, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1400, 372, 216, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1401, 373, 220, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1402, 374, 221, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1403, 375, 185, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1404, 376, 186, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1405, 377, 187, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1406, 378, 188, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1407, 379, 189, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1408, 380, 190, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1409, 381, 192, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1410, 382, 193, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1411, 383, 194, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1412, 384, 357, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1413, 385, 358, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1414, 388, 360, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1415, 389, 361, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1416, 390, 362, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1417, 392, 363, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1418, 393, 364, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1419, 394, 365, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1420, 404, 366, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1421, 397, 360, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1422, 398, 361, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1423, 399, 362, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1424, 400, 363, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1425, 401, 364, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1426, 402, 365, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1427, 403, 366, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1428, 413, 359, 0, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1429, 57, 119, 82, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1430, 57, 120, 83, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1431, 57, 367, 84, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1432, 57, 368, 85, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1433, 58, 367, 84, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1434, 58, 368, 85, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1435, 59, 367, 84, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1436, 59, 368, 85, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1437, 60, 367, 84, 0)
GO
INSERT [Forms].[QuestionEmissionActivity] ([id], [questionId], [emissionActivityId], [rowNo], [columnNo]) VALUES (1438, 60, 368, 84, 0)
GO
SET IDENTITY_INSERT [Forms].[QuestionEmissionActivity] OFF
GO
INSERT [Lookups].[DataSource] ([id], [name]) VALUES (1, N'JotForm')
GO
INSERT [Lookups].[DataSource] ([id], [name]) VALUES (2, N'NczForm')
GO
INSERT [Lookups].[EntityType] ([id], [name]) VALUES (1, N'CustomerProfile')
GO
INSERT [Lookups].[EntityType] ([id], [name]) VALUES (2, N'Event')
GO
INSERT [Lookups].[EntityType] ([id], [name]) VALUES (3, N'Meeting')
GO
INSERT [Lookups].[EntityType] ([id], [name]) VALUES (4, N'Customer')
GO
INSERT [Lookups].[FormCategory] ([id], [name]) VALUES (1, N'Certification')
GO
INSERT [Lookups].[FormCategory] ([id], [name]) VALUES (2, N'Event')
GO
INSERT [Lookups].[FormCategory] ([id], [name]) VALUES (3, N'Meeting')
GO
INSERT [Lookups].[QuestionInputType] ([id], [name]) VALUES (1, N'TextBox')
GO
INSERT [Lookups].[QuestionInputType] ([id], [name]) VALUES (2, N'TextArea')
GO
INSERT [Lookups].[QuestionInputType] ([id], [name]) VALUES (3, N'Date')
GO
INSERT [Lookups].[QuestionInputType] ([id], [name]) VALUES (4, N'Time')
GO
INSERT [Lookups].[QuestionInputType] ([id], [name]) VALUES (5, N'Select')
GO
INSERT [Lookups].[QuestionInputType] ([id], [name]) VALUES (6, N'Number')
GO
INSERT [Lookups].[QuestionType] ([id], [name]) VALUES (1, N'EntityReference')
GO
INSERT [Lookups].[QuestionType] ([id], [name]) VALUES (2, N'ReportingFrequency')
GO
INSERT [Lookups].[QuestionType] ([id], [name]) VALUES (3, N'OptInPreference')
GO
INSERT [Lookups].[QuestionType] ([id], [name]) VALUES (4, N'UserInputByMonth')
GO
INSERT [Lookups].[QuestionType] ([id], [name]) VALUES (5, N'UserInputAnnualByMonth')
GO
INSERT [Lookups].[QuestionType] ([id], [name]) VALUES (6, N'UserInputAnnual')
GO
INSERT [Lookups].[QuestionType] ([id], [name]) VALUES (7, N'Month')
GO
INSERT [Lookups].[QuestionType] ([id], [name]) VALUES (8, N'ManagementBasedDecision')
GO
INSERT [Lookups].[QuestionType] ([id], [name]) VALUES (9, N'DataUnit')
GO
INSERT [Lookups].[QuestionType] ([id], [name]) VALUES (10, N'ConversionFactor')
GO
INSERT [Lookups].[QuestionType] ([id], [name]) VALUES (11, N'UserInputAnnualFromJanToJun')
GO
INSERT [Lookups].[QuestionType] ([id], [name]) VALUES (12, N'UnserInputAnnualFromJulToDec')
GO
INSERT [Lookups].[QuestionType] ([id], [name]) VALUES (13, N'UserInputTextBox')
GO
INSERT [Lookups].[QuestionType] ([id], [name]) VALUES (14, N'DeliveriesItemiseInput')
GO
INSERT [Lookups].[ReportingFrequency] ([id], [name]) VALUES (1, N'weekly')
GO
INSERT [Lookups].[ReportingFrequency] ([id], [name]) VALUES (2, N'monthly')
GO
INSERT [Lookups].[ReportingFrequency] ([id], [name]) VALUES (3, N'annualised_monthly')
GO
INSERT [Lookups].[ReportingFrequency] ([id], [name]) VALUES (4, N'annualised')
GO
