CREATE OR ALTER PROCEDURE [Reports].[spBlueCertificationReportGeneratedData]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        cfs.dimSubmissionId AS submissionId,
        bac.certSubmissionId,
        bac.documentId
    FROM portal.BlueAwardCertification bac
    INNER JOIN portal.CertFormSubmissions cfs
        ON bac.certSubmissionId = cfs.certSubmissionId
    WHERE
        bac.status = 4
        AND bac.isDeleted = 0
        AND bac.documentId IS NOT NULL;
END;
GO

CREATE OR ALTER PROCEDURE [Reports].[spBlueCertificationCompletedData]
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
        bac.status = 3
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
        cfs.dimSubmissionId;
END;
GO
