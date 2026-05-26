/****** Object:  StoredProcedure [Emissions].[spGetFlightTypeDistance]    Script Date: 17/12/2025 10:32:38 ******/
DROP PROCEDURE [Emissions].[spGetFlightTypeDistance]
GO

/****** Object:  StoredProcedure [Emissions].[spGetFlightTypeDistance]    Script Date: 17/12/2025 10:32:38 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Emissions].[spGetFlightTypeDistance]
  @depAirport NVARCHAR(5),
  @arrAirport NVARCHAR(5)
AS
BEGIN

  Declare @srcLat float, @srcLon float, @destLat float, @destLon float, @distance float, @flightType varchar(10), @srcCountry varchar(2), @destCountry varchar(2);
  
  Select @srcLat = latitude_deg, @srcLon = longitude_deg, @srcCountry = iso_country 
  from Emissions.Airports where iata_code = Upper(Trim(@depAirport));
  Select @destLat = latitude_deg, @destLon = longitude_deg, @destCountry = iso_country 
  from Emissions.Airports where iata_code = Upper(Trim(@arrAirport));
  
  if(@srcLat is not null AND @destLat is not null)
    Select @distance = Emissions.fnFlightDistanceInKm(@srcLat, @srcLon, @destLat, @destLon); 
  else
    select null as distanceKms;
    
  if(@srcCountry = @destCountry)
    set @flightType = 'domestic';
  else if (@distance > 3700)
    set @flightType = 'long_haul';
  else
    set @flightType = 'short_haul';
    
  Select @distance as distanceKms, @flightType as flightType;
    

END
GO

