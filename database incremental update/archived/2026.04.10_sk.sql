-- ============================================================
-- SP: spCertificationHeadCount_Get
--   Returns certification totals and active company locations,
--   including location currency and country name.
-- ============================================================
IF EXISTS (
    SELECT * FROM sys.all_objects
    WHERE object_id = OBJECT_ID(N'[portal].[spCertificationHeadCount_Get]')
    AND type IN ('P', 'PC', 'RF', 'X')
)
    DROP PROCEDURE [portal].[spCertificationHeadCount_Get]
GO

CREATE PROCEDURE [portal].[spCertificationHeadCount_Get]
    @certId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.certId,
        c.headCount,
        c.revenue
    FROM [portal].[Certification] c
    WHERE c.certId = @certId;

    SELECT
        l.locationId,
        l.locationName,
        l.currency,
        cntr.countryName,
        hc.headCount,
        hc.revenue
    FROM [portal].[Location] l
    INNER JOIN [portal].[Certification] cert
        ON cert.companyId = l.companyId
        AND cert.certId = @certId
    LEFT JOIN [portal].[CertificationHeadCount] hc
        ON hc.certId = @certId
        AND hc.locationId = l.locationId
    LEFT JOIN Lookups.Countries AS cntr
        ON l.countryId = cntr.countryId
    WHERE l.isDeleted = 0
    ORDER BY l.locationName;
END
GO
