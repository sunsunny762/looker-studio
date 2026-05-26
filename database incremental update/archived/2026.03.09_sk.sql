IF NOT EXISTS (
    SELECT * FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[Reports].[spBlueCertificationCompletedData]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC dbo.sp_executesql
        @statement = N'CREATE PROCEDURE [Reports].[spBlueCertificationCompletedData] AS'
END
GO

ALTER PROCEDURE [Reports].[spBlueCertificationCompletedData]
AS
BEGIN
    SET NOCOUNT ON; 

    SELECT 
        cfs.dimSubmissionId AS submissionId,
        bac.blueCertId, 
        bac.certSubmissionId, 
        bac.status, 
        bac.companyId, 
        bac.documentId, 
        bac.certTaskId,

        MAX(CASE WHEN fs.questionId = 817 THEN fs.responseData END) AS companyName,
        MAX(CASE WHEN fs.questionId = 826 THEN fs.responseData END) AS fullName,
        MAX(CASE WHEN fs.questionId = 828 THEN fs.responseData END) AS email,
        MAX(CASE WHEN fs.questionId = 829 THEN fs.responseData END) AS jobTitle,
        MAX(CASE WHEN fs.questionId = 831 THEN fs.responseData END) AS phone,
        MAX(CASE WHEN fs.questionId = 820 THEN fs.responseData END) AS website,
        MAX(CASE WHEN fs.questionId = 822 THEN JSON_VALUE(fs.responseData, '$.value') END) AS country,
        MAX(CASE WHEN fs.questionId = 825 THEN JSON_VALUE(fs.responseData, '$[0]') END) AS companyLogo

    FROM portal.BlueAwardCertification bac 

    INNER JOIN portal.CertFormSubmissions cfs 
        ON bac.certSubmissionId = cfs.certSubmissionId 

    LEFT JOIN portal.FormSubmissionResponses fs
        ON cfs.submissionId = fs.submissionId

    WHERE 
        bac.status = 2 
        AND bac.isDeleted = 0 
        AND EXISTS (
            SELECT 1 
            FROM Reports.blueAwardByScope r
            WHERE r.submissionId = cfs.dimSubmissionId
        )

    GROUP BY
        bac.blueCertId, 
        bac.certSubmissionId, 
        bac.status, 
        bac.companyId, 
        bac.documentId, 
        bac.certTaskId,
        cfs.dimSubmissionId

END
GO


IF NOT EXISTS (
    SELECT * FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[portal].[spCertificationBlueAwardStatus_Update]')
      AND type IN (N'P', N'PC')
)
BEGIN
    EXEC dbo.sp_executesql
        @statement = N'CREATE PROCEDURE [portal].[spCertificationBlueAwardStatus_Update] AS'
END
GO

ALTER PROCEDURE [portal].[spCertificationBlueAwardStatus_Update]
    @certSubmissionId INT,
    @status INT,
    @notes NVARCHAR(MAX),
    @documentId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
  
    UPDATE portal.BlueAwardCertification
    SET 
        status = @status,
        notes = @notes,
        documentId = CASE 
                        WHEN @documentId IS NOT NULL THEN @documentId 
                        ELSE documentId 
                     END,
        dateUpdated = GETDATE()
    WHERE certSubmissionId = @certSubmissionId;
  
    EXEC portal.spCertificationBlueAward_Get @certSubmissionId;

END
GO