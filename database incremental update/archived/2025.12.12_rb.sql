ALTER PROCEDURE [Emissions].spAirport_Search
  @keyword nvarchar(20)
AS
BEGIN

    SELECT iata_code as value, concat(airportName,' (', iata_code,')') as label
    FROM emissions.Airports 
    WHERE municipality like '%' + @keyword + '%' or airportName LIKE '%' + @keyword + '%' or iata_code LIKE '%' + @keyword + '%'
    ORDER BY CHARINDEX(@keyword, airportName), CHARINDEX(@keyword, iata_code);

END