/****** Add Table [clickup].[CertificationBuyer]  ******/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[CertificationBuyer]') AND type in (N'U'))
BEGIN
	CREATE TABLE [clickup].[CertificationBuyer] (
		[certificationTaskId] nvarchar(25) NOT NULL ,
		[buyerTaskId] nvarchar(25) NOT NULL ,
		PRIMARY KEY (
			[certificationTaskId], [buyerTaskId]
		)
	)
END
GO

/******  StoredProcedure [clickup].[spClickup_AddCertificationBuyer] ******/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[clickup].[spClickup_AddCertificationBuyer]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [clickup].[spClickup_AddCertificationBuyer] AS' 
END
GO

ALTER PROCEDURE [clickup].[spClickup_AddCertificationBuyer]
	@data_JSON NVARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @tblData TABLE(
		 [certificationTaskId] nvarchar(36)
		,[buyerTaskId] nvarchar(36)
	)
	INSERT INTO @tblData ([certificationTaskId], [buyerTaskId])
	SELECT ln.[certificationTaskId], ln.[buyerTaskId]
	FROM OPENJSON(@data_JSON) A
	CROSS APPLY OPENJSON(A.value) 
	WITH
	(
		[certificationTaskId] nvarchar(36),
		[buyerTaskId] nvarchar(36)
	) ln;

	MERGE INTO [clickup].[CertificationBuyer] AS target
    USING @tblData AS source
    ON target.certificationTaskId = source.[certificationTaskId] AND target.buyerTaskId = source.[buyerTaskId]
    WHEN NOT MATCHED THEN
        INSERT (certificationTaskId, buyerTaskId) VALUES (source.[certificationTaskId], source.[buyerTaskId]);
		
	Return 1;
END

GO