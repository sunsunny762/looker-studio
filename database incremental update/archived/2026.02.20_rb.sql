
-- Drop procedure if exists
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spCertificationBlueAwardStatus_Update]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spCertificationBlueAwardStatus_Update]
GO

-- Create procedure
CREATE PROCEDURE [portal].[spCertificationBlueAwardStatus_Update]
  @certSubmissionId int,
  @status int,
  @notes nvarchar(max)
AS
BEGIN
  SET NOCOUNT ON;
  
  UPDATE portal.BlueAwardCertification
  SET status = @status,
      notes = @notes,
      dateUpdated = GETDATE()
  WHERE certSubmissionId = @certSubmissionId;
  
  SELECT blueCertId, certSubmissionId, status, notes, dateUpdated
  FROM portal.BlueAwardCertification
  WHERE certSubmissionId = @certSubmissionId;
  
END
GO

-- Drop procedure if exists
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spCertificationBlueAward_Delete]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spCertificationBlueAward_Delete]
GO

-- Create procedure
CREATE PROCEDURE [portal].[spCertificationBlueAward_Delete]
  @certSubmissionId int
AS
BEGIN
  SET NOCOUNT ON;
  
  UPDATE portal.BlueAwardCertification
  SET isDeleted = 1,
      dateUpdated = GETDATE()
  WHERE certSubmissionId = @certSubmissionId;
  
END
GO


-- Drop existing procedure
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spCertificationBlueAward_Get]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spCertificationBlueAward_Get]
GO

-- Create updated procedure
CREATE PROCEDURE [portal].spCertificationBlueAward_Get
  @certSUbmissionId int = null
AS
BEGIN

    -- Blue award submissions from Portal
    SELECT  
        bac.blueCertId,
        bac.certSubmissionId,
        cfs.submissionId,
        cfs.dateSubmitted,
        cfs.notes AS companyName,
        cfs.isProcessed,
        bac.status as statusId,
        di.itemName as status,
        bac.notes,
        bac.certTaskId as certificationTaskId,
        MAX(CASE WHEN questionId = 826 THEN responseData END) AS fullName,
        MAX(CASE WHEN questionId = 828 THEN responseData END) AS email,
        MAX(CASE WHEN questionId = 829 THEN responseData END) AS jobTitle,
        MAX(CASE WHEN questionId = 831 THEN responseData END) AS phone,
        MAX(CASE WHEN questionId = 820 THEN responseData END) AS website,
        MAX(CASE WHEN questionId = 822 THEN JSON_VALUE(responseData, '$.value') END) AS country
    FROM portal.CertFormSubmissions AS cfs
    INNER JOIN portal.BlueAwardCertification as bac on (cfs.certsubmissionId = bac.certSubmissionId and bac.isDeleted = 0)
    INNER JOIN portal.DropdownItems as di on (bac.status = di.itemId)
    LEFT JOIN portal.FormSubmissionResponses AS fs
        ON cfs.submissionId = fs.submissionId
       AND fs.questionId IN (820, 822, 826, 828, 829, 831)

    WHERE cfs.certId = 0 AND cfs.dimFormId = 29
          and ISNULL(@certSubmissionId, bac.certSubmissionId) = bac.certSubmissionId 
    GROUP BY
        bac.blueCertId,
        bac.certSubmissionId,
        cfs.submissionId,
        cfs.dateSubmitted,
        cfs.notes,
        cfs.isProcessed,
        bac.status,
        di.itemName,
        bac.notes,
        bac.certTaskId
    ORDER BY cfs.dateSubmitted DESC;

END
GO
