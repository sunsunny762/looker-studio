/****** StoredProcedure [portal].[spOtherSubmission_GetByProgFormId] ******/
IF NOT EXISTS (
    SELECT * FROM sys.objects 
    WHERE object_id = OBJECT_ID(N'[portal].[spOtherSubmission_GetByProgFormId]') 
    AND type IN (N'P', N'PC')
)
BEGIN
    EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [portal].[spOtherSubmission_GetByProgFormId] AS'
END
GO

ALTER PROCEDURE [portal].[spOtherSubmission_GetByProgFormId]
  @certId INT,
  @progFormId INT
AS
BEGIN
  SET NOCOUNT ON;

  SELECT 
      cfs.certsubmissionId, 
      cfs.submissionId, 
      df.dataSourceId, 
      FORMAT(cfs.dateSubmitted, 'dd/MM/yyyy') AS dateSubmitted, 
      CASE WHEN cfs.userId = 0 THEN cfs.notes ELSE u.fullName END AS submittedBy,
      CASE WHEN cfs.userId = 0 THEN '' ELSE cfs.notes END AS notes,
      CASE WHEN cfs.isDraft = 1 THEN 'Draft' ELSE 'Processed' END AS formStatus,
      pf.displayName AS formName,
      CASE WHEN pf.progFormId IN (209,309,409) THEN 1 ELSE 0 END AS isCHW, 
      0 AS isCMP, 
      cfs.isMBD, 
      cfs.isDraft, 
      cfs.isProcessed, 
      df.dataSourceId
  FROM portal.CertFormSubmissions AS cfs 
      INNER JOIN portal.Certification AS c ON (c.certId = cfs.certId)
      INNER JOIN portal.Programme AS p ON (c.progId = p.progId)
      INNER JOIN portal.ProgrammeForms AS pf ON (p.progId = pf.progId AND pf.dimFormId = cfs.dimFormId)
      INNER JOIN Dimension.Form AS df ON (pf.dimFormId = df.id)
      LEFT JOIN portal.Users AS u ON (u.userId = cfs.userId)
  WHERE 
      cfs.certId = @certId 
      AND pf.progFormId = @progFormId
      AND ((df.dataSourceId = 1 AND cfs.isDraft = 0) OR df.dataSourceId <> 1) -- Hide pending/draft for Jotform
  ORDER BY cfs.dateSubmitted DESC;
END
GO


/****** StoredProcedure [portal].[spOtherSubmission_GetTiles] ******/
IF NOT EXISTS (
    SELECT * FROM sys.objects 
    WHERE object_id = OBJECT_ID(N'[portal].[spOtherSubmission_GetTiles]') 
    AND type IN (N'P', N'PC')
)
BEGIN
    EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [portal].[spOtherSubmission_GetTiles] AS'
END
GO

ALTER PROCEDURE [portal].[spOtherSubmission_GetTiles]
  @certId INT,
  @uCompanyId INT = NULL
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @locationCnt INT = 1;
			
  IF ([portal].[fnCheckUserAccess]('CERTIFICATION', @certId, @uCompanyId) = 0)
  BEGIN
      RETURN;
  END;

  -- Other Forms
  SELECT 
      MAX(prg.progId) AS progId,
      prg.progName, 
      cert.certYear, 
      c.companyName, 
      cert.refNumber, 
      pf.progFormId, 
      pf.dimFormId, 
      pf.displayName AS formName, 
      SUM(CASE WHEN cfs.isDraft = 1 THEN 1 ELSE 0 END) AS draftCnt,
      SUM(CASE WHEN cfs.isDraft = 0 AND cfs.isProcessed = 0 THEN 1 ELSE 0 END) AS submitCnt,
      CASE 
          WHEN COUNT(cfs.submissionId) = 0 THEN 'Pending'
          ELSE 'Processed'
      END AS formStatus,
      pf.displayOrder,
      df.dataSourceId,
      NULL AS certsubmissionId
  FROM portal.Certification AS cert 
      INNER JOIN portal.Company AS c ON c.companyId = cert.companyId
      INNER JOIN portal.Programme AS prg ON prg.progId = cert.progId
      INNER JOIN portal.ProgrammeForms AS pf ON pf.progId = prg.progId AND pf.isActive = 1
      INNER JOIN Dimension.Form AS df ON df.id = pf.dimFormId AND df.categoryId = 6
      LEFT JOIN portal.CertFormSubmissions AS cfs 
          ON pf.dimFormId = cfs.dimFormId AND cert.certId = cfs.certId																		 
  WHERE cert.certId = @certId
  GROUP BY 
      prg.progName, cert.certYear, c.companyName, cert.refNumber, 
      pf.progFormId, pf.dimFormId, df.dataSourceId, pf.displayName, pf.displayOrder
  ORDER BY pf.displayOrder;
END
GO


/****** StoredProcedure [portal].[spSubmission_GetDetails] ******/
IF NOT EXISTS (
    SELECT * FROM sys.objects 
    WHERE object_id = OBJECT_ID(N'[portal].[spSubmission_GetDetails]') 
    AND type IN (N'P', N'PC')
)
BEGIN
    EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [portal].[spSubmission_GetDetails] AS'
END
GO

ALTER PROCEDURE [portal].[spSubmission_GetDetails]
  @certsubmissionId INT,
  @uCompanyId INT = NULL
AS
BEGIN
  SET NOCOUNT ON;
	
  IF ([portal].[fnCheckUserAccess]('CERT_FORM_SUBMISSIONS', @certsubmissionId, @uCompanyId) = 0)
  BEGIN
      RETURN;
  END;
  
  -- Get Submission details
  SELECT 
      c.companyName, 
      cert.refNumber, 
      prg.progName, 
      pf.displayName AS formName, 
      l.locationName,
      cfs.submissionId, 
      cfs.jotformId, 
      cert.certId, 
      df.dataSourceId, 
      cfs.dimFormId,
      CASE df.dataSourceId 
          WHEN 1 THEN jf.formId 
          WHEN 2 THEN CAST(nf.formId AS NVARCHAR(5)) 
      END AS formId
  FROM portal.Certification AS cert 
      INNER JOIN portal.CertFormSubmissions AS cfs ON (cfs.certId = cert.certId)
      INNER JOIN portal.Company AS c ON (c.companyId = cert.companyId)
      INNER JOIN portal.Programme AS prg ON (prg.progId = cert.progId) 
      INNER JOIN portal.ProgrammeForms AS pf ON (prg.progId = pf.progId AND pf.dimFormId = cfs.dimFormId)
      INNER JOIN Dimension.Form AS df ON (df.id = pf.dimFormId)
      LEFT JOIN portal.Location AS l ON (cfs.locationId = l.locationId)
      LEFT JOIN forms.JotForm AS jf ON (jf.id = df.sourceId AND df.dataSourceId = 1)
      LEFT JOIN portal.Forms AS nf ON (nf.formId = df.sourceId AND df.dataSourceId = 2)
  WHERE cfs.certsubmissionId = @certsubmissionId;
END
GO
