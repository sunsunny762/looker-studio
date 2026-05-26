/****** View: [PowerBI].[vCertificationTasks] ******/

IF NOT EXISTS (
    SELECT *
    FROM sys.views
    WHERE object_id = OBJECT_ID(N'[PowerBI].[vCertificationTasks]')
)
BEGIN
    EXEC (
        'CREATE VIEW [PowerBI].[vCertificationTasks]
         AS
         SELECT 1 AS DummyColumn'
    );
END
GO

ALTER VIEW [PowerBI].[vCertificationTasks]
AS
WITH LatestTaskStatus AS (
    SELECT
        t.id,
        t.name,
        t.status,
        t.dateUpdated,
        t.activeTo,
        t.parentId,
        t.listId,
        ROW_NUMBER() OVER (
            PARTITION BY t.id
            ORDER BY t.dateUpdated DESC
        ) AS rn
    FROM [clickup].[Task] t
)
SELECT
    lts.id,
    lts.name,
    lts.status,
    ef.id   AS emissionProfileId,
    ef.name AS emissionProfile
FROM LatestTaskStatus lts
JOIN [Emissions].[EmissionProfile] ef
    ON ef.active = 1
   AND ef.id = 9
WHERE lts.rn = 1
  AND lts.listId IN (
        '901200207978',
        '901205502657',
        '901205524266',
        '901206607383',
        '901206788692',
        '901206788699',
        '901206788725',
        '901206501310'
    )
  AND lts.parentId IS NULL
  AND (
        lts.activeTo > [Utilities].[DateToEpoch](GETDATE())
        OR lts.activeTo IS NULL
      )
  AND lts.status IN (
        'blue data submitted',
        'data collection complete'
      );
GO
