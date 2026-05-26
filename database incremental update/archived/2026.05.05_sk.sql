IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[portal].[spCertificationSubmissionDocuments_Get]') AND type IN (N'P', N'PC'))
    DROP PROCEDURE [portal].[spCertificationSubmissionDocuments_Get];
GO

CREATE PROCEDURE [portal].[spCertificationSubmissionDocuments_Get]
   @certId INT
AS
BEGIN
    SET NOCOUNT ON;

    ;SELECT *
    FROM (
        SELECT
            CONCAT('NCZ:', @certId, ':', d.id) AS documentKey,
            cfs.certsubmissionId,
            ISNULL(l.locationName, '') AS locationName,
            pf.displayName AS formName,
            ISNULL(fq.questionLabel, '') AS question,
            COALESCE(fsd.displayName, d.title, '') AS documentName,
            'NCZFORM' AS sourceType,
            d.container,
            d.blobName
        FROM portal.Certification cert
        INNER JOIN portal.ProgrammeForms pf
            ON pf.progId = cert.progId
        INNER JOIN Dimension.Form df
            ON df.id = pf.dimFormId AND df.dataSourceId = 2
        INNER JOIN portal.CertFormSubmissions cfs
            ON cfs.certId = cert.certId
            AND cfs.dimFormId = pf.dimFormId
        INNER JOIN portal.FormSubmissionDocuments fsd
            ON fsd.submissionId = cfs.submissionId
            AND fsd.formId = df.sourceId
        INNER JOIN documents.Document d
            ON d.id = fsd.documentId
        LEFT JOIN portal.Location l
            ON l.locationId = cfs.locationId
            AND ISNULL(l.isDeleted, 0) = 0
        LEFT JOIN portal.FormQuestions fq
            ON fq.questionId = fsd.questionId
            AND fq.formId = fsd.formId
        WHERE cert.certId = @certId
            AND ISNULL(cfs.isDraft, 0) = 0

        UNION ALL

        -- JOTFORM DOCUMENTS
        SELECT
            CONCAT('JOTFORM:', @certId, ':', cfs.certsubmissionId, ':', attachments.[key]),
            cfs.certsubmissionId,
            ISNULL(l.locationName, ''),
            pf.displayName,
            ISNULL(jq.question, 'Attachment'),
            attachments.[value],
            'JOTFORM',
            'jotform-submission-docs',
            CONCAT(CAST(cfs.submissionId AS NVARCHAR(50)), '/', attachments.[value])
        FROM portal.Certification cert
        INNER JOIN portal.ProgrammeForms pf
            ON pf.progId = cert.progId
        INNER JOIN Dimension.Form df
            ON df.id = pf.dimFormId AND df.dataSourceId = 1
        INNER JOIN portal.CertFormSubmissions cfs
            ON cfs.certId = cert.certId
            AND cfs.dimFormId = pf.dimFormId
        INNER JOIN portal.JotformViewDetail jvd
            ON jvd.submissionId = cfs.submissionId
            AND ISNULL(jvd.isSuccess, 0) = 1
        CROSS APPLY OPENJSON(
            CASE WHEN ISJSON(jvd.attachment) = 1 
                 THEN jvd.attachment 
                 ELSE '[]' END
        ) attachments
        OUTER APPLY (
            SELECT TOP 1 JSON_VALUE(a.[value], '$.text') AS question
            FROM OPENJSON(JSON_QUERY(jvd.jotformViewResponse, '$.content.answers')) a
            WHERE a.[value] LIKE CONCAT('%', attachments.[value], '%')
            ORDER BY TRY_CAST(JSON_VALUE(a.[value], '$.order') AS INT)
        ) jq
        LEFT JOIN portal.Location l
            ON l.locationId = cfs.locationId
            AND ISNULL(l.isDeleted, 0) = 0
        WHERE cert.certId = @certId
            AND ISNULL(cfs.isDraft, 0) = 0
    ) finalResult
    ORDER BY locationName, formName, question, documentName;
END;
GO
