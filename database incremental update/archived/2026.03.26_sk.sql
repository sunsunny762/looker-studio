IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spCertification_GetSubmissions]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spCertification_GetSubmissions]
GO

CREATE PROCEDURE [portal].[spCertification_GetSubmissions]
  @certId INT
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    pf.progFormId,
    pf.dimFormId,
    pf.displayName AS formName,
    pf.displayOrder,
    df.dataSourceId,
    cfs.certsubmissionId,
    cfs.submissionId,
    cfs.dateSubmitted,
    cfs.userId,
    u.fullName,
    cfs.locationId,
    l.locationName
  FROM portal.Certification AS cert
  INNER JOIN portal.ProgrammeForms AS pf
    ON pf.progId = cert.progId
  INNER JOIN Dimension.Form AS df
    ON df.id = pf.dimFormId
  INNER JOIN portal.CertFormSubmissions AS cfs
    ON pf.dimFormId = cfs.dimFormId
    AND cert.certId = cfs.certId
  LEFT JOIN portal.Users AS u
    ON u.userId = cfs.userId
    AND ISNULL(u.isDeleted, 0) = 0
  LEFT JOIN portal.Location AS l
    ON l.locationId = cfs.locationId
    AND ISNULL(l.isDeleted, 0) = 0
  WHERE cert.certId = @certId
    AND cfs.isDraft = 0
  ORDER BY cfs.dateSubmitted;
END;
GO
