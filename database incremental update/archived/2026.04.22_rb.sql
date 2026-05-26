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

 Date: 22/04/2026 10:02:59
*/


-- ----------------------------
-- procedure structure for spSubmission_MarkProcessed
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spSubmission_MarkProcessed]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spSubmission_MarkProcessed]
GO

CREATE PROCEDURE [portal].[spSubmission_MarkProcessed]
	@submissionId int
AS
BEGIN
     SET NOCOUNT ON;
   
     Update portal.CertFormSubmissions
      set isProcessed = 1
     Where submissionId = @submissionId;
     
     -- if Blue Award from NCZForm, insert Blue award report data by executing SP
     if exists(Select * from portal.CertFormSubmissions where certId = 0 and dimFormId = 29 and submissionId = @submissionId)
     begin
        Declare @dimSubmissionId int, @certSubmissionId int, @EPId int;
        DECLARE @startDate nvarchar(25), @endDate nvarchar(25);
        
        Select @dimSubmissionId = dimSubmissionId, @certSubmissionId = certSubmissionId 
        from portal.CertFormSubmissions where submissionId = @submissionId;
        
        SELECT @startDate = CAST(DATEADD(DAY, +1, DATEADD(YEAR, -1, CAST(BAQ_ReportStartDate as date))) as date), @endDate = CAST(BAQ_ReportStartDate as date) 
        FROM [DataModel].[BlueAwardSubmissionData] bas
        WHERE bas.submissionId = @submissionId;
        
        Select @EPId = emissions.fnBlueAwardEmissionProfile_Get(@startDate, @endDate);
      
        exec DataModel.spBAQ_DataOutputByScope_Portal @dimSubmissionId, @EPId, 1; -- emission ProfileId: 9, 1 for Insert/ 0 for View

        Update portal.BlueAwardCertification 
          set status = 3, -- Set status "Report under process"
              dateUpdated = GETDATE()
        Where certSubmissionId = @certSubmissionId;
     end

END
GO


-- ----------------------------
-- function structure for fnBlueAwardEmissionProfile_Get
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[Emissions].[fnBlueAwardEmissionProfile_Get]') AND type IN ('FN', 'FS', 'FT', 'IF', 'TF'))
	DROP FUNCTION [Emissions].[fnBlueAwardEmissionProfile_Get]
GO

CREATE FUNCTION [Emissions].[fnBlueAwardEmissionProfile_Get]
(
    @StartDate DATE,
    @EndDate   DATE
)
RETURNS INT
AS
BEGIN
    IF @StartDate IS NULL OR @EndDate IS NULL OR @StartDate > @EndDate
        RETURN 10;

    IF YEAR(@StartDate) = YEAR(@EndDate)
        DECLARE @ReportYear INT = YEAR(@StartDate);
    ELSE
    BEGIN
        DECLARE @StartYearDays INT = DATEDIFF(DAY, @StartDate,  DATEFROMPARTS(YEAR(@StartDate), 12, 31)) + 1;
        DECLARE @EndYearDays   INT = DATEDIFF(DAY, DATEFROMPARTS(YEAR(@EndDate), 1, 1), @EndDate)        + 1;
        SET @ReportYear = CASE WHEN @EndYearDays > @StartYearDays THEN YEAR(@EndDate) ELSE YEAR(@StartDate) END;
    END

    DECLARE @EmissionProfileId INT;

    SELECT @EmissionProfileId = Id
    FROM   Emissions.EmissionProfile
    WHERE  Active = 1
    AND    Name LIKE 'BEIS / DEFRA%'
    AND    [Year] = @ReportYear;

    RETURN ISNULL(@EmissionProfileId, 10); -- fallback to 2025
END;
GO


-- ----------------------------
-- procedure structure for spFormResponse_MarkProcessed
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[Forms].[spFormResponse_MarkProcessed]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [Forms].[spFormResponse_MarkProcessed]
GO

CREATE PROCEDURE [Forms].[spFormResponse_MarkProcessed]
	@id int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @submissionId NVARCHAR(25), @jotformId NVARCHAR(25);

    SELECT 
      @submissionId = submissionId,
      @jotformId = formId
    FROM forms.JotformRawResponse
    WHERE id = @id;
  
   UPDATE [Forms].[JotformRawResponse] 
		 SET [processFlag] = 1
	 WHERE [id] = @id;  
   
   Update portal.CertFormSubmissions
    set isProcessed = 1
   Where submissionId = @submissionId;
   
   if(@jotformId='241290444812856') -- Company profile form then should go for update, it may be Blue Award
    begin
       Update portal.BlueAwardSubmissions
        set isProcessed = 1
       Where submissionId = @submissionId;
       
       -- if Blue Award from Jotform App, insert Blue award report data by executing SP
       if not exists (Select certSubmissionId from portal.CertFormSubmissions where submissionId = @submissionId)
       begin
          DECLARE @startDate nvarchar(25), @endDate nvarchar(25);
          DECLARE @EPId int;
          
          SELECT @startDate = CAST(DATEADD(DAY, +1, DATEADD(YEAR, -1, CAST(BAQ_ReportStartDate as date))) as date), @endDate = CAST(BAQ_ReportStartDate as date) 
          FROM [DataModel].[BlueAwardSubmissionData] bas
          WHERE bas.submissionId = @submissionId;
          
          Select @EPId = emissions.fnBlueAwardEmissionProfile_Get(@startDate, @endDate);
       
          exec DataModel.spBAQ_DataOutputByScope @submissionId, null, @EPId, 1; --emission ProfileId: 9, silversubmissionIds: null, 1 for Insert/ 0 for View
        
       end
    end
   
END
GO

