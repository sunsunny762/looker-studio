IF NOT EXISTS (
    SELECT * FROM sys.objects 
    WHERE object_id = OBJECT_ID(N'[portal].[spCertification_UpdateStatus]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC dbo.sp_executesql 
        @statement = N'CREATE PROCEDURE [portal].[spCertification_UpdateStatus] AS'
END
GO

ALTER PROCEDURE [portal].[spCertification_UpdateStatus]
    @certId INT,
    @companyId INT = NULL,
    @status INT,
    @userId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @companyId IS NULL
    BEGIN
        SELECT @companyId = companyId
        FROM portal.certification
        WHERE certId = @certId;
    END

    IF @companyId IS NULL
    BEGIN
        RETURN 0;
    END

    UPDATE portal.certification
    SET status = @status
    WHERE certId = @certId;

    EXEC [portal].[spCertificationStatusHistory_Save]
        @companyId = @companyId,
        @certId = @certId,
        @status = @status,
        @userId = @userId;

    EXEC portal.spCertification_Get @certId;
END
GO

IF NOT EXISTS (
    SELECT * FROM sys.objects 
    WHERE object_id = OBJECT_ID(N'[Reports].[spSilverAwardDetailData_Get]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC dbo.sp_executesql 
        @statement = N'CREATE PROCEDURE [Reports].[spSilverAwardDetailData_Get] AS'
END
GO

ALTER PROCEDURE [Reports].[spSilverAwardDetailData_Get]
    @certId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM [Reports].[SilverAwardDetailData]
    WHERE certId = @certId;
END
GO

IF NOT EXISTS (
    SELECT * FROM sys.objects 
    WHERE object_id = OBJECT_ID(N'[Reports].[spSilverAwardByScope_Get]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC dbo.sp_executesql 
        @statement = N'CREATE PROCEDURE [Reports].[spSilverAwardByScope_Get] AS'
END
GO

ALTER PROCEDURE [Reports].[spSilverAwardByScope_Get]
    @certId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM [Reports].[silverAwardByScope]
    WHERE certId = @certId;
END
GO

IF NOT EXISTS (
    SELECT * FROM sys.objects 
    WHERE object_id = OBJECT_ID(N'[Reports].[spSilverCertificationCompletedData]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC dbo.sp_executesql 
        @statement = N'CREATE PROCEDURE [Reports].[spSilverCertificationCompletedData] AS'
END
GO

ALTER PROCEDURE [Reports].[spSilverCertificationCompletedData]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        Cert.certId,
        Cert.companyId,
        Cert.progId,
        Cert.status
    FROM portal.Certification AS Cert

    INNER JOIN portal.Programme AS P 
        ON P.progId = Cert.progId 
        AND Cert.isDeleted = 0 
        AND Cert.status IN (2, 3)
        AND Cert.progId = 2

    INNER JOIN portal.Company AS C 
        ON C.companyId = Cert.companyId 
        AND C.status = 1 
        AND C.isDeleted = 0

    INNER JOIN portal.CertFormSubmissions AS CFS 
        ON Cert.certId = CFS.certId 
        AND CFS.jotformId = '241290444812856' 
        AND CFS.isProcessed = 1

    GROUP BY Cert.certId, Cert.companyId, Cert.progId, Cert.status;
END
GO

IF NOT EXISTS (
    SELECT * FROM sys.objects 
    WHERE object_id = OBJECT_ID(N'[DataModel].[spSilver_DataOutputDetailedWrapper_Portal]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC dbo.sp_executesql 
        @statement = N'CREATE PROCEDURE [DataModel].[spSilver_DataOutputDetailedWrapper_Portal] AS'
END
GO

ALTER PROCEDURE [DataModel].[spSilver_DataOutputDetailedWrapper_Portal] 
    @certId int,
    @emissionProfileId INT,
    @dataInsert int = 0
AS
BEGIN
    DECLARE @BAQSubmissionId bigint;
    DECLARE @SilverSubmissionIds nvarchar(max), @CHWSubmissionIds nvarchar(max);
    
    SET @SilverSubmissionIds = (SELECT STRING_AGG([dimSubmissionId], ',') FROM portal.CertFormSubmissions 
                                WHERE dimFormId not in (14, 29, 11, 26) and certId = @certId and isProcessed=1);
    
    SELECT @BAQSubmissionId = MAX(dimSubmissionId)
    FROM portal.CertFormSubmissions
    WHERE dimFormId IN (14, 29) AND certId = @certId AND isProcessed = 1;
    
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
