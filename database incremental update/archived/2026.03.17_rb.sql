/*
 Navicat Premium Data Transfer

 Source Server         : NCZ [Dev]
 Source Server Type    : SQL Server
 Source Server Version : 12009114 (12.00.9114)
 Source Host           : ncz.database.windows.net:1433
 Source Catalog        : nczdev
 Source Schema         : DataModel

 Target Server Type    : SQL Server
 Target Server Version : 12009114 (12.00.9114)
 File Encoding         : 65001

 Date: 17/03/2026 16:39:31
*/


-- ----------------------------
-- function structure for fnSAQ_DataOutput_Portal
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[DataModel].[fnSAQ_DataOutput_Portal]') AND type IN ('FN', 'FS', 'FT', 'IF', 'TF'))
	DROP FUNCTION [DataModel].[fnSAQ_DataOutput_Portal]
GO

CREATE FUNCTION [DataModel].[fnSAQ_DataOutput_Portal](@dimSubmissionId BIGINT)
RETURNS @result TABLE 
(
    category NVARCHAR(255),
    total DECIMAL(18,2),
    dataUnit NVARCHAR(50),
    bmCategory NVARCHAR(255),
    [order] DECIMAL(5,2)
)
AS
BEGIN
		-- Declare variables for the specified fields
    
		DECLARE @SAQ_TotalHeadcount NUMERIC(10,2),
				@SAQ_OfficeHeadcount NUMERIC(10,2),
				@SAQ_CompanyRevenue MONEY,
				@SAQ_WorkingDaysAndCommuting_AvgDaysPerWeekWorked_Office NUMERIC(10,2),
				@SAQ_WorkingDaysAndCommuting_AvgDaysPerWeekWorked_Other NUMERIC(10,2),
				@SAQ_WorkingDaysAndCommuting_AvgDaysPerWeekCommuting_Office NUMERIC(10,2),
				@SAQ_WorkingDaysAndCommuting_AvgDaysPerWeekCommuting_Other NUMERIC(10,2),
				@SAQ_WorkingDaysAndCommuting_AvgDistance_Office NUMERIC(10,2),
				@SAQ_WorkingDaysAndCommuting_AvgDistance_Other NUMERIC(10,2),
				@SAQ_OfficeStaffPublicTransport NUMERIC(10,2),
				@SAQ_OtherStaffPublicTransport NUMERIC(10,2),
				@SAQ_TotalSpend MONEY,
				@SAQ_TotalSpendUSD MONEY = 0,
				@SAQ_PercentageSpendOnServices NUMERIC(10,2),
				@SAQ_CompanyVehiclesMileage_Cars NUMERIC(10,2),
				@SAQ_CompanyVehiclesMileage_Vans NUMERIC(10,2),
				@SAQ_CompanyVehiclesMileage_HGVs NUMERIC(10,2),
				@SAQ_BusinessTravel_Domestic_Daily NUMERIC(10,2),
				@SAQ_BusinessTravel_International_Daily NUMERIC(10,2),
				@SAQ_BusinessTravel_Domestic_Weekly NUMERIC(10,2),
				@SAQ_BusinessTravel_International_Weekly NUMERIC(10,2),
				@SAQ_BusinessTravel_Domestic_Monthly NUMERIC(10,2),
				@SAQ_BusinessTravel_International_Monthly NUMERIC(10,2),
				@SAQ_BusinessTravel_Domestic_Quarterly NUMERIC(10,2),
				@SAQ_BusinessTravel_International_Quarterly NUMERIC(10,2),
				@SAQ_BusinessTravel_Domestic_Biannually NUMERIC(10,2),
				@SAQ_BusinessTravel_International_Biannually NUMERIC(10,2),
				@SAQ_BusinessTravel_Domestic_Annually NUMERIC(10,2),
				@SAQ_BusinessTravel_International_Annually NUMERIC(10,2),
				@SAQ_GoodsReceived_Local_Daily NUMERIC(10,2),
				@SAQ_GoodsReceived_National_Daily NUMERIC(10,2),
				@SAQ_GoodsReceived_International_Daily NUMERIC(10,2),
				@SAQ_GoodsReceived_Unknown_Daily NUMERIC(10,2),
				@SAQ_GoodsReceived_Local_Weekly NUMERIC(10,2),
				@SAQ_GoodsReceived_National_Weekly NUMERIC(10,2),
				@SAQ_GoodsReceived_International_Weekly NUMERIC(10,2),
				@SAQ_GoodsReceived_Unknown_Weekly NUMERIC(10,2),
				@SAQ_GoodsReceived_Local_Monthly NUMERIC(10,2),
				@SAQ_GoodsReceived_National_Monthly NUMERIC(10,2),
				@SAQ_GoodsReceived_International_Monthly NUMERIC(10,2),
				@SAQ_GoodsReceived_Unknown_Monthly NUMERIC(10,2),
				@SAQ_GoodsReceived_Local_Quarterly NUMERIC(10,2),
				@SAQ_GoodsReceived_National_Quarterly NUMERIC(10,2),
				@SAQ_GoodsReceived_International_Quarterly NUMERIC(10,2),
				@SAQ_GoodsReceived_Unknown_Quarterly NUMERIC(10,2),
				@SAQ_GoodsSent_Local_Daily NUMERIC(10,2),
				@SAQ_GoodsSent_National_Daily NUMERIC(10,2),
				@SAQ_GoodsSent_International_Daily NUMERIC(10,2),
				@SAQ_GoodsSent_Unknown_Daily NUMERIC(10,2),
				@SAQ_GoodsSent_Local_Weekly NUMERIC(10,2),
				@SAQ_GoodsSent_National_Weekly NUMERIC(10,2),
				@SAQ_GoodsSent_International_Weekly NUMERIC(10,2),
				@SAQ_GoodsSent_Unknown_Weekly NUMERIC(10,2),
				@SAQ_GoodsSent_Local_Monthly NUMERIC(10,2),
				@SAQ_GoodsSent_National_Monthly NUMERIC(10,2),
				@SAQ_GoodsSent_International_Monthly NUMERIC(10,2),
				@SAQ_GoodsSent_Unknown_Monthly NUMERIC(10,2),
				@SAQ_GoodsSent_Local_Quarterly NUMERIC(10,2),
				@SAQ_GoodsSent_National_Quarterly NUMERIC(10,2),
				@SAQ_GoodsSent_International_Quarterly NUMERIC(10,2),
				@SAQ_GoodsSent_Unknown_Quarterly NUMERIC(10,2),
				--calculated variables
				@CALC_WeeksInYear NUMERIC(10,2),
				@CALC_HoursPerDay NUMERIC(10,2),
				@CALC_OtherHeadcount NUMERIC(10,2),
				@CALC_TotalSpendOnServices MONEY,
				@CALC_TotalSpendOnProducts MONEY,
				@CALC_AnnualDaysWorked_Office NUMERIC(10,2),
				@CALC_AnnualDaysWorked_Other NUMERIC(10,2),
				@CALC_AnnualDaysCommute_Office NUMERIC(10,2),
				@CALC_AnnualDaysCommute_Other NUMERIC(10,2),
				@CALC_AnnualDistance_Office NUMERIC(10,2),
				@CALC_AnnualDistance_Other NUMERIC(10,2),
				@CALC_AnnualDaysHomeWorking_Office NUMERIC(10,2),
				@CALC_AnnualDaysHomeWorking_Other NUMERIC(10,2),
				@CALC_AnnualCommutingDistance_Other_Private NUMERIC(10,2),
				@CALC_AnnualCommutingDistance_Other_Public NUMERIC(10,2),
				@CALC_AnnualCommutingDistance_Office_Private NUMERIC(10,2),
				@CALC_AnnualCommutingDistance_Office_Public NUMERIC(10,2),
				@CALC_AnnualBusinessTravel_Domestic NUMERIC(10,2),
				@CALC_AnnualBusinessTravel_International NUMERIC(10,2),
				@CALC_AnnualGoodsReceived_Local NUMERIC(10,2),
				@CALC_AnnualGoodsReceived_National NUMERIC(10,2),
				@CALC_AnnualGoodsReceived_International NUMERIC(10,2),
				@CALC_AnnualGoodsReceived_Unknown NUMERIC(10,2),
				@CALC_AnnualGoodsSent_Local NUMERIC(10,2),
				@CALC_AnnualGoodsSent_National NUMERIC(10,2),
				@CALC_AnnualGoodsSent_International NUMERIC(10,2),
				@CALC_AnnualGoodsSent_Unknown NUMERIC(10,2),
				@CALC_AnnualElectric_Office NUMERIC(10,2),
				@CALC_AnnualGas_Office NUMERIC(10,2),
				@CALC_AnnualWater_Office NUMERIC(10,2),
				@CALC_OfficeWaste_Recycling NUMERIC(10,2),
				@CALC_OfficeWaste_Refuse NUMERIC(10,2),
				@CALC_TotalSQM NUMERIC(10,2),
				@CALC_TotalRefrigerant NUMERIC(10,2),
				@CALC_TotalOtherFuel NUMERIC(10,2),
				--Management Based Decisions
				@MBD_SQM_PER_PERSON NUMERIC(10,2),
				@MBD_ELEC_KWH_PER_SQM NUMERIC(10,2),
				@MBD_GAS_KWH_PER_SQM NUMERIC(10,2),
				@MBD_WATER_LITRES_PER_DAY NUMERIC(10,2),
				@MBD_WASTE_REFUSE_KG_PER_DAY NUMERIC(10,2),
				@MBD_WASTE_RECYCLING_KG_PER_DAY NUMERIC(10,2),
				@MBD_DELIVERY_LOCAL_KMS NUMERIC(10,2),
				@MBD_DELIVERY_NATIONAL_KMS NUMERIC(10,2),
				@MBD_DELIVERY_INTERNATIONAL_KMS NUMERIC(10,2),
				@MBD_DELIVERY_UNKNOWN_KMS NUMERIC(10,2),
				@MBD_REFRIGERANT_KG_PER_PERSON NUMERIC(10,2),
				@MBD_OTHER_FUEL_PER_PERSON NUMERIC(10,2);


		-- Assign values to each variable
		SELECT @CALC_WeeksInYear = 46
		SELECT @MBD_SQM_PER_PERSON = 4.6
		SELECT @MBD_WATER_LITRES_PER_DAY = 50
		SELECT @MBD_WASTE_RECYCLING_KG_PER_DAY = 0.892
		SELECT @MBD_WASTE_REFUSE_KG_PER_DAY = 1.108 
		SELECT @MBD_DELIVERY_LOCAL_KMS = 40.0
		SELECT @MBD_DELIVERY_NATIONAL_KMS = 200.0
		SELECT @MBD_DELIVERY_INTERNATIONAL_KMS = 500.0
		SELECT @MBD_DELIVERY_UNKNOWN_KMS = 200.0
		SELECT @CALC_HoursPerDay = 8.0
		Select @MBD_REFRIGERANT_KG_PER_PERSON = 0.226;
		Select @MBD_OTHER_FUEL_PER_PERSON = 0.357;

		--Company
		--SELECT @SAQ_TotalHeadcount = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_TotalHeadcount' AND dimSubmissionId = @dimSubmissionId;
		--SELECT @SAQ_OfficeHeadcount = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_OfficeHeadcount' AND dimSubmissionId = @dimSubmissionId;
		
    Select @SAQ_TotalHeadcount = cert.headCount, @SAQ_OfficeHeadcount = sum(hc.headCount)
    from portal.CertFormSubmissions as cfs 
        INNER JOIN portal.CertificationHeadCount as hc on (cfs.certId = hc.certId)
        INNER JOIN portal.Certification as cert on (cert.certId = cfs.certId)
    where cfs.dimSubmissionId = @dimSubmissionId
    GROUP BY cfs.certId, cert.headCount;
    
    SELECT @CALC_OtherHeadcount = (@SAQ_TotalHeadcount-@SAQ_OfficeHeadcount)
		SELECT @SAQ_CompanyRevenue = CONVERT(MONEY,  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_CompanyRevenue' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_TotalSpend = CONVERT(MONEY,  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_TotalSpend' AND dimSubmissionId = @dimSubmissionId;
		DECLARE @Currency nvarchar(10) = (SELECT TOP 1 [value] FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_Currency' AND dimSubmissionId = @dimSubmissionId);
		DECLARE @CurrencyRate decimal(10,2) = (SELECT TOP 1 rate FROM currency.CurrencyRate WHERE [currency] = @Currency);
		SELECT @SAQ_TotalSpendUSD = @SAQ_TotalSpend * (1/@CurrencyRate); --TODO Check its not devide by zero / NULL
		SELECT @SAQ_PercentageSpendOnServices = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_PercentageSpendOnServices' AND dimSubmissionId = @dimSubmissionId;
		SELECT @CALC_TotalSpendOnServices = (@SAQ_TotalSpendUSD*(@SAQ_PercentageSpendOnServices/100.0))
		SELECT @CALC_TotalSpendOnProducts = (@SAQ_TotalSpendUSD-@CALC_TotalSpendOnServices)
		SELECT @CALC_TotalSQM = (@MBD_SQM_PER_PERSON * @SAQ_OfficeHeadcount)
		SELECT @CALC_TotalRefrigerant = (@MBD_REFRIGERANT_KG_PER_PERSON * @SAQ_OfficeHeadcount)
		SELECT @CALC_TotalOtherFuel = (@MBD_OTHER_FUEL_PER_PERSON * @SAQ_OfficeHeadcount)

		SELECT @MBD_ELEC_KWH_PER_SQM = KWHPerSQM
			 FROM MBD.ElectricityConsumption
			WHERE @CALC_TotalSQM BETWEEN MinSQM AND ISNULL(MaxSQM, @CALC_TotalSQM);


		SELECT @MBD_GAS_KWH_PER_SQM = KWHPerSQM
			 FROM MBD.GasConsumption
			WHERE @CALC_TotalSQM BETWEEN MinSQM AND ISNULL(MaxSQM, @CALC_TotalSQM);

		--Electricity
		SELECT @CALC_AnnualElectric_Office = @CALC_TotalSQM * @MBD_ELEC_KWH_PER_SQM
		--Gas
		SELECT @CALC_AnnualGas_Office = @CALC_TotalSQM * @MBD_GAS_KWH_PER_SQM

		--Office/Other Commuting
		SELECT @SAQ_WorkingDaysAndCommuting_AvgDaysPerWeekWorked_Office = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_WorkingDaysAndCommuting_AvgDaysPerWeekWorked_Office' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_WorkingDaysAndCommuting_AvgDaysPerWeekWorked_Other = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_WorkingDaysAndCommuting_AvgDaysPerWeekWorked_Other' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_WorkingDaysAndCommuting_AvgDaysPerWeekCommuting_Office = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_WorkingDaysAndCommuting_AvgDaysPerWeekCommuting_Office' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_WorkingDaysAndCommuting_AvgDaysPerWeekCommuting_Other = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_WorkingDaysAndCommuting_AvgDaysPerWeekCommuting_Other' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_WorkingDaysAndCommuting_AvgDistance_Office = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_WorkingDaysAndCommuting_AvgDistance_Office' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_WorkingDaysAndCommuting_AvgDistance_Other = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_WorkingDaysAndCommuting_AvgDistance_Other' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_OfficeStaffPublicTransport = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_OfficeStaffPublicTransport' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_OtherStaffPublicTransport = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_OtherStaffPublicTransport' AND dimSubmissionId = @dimSubmissionId;

		--Office Calcs
		SELECT @CALC_AnnualDaysWorked_Office = @SAQ_WorkingDaysAndCommuting_AvgDaysPerWeekWorked_Office * @CALC_WeeksInYear * @SAQ_OfficeHeadcount
		SELECT @CALC_AnnualDaysCommute_Office = @SAQ_WorkingDaysAndCommuting_AvgDaysPerWeekCommuting_Office * @CALC_WeeksInYear * @SAQ_OfficeHeadcount
		SELECT @CALC_AnnualDistance_Office = @SAQ_WorkingDaysAndCommuting_AvgDistance_Office * 2 * @CALC_AnnualDaysCommute_Office
		SELECT @CALC_AnnualDaysHomeWorking_Office = @CALC_AnnualDaysWorked_Office-@CALC_AnnualDaysCommute_Office
		SELECT @CALC_AnnualCommutingDistance_Office_Public = @CALC_AnnualDistance_Office*(@SAQ_OfficeStaffPublicTransport/100.0)
		SELECT @CALC_AnnualCommutingDistance_Office_Private = @CALC_AnnualDistance_Office-@CALC_AnnualCommutingDistance_Office_Public

		--Waste
		SELECT @CALC_OfficeWaste_Recycling = (@CALC_AnnualDaysCommute_Office * @MBD_WASTE_RECYCLING_KG_PER_DAY) / 1000
		SELECT @CALC_OfficeWaste_Refuse = (@CALC_AnnualDaysCommute_Office * @MBD_WASTE_REFUSE_KG_PER_DAY) / 1000

		--Water
		SELECT @CALC_AnnualWater_Office = (@CALC_AnnualDaysCommute_Office * @MBD_WATER_LITRES_PER_DAY)/1000

		--Other Calcs
		SELECT @CALC_AnnualDaysWorked_Other = @SAQ_WorkingDaysAndCommuting_AvgDaysPerWeekWorked_Other * @CALC_WeeksInYear * @CALC_OtherHeadcount
		SELECT @CALC_AnnualDaysCommute_Other = @SAQ_WorkingDaysAndCommuting_AvgDaysPerWeekCommuting_Other * @CALC_WeeksInYear * @CALC_OtherHeadcount
		SELECT @CALC_AnnualDistance_Other = @SAQ_WorkingDaysAndCommuting_AvgDistance_Other * 2 * @CALC_WeeksInYear * @CALC_OtherHeadcount
		SELECT @CALC_AnnualDaysHomeWorking_Other = @CALC_AnnualDaysWorked_Other-@CALC_AnnualDaysCommute_Other
		SELECT @CALC_AnnualCommutingDistance_Other_Public = @CALC_AnnualDistance_Other*(@SAQ_OtherStaffPublicTransport/100.0)
		SELECT @CALC_AnnualCommutingDistance_Other_Private = @CALC_AnnualDistance_Other-@CALC_AnnualCommutingDistance_Other_Public

		--Company Vehicles
		SELECT @SAQ_CompanyVehiclesMileage_Cars = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_CompanyVehiclesMileage_Cars' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_CompanyVehiclesMileage_Vans = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_CompanyVehiclesMileage_Vans' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_CompanyVehiclesMileage_HGVs = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_CompanyVehiclesMileage_HGVs' AND dimSubmissionId = @dimSubmissionId;

		--Business Travel
		SELECT @SAQ_BusinessTravel_Domestic_Daily = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_BusinessTravel_Domestic_Daily' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_BusinessTravel_International_Daily = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_BusinessTravel_International_Daily' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_BusinessTravel_Domestic_Weekly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_BusinessTravel_Domestic_Weekly' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_BusinessTravel_International_Weekly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_BusinessTravel_International_Weekly' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_BusinessTravel_Domestic_Monthly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_BusinessTravel_Domestic_Monthly' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_BusinessTravel_International_Monthly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_BusinessTravel_International_Monthly' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_BusinessTravel_Domestic_Quarterly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_BusinessTravel_Domestic_Quarterly' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_BusinessTravel_International_Quarterly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_BusinessTravel_International_Quarterly' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_BusinessTravel_Domestic_Biannually = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_BusinessTravel_Domestic_Bi-annually' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_BusinessTravel_International_Biannually = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_BusinessTravel_International_Bi-annually' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_BusinessTravel_Domestic_Annually = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_BusinessTravel_Domestic_Annually' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_BusinessTravel_International_Annually = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_BusinessTravel_International_Annually' AND dimSubmissionId = @dimSubmissionId;

		--Annual Business Travel
		--Domestic
		SELECT @CALC_AnnualBusinessTravel_Domestic = ISNULL((@SAQ_BusinessTravel_Domestic_Daily * @SAQ_WorkingDaysAndCommuting_AvgDaysPerWeekWorked_Office * @CALC_WeeksInYear), 0)
													+ ISNULL((@SAQ_BusinessTravel_Domestic_Weekly * @CALC_WeeksInYear),0)
													+ ISNULL((@SAQ_BusinessTravel_Domestic_Monthly * 12),0)
													+ ISNULL((@SAQ_BusinessTravel_Domestic_Quarterly * 4),0)
													+ ISNULL((@SAQ_BusinessTravel_Domestic_Biannually * 2),0)
													+ ISNULL((@SAQ_BusinessTravel_Domestic_Annually),0)

		--International
		SELECT @CALC_AnnualBusinessTravel_International = ISNULL((@SAQ_BusinessTravel_International_Daily * @SAQ_WorkingDaysAndCommuting_AvgDaysPerWeekWorked_Office * @CALC_WeeksInYear), 0) 
													+ ISNULL((@SAQ_BusinessTravel_International_Weekly * @CALC_WeeksInYear), 0)
													+ ISNULL((@SAQ_BusinessTravel_International_Monthly * 12), 0)
													+ ISNULL((@SAQ_BusinessTravel_International_Quarterly * 4), 0)
													+ ISNULL((@SAQ_BusinessTravel_International_Biannually * 2), 0)
													+ ISNULL((@SAQ_BusinessTravel_International_Annually), 0)

		-- Goods Received
		SELECT @SAQ_GoodsReceived_Local_Daily = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsReceived_Local_Daily' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsReceived_National_Daily = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsReceived_National_Daily' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsReceived_International_Daily = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsReceived_International_Daily' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsReceived_Unknown_Daily = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsReceived_Unknown_Daily' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsReceived_Local_Weekly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsReceived_Local_Weekly' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsReceived_National_Weekly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsReceived_National_Weekly' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsReceived_International_Weekly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsReceived_International_Weekly' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsReceived_Unknown_Weekly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsReceived_Unknown_Weekly' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsReceived_Local_Monthly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsReceived_Local_Monthly' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsReceived_National_Monthly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsReceived_National_Monthly' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsReceived_International_Monthly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsReceived_International_Monthly' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsReceived_Unknown_Monthly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsReceived_Unknown_Monthly' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsReceived_Local_Quarterly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsReceived_Local_Quarterly' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsReceived_National_Quarterly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsReceived_National_Quarterly' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsReceived_International_Quarterly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsReceived_International_Quarterly' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsReceived_Unknown_Quarterly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsReceived_Unknown_Quarterly' AND dimSubmissionId = @dimSubmissionId;

		--Annual Goods Received
		--Local
		SELECT @CALC_AnnualGoodsReceived_Local = ((@SAQ_GoodsReceived_Local_Daily * @SAQ_WorkingDaysAndCommuting_AvgDaysPerWeekWorked_Office * @CALC_WeeksInYear)
												+ (@SAQ_GoodsReceived_Local_Weekly * @CALC_WeeksInYear)
												+ (@SAQ_GoodsReceived_Local_Monthly * 12)
												+ (@SAQ_GoodsReceived_Local_Quarterly *4))
												* @MBD_DELIVERY_LOCAL_KMS
												/1000
		--National
		SELECT @CALC_AnnualGoodsReceived_National = ((@SAQ_GoodsReceived_National_Daily * @SAQ_WorkingDaysAndCommuting_AvgDaysPerWeekWorked_Office * @CALC_WeeksInYear)
												+ (@SAQ_GoodsReceived_National_Weekly * @CALC_WeeksInYear)
												+ (@SAQ_GoodsReceived_National_Monthly * 12)
												+ (@SAQ_GoodsReceived_National_Quarterly *4))
												* @MBD_DELIVERY_NATIONAL_KMS
												/1000
		--International
		SELECT @CALC_AnnualGoodsReceived_International = ((@SAQ_GoodsReceived_International_Daily * @SAQ_WorkingDaysAndCommuting_AvgDaysPerWeekWorked_Office * @CALC_WeeksInYear)
												+ (@SAQ_GoodsReceived_International_Weekly * @CALC_WeeksInYear)
												+ (@SAQ_GoodsReceived_International_Monthly * 12)
												+ (@SAQ_GoodsReceived_International_Quarterly *4))
												* @MBD_DELIVERY_INTERNATIONAL_KMS
												/1000
		--Unknown
		SELECT @CALC_AnnualGoodsReceived_Unknown = ((@SAQ_GoodsReceived_Unknown_Daily * @SAQ_WorkingDaysAndCommuting_AvgDaysPerWeekWorked_Office * @CALC_WeeksInYear)
												+ (@SAQ_GoodsReceived_Unknown_Weekly * @CALC_WeeksInYear)
												+ (@SAQ_GoodsReceived_Unknown_Monthly * 12)
												+ (@SAQ_GoodsReceived_Unknown_Quarterly *4))
												* @MBD_DELIVERY_UNKNOWN_KMS
												/1000
		-- Goods Sent

		SELECT @SAQ_GoodsSent_Local_Daily = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsSent_Local_Daily' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsSent_National_Daily = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsSent_National_Daily' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsSent_International_Daily = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsSent_International_Daily' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsSent_Unknown_Daily = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsSent_Unknown_Daily' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsSent_Local_Weekly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsSent_Local_Weekly' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsSent_National_Weekly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsSent_National_Weekly' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsSent_International_Weekly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsSent_International_Weekly' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsSent_Unknown_Weekly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsSent_Unknown_Weekly' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsSent_Local_Monthly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsSent_Local_Monthly' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsSent_National_Monthly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsSent_National_Monthly' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsSent_International_Monthly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsSent_International_Monthly' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsSent_Unknown_Monthly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsSent_Unknown_Monthly' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsSent_Local_Quarterly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsSent_Local_Quarterly' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsSent_National_Quarterly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsSent_National_Quarterly' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsSent_International_Quarterly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsSent_International_Quarterly' AND dimSubmissionId = @dimSubmissionId;
		SELECT @SAQ_GoodsSent_Unknown_Quarterly = CONVERT(NUMERIC(10,2),  NULLIF(trim([value]), '')) FROM forms.blueawardquestionnaire WHERE [key] = 'BAQ_GoodsSent_Unknown_Quarterly' AND dimSubmissionId = @dimSubmissionId;

		--Annual Goods Sent
		--Local
		SELECT @CALC_AnnualGoodsSent_Local = ((@SAQ_GoodsSent_Local_Daily * @SAQ_WorkingDaysAndCommuting_AvgDaysPerWeekWorked_Office * @CALC_WeeksInYear)
												+ (@SAQ_GoodsSent_Local_Weekly * @CALC_WeeksInYear)
												+ (@SAQ_GoodsSent_Local_Monthly * 12)
												+ (@SAQ_GoodsSent_Local_Quarterly *4))
												* @MBD_DELIVERY_LOCAL_KMS
												/1000
		--National
		SELECT @CALC_AnnualGoodsSent_National = ((@SAQ_GoodsSent_National_Daily * @SAQ_WorkingDaysAndCommuting_AvgDaysPerWeekWorked_Office * @CALC_WeeksInYear)
												+ (@SAQ_GoodsSent_National_Weekly * @CALC_WeeksInYear)
												+ (@SAQ_GoodsSent_National_Monthly * 12)
												+ (@SAQ_GoodsSent_National_Quarterly *4))
												* @MBD_DELIVERY_NATIONAL_KMS
												/1000
		--International
		SELECT @CALC_AnnualGoodsSent_International = ((@SAQ_GoodsSent_International_Daily * @SAQ_WorkingDaysAndCommuting_AvgDaysPerWeekWorked_Office * @CALC_WeeksInYear)
												+ (@SAQ_GoodsSent_International_Weekly * @CALC_WeeksInYear)
												+ (@SAQ_GoodsSent_International_Monthly * 12)
												+ (@SAQ_GoodsSent_International_Quarterly *4))
												* @MBD_DELIVERY_INTERNATIONAL_KMS
												/1000
		--Unknown
		SELECT @CALC_AnnualGoodsSent_Unknown = ((@SAQ_GoodsSent_Unknown_Daily * @SAQ_WorkingDaysAndCommuting_AvgDaysPerWeekWorked_Office * @CALC_WeeksInYear)
												+ (@SAQ_GoodsSent_Unknown_Weekly * @CALC_WeeksInYear)
												+ (@SAQ_GoodsSent_Unknown_Monthly * 12)
												+ (@SAQ_GoodsSent_Unknown_Quarterly *4))
												* @MBD_DELIVERY_UNKNOWN_KMS
												/1000

		INSERT INTO @result (category, total, dataunit, bmCategory, [order])
		SELECT 'Spend on services' AS category, @CALC_TotalSpendOnServices AS total, 'currency' AS dataunit, 'Purchased Goods and Services' as bmCategory, 12 as [order]
		UNION
		SELECT 'Spend on products', @CALC_TotalSpendOnProducts, 'currency', 'Purchased Goods and Services', 12
		UNION
		SELECT 'Homeworking hours', (@CALC_AnnualDaysHomeWorking_Office+@CALC_AnnualDaysHomeWorking_Other)*@CALC_HoursPerDay, 'hours', 'Home Working', 7.5
		UNION
		SELECT 'Office commuting distance public transport', @CALC_AnnualCommutingDistance_Office_Public, 'km', 'Commuting', 7
		UNION
		SELECT 'Office commuting distance private transport', @CALC_AnnualCommutingDistance_Office_Private, 'km', 'Commuting', 7
		UNION
		SELECT 'Other commuting distance public transport', @CALC_AnnualCommutingDistance_Other_Public, 'km', 'Commuting', 7
		UNION
		SELECT 'Other commuting distance private transport', @CALC_AnnualCommutingDistance_Other_Private, 'km', 'Commuting', 7
		UNION 
		SELECT 'Company vehicle distance cars', @SAQ_CompanyVehiclesMileage_Cars, 'km', 'Company Vehicles', 4
		UNION 	
		SELECT 'Company vehicle distance vans', @SAQ_CompanyVehiclesMileage_Vans, 'km', 'Company Vehicles', 4
		UNION 	
		SELECT 'Company vehicle distance HGVs', @SAQ_CompanyVehiclesMileage_HGVs, 'km', 'Company Vehicles', 4
		UNION	
		SELECT 'Goods received local', @CALC_AnnualGoodsReceived_Local, 't-km', 'Downstream Deliveries', 11
		UNION	
		SELECT 'Goods received national', @CALC_AnnualGoodsReceived_National, 't-km', 'Downstream Deliveries', 11
		UNION
		SELECT 'Goods received international', @CALC_AnnualGoodsReceived_International, 't-km', 'Downstream Deliveries', 11
		UNION	
		SELECT 'Goods received unknown', @CALC_AnnualGoodsReceived_Unknown, 't-km', 'Downstream Deliveries', 11
		UNION	
		SELECT 'Goods sent local', @CALC_AnnualGoodsSent_Local, 't-km', 'Upstream Deliveries', 10
		UNION	
		SELECT 'Goods sent national', @CALC_AnnualGoodsSent_National, 't-km', 'Upstream Deliveries', 10
		UNION	
		SELECT 'Goods sent international', @CALC_AnnualGoodsSent_International, 't-km', 'Upstream Deliveries', 10
		UNION	
		SELECT 'Goods sent unknown', @CALC_AnnualGoodsSent_Unknown, 't-km', 'Upstream Deliveries', 10
		UNION 
		SELECT 'Business travel domestic', @CALC_AnnualBusinessTravel_Domestic, 'days', 'Business Travel - Domestic', 6
		UNION 
		SELECT 'Business travel international', @CALC_AnnualBusinessTravel_International, 'days', 'Business Travel - International', 6
		UNION
		SELECT 'Electricity usage office', @CALC_AnnualElectric_Office, 'kWh', 'Electricity', 5
		UNION
		SELECT 'Refrigerent usage office', @CALC_TotalRefrigerant, 'kg', 'Refrigerents', 2
		UNION
		SELECT 'Other fuels usage office', @CALC_TotalOtherFuel, 'tonnes/kWh/liters', 'Other Fuels', 3
		UNION
		SELECT 'Gas usage office', @CALC_AnnualGas_Office, 'kWh', 'Natural Gas', 1
		UNION
		SELECT 'Water usage office', @CALC_AnnualWater_Office, 'Cubic Meters', 'Water', 9
		UNION 
		SELECT 'Office recycling', @CALC_OfficeWaste_Recycling, 'tonnes', 'Waste and Recycling', 8
		UNION 
		SELECT 'Office refuse', @CALC_OfficeWaste_Refuse, 'tonnes', 'Waste and Recycling', 8
		UNION 
		SELECT 'Office headcount', @SAQ_OfficeHeadcount, 'person', '', 13
		UNION 
		SELECT 'Other headcount', @CALC_OtherHeadcount, 'person', '', 13

    RETURN;
END;
GO


-- ----------------------------
-- procedure structure for spSilver_DataOutputByScope_Portal
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[DataModel].[spSilver_DataOutputByScope_Portal]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [DataModel].[spSilver_DataOutputByScope_Portal]
GO

CREATE PROCEDURE [DataModel].[spSilver_DataOutputByScope_Portal] 
	@BAQSubmissionid BIGINT,
	@silverSubmissionIds nvarchar(MAX) = NULL,
    @CHWSubmissionIds nvarchar(MAX) = NULL,
	@emissionProfileId INT = 1,
	@dataInsert int = 0
AS
BEGIN
	
	CREATE TABLE #BAQData (
    category NVARCHAR(255),
    total DECIMAL(18, 2),
    dataUnit NVARCHAR(50),
    bmCategory NVARCHAR(255),
		[order] DECIMAL(5,2)
	);

	INSERT INTO #BAQData (category, total, dataUnit, bmCategory, [order])
  SELECT category, total, dataUnit, bmCategory, [order]
  FROM DataModel.fnSAQ_DataOutput_Portal(@BAQSubmissionid); 

	CREATE TABLE #BAQDataWithBM (
    category NVARCHAR(1000),
    total DECIMAL(18, 2),
    dataUnit NVARCHAR(50),
    bmCategory NVARCHAR(255),
		[order] DECIMAL(5,2),
		EF DECIMAL(18, 2),
		WTT DECIMAL(18, 2),
		TND DECIMAL(18, 2),
		TNDWTT DECIMAL(18, 2)
	);

	-- Totals by activity from our data collection
	WITH CTE_INPUT_TOTALS_BY_ACTIVITY AS (
				SELECT
						CONVERT(DATE,GETDATE()) AS Date,
						formName,  
						PercentageOfTotal,
						Utilities.GetEF(t.emissionActivityId, @emissionProfileId) as EF,
						Utilities.GetWTT(t.emissionActivityId, @emissionProfileId) as WTT, 
						Utilities.GetTND(t.emissionActivityId, @emissionProfileId) as TND, 
						Utilities.GetTNDWTT(t.emissionActivityId, @emissionProfileId) as TNDWTT
			 FROM DataModel.InputTotalsByActivity t
			 LEFT JOIN Emissions.EmissionFactor e ON e.activityId = t.emissionActivityId AND e.emissionProfileId = @emissionProfileId
	)

	-- Calculate Benchmark data
	,CTE_BENCHMARKS_BY_CATEGORY AS (
				SELECT
						CONVERT(DATE,GETDATE()) AS Date,
						formName AS Category,  
						SUM(PercentageOfTotal*ef) AS EF,
						SUM(PercentageOfTotal*wtt) AS WTT,
						SUM(PercentageOfTotal*tnd) AS TND,
						SUM(PercentageOfTotal*tndwtt) AS TNDWTT
			 FROM CTE_INPUT_TOTALS_BY_ACTIVITY
			 GROUP BY formname
	)

	,CTE_FINAL AS (
		 SELECT baq.category, 
						baq.total, 
						baq.dataunit, 
						baq.bmCategory, 
						baq.[order],
						bm.EF, 	
						bm.WTT, 
						bm.TND, 
						bm.TNDWTT
			 FROM #BAQData baq
	LEFT JOIN [CTE_BENCHMARKS_BY_CATEGORY] bm ON baq.bmCategory = bm.category
 )

-- BAQ data group by category.
	INSERT INTO #BAQDataWithBM (category, total, dataUnit, bmCategory, [order], ef, wtt, tnd, tndwtt)
	SELECT  STRING_AGG([Category], ', ') as [Sub Categories],
				SUM(total) as [Total],
				MAX(dataUnit) as [dataUnit],
				bmCategory,
				MAX([order]) as [Order],
				SUM(total * ef) as TotalEF, 
				SUM(total * wtt) as TotalWTT,
				SUM(total * tnd) as TotalTND, 
				SUM(total * tndwtt) as TotalTNDWTT
		FROM CTE_FINAL 
		GROUP BY bmCategory;

  -- C&HW submissions data and calculation 
    /* C&HW EF total formula, 
       - Commuting, (Total EF/ No of submissions ) * Commuting Head count
       - Home working, (Total EF/ No of submissions ) * Home working Head count
    */
    Declare @HomeWorkingSubmissionIds NVARCHAR(MAX), @CommutingSubmissionIds NVARCHAR(MAX);
    Declare @HomeWorkingSubmissionCount int, @CommutingSubmissionCount int;
    Declare @HomeWorkingHeadCount NUMERIC(10,2), @CommutingHeadCount NUMERIC(10,2);
    
    Select @HomeWorkingHeadCount = cast(BAQ_OfficeHeadcount as NUMERIC(10,2)), 
           @CommutingHeadCount = cast(BAQ_TotalHeadcount as NUMERIC(10,2)) - cast( BAQ_OfficeHeadcount as NUMERIC(10,2))
    From DataModel.BlueAwardSubmissionData Where dimSubmissionId = @BAQSubmissionid;
    
    CREATE TABLE #CHWSubmissions (
          submissionId int, -- dimension's submissionId
          CHWType NVARCHAR(50)
      );

    INSERT INTO #CHWSubmissions (submissionId, CHWType)
    SELECT DISTINCT submissionId, 
           CASE 
               WHEN emissionActivityId IN (357, 358, 359) THEN 'HOME_WORKING' 
               ELSE 'COMMUTING' 
           END AS CHWType
    FROM DataModel.vSilverSubmissions 
    WHERE submissionId IN (
          SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@CHWSubmissionIds, ',')
      );
      
    -- Get Emission data for C&HW (Home working)
    Select @HomeWorkingSubmissionCount = COUNT(*),
           @HomeWorkingSubmissionIds = STRING_AGG(CAST(submissionId AS NVARCHAR(MAX)), ',')
    From #CHWSubmissions
    Where CHWType='HOME_WORKING'; 

    CREATE TABLE #HomeWorkingData (
        formName NVARCHAR(255),
        category NVARCHAR(255),
        TotalEF DECIMAL(18, 2),
        TotalWTT DECIMAL(18, 2),
        TotalTND DECIMAL(18, 2),
        TotalTNDWTT DECIMAL(18, 2),
        isMBD INT
      );
    
    INSERT INTO #HomeWorkingData (formName, category, TotalEF, TotalWTT, TotalTND, TotalTNDWTT, isMBD)
    SELECT formName, category, TotalEF, TotalWTT, TotalTND, TotalTNDWTT, isMBD
    FROM DataModel.fnSilver_DataOutput_Portal(@HomeWorkingSubmissionIds, @emissionProfileId); 
    
    Update #HomeWorkingData 
      set TotalEF = (TotalEF / @HomeWorkingSubmissionCount) * @HomeWorkingHeadCount,
          TotalWTT = (TotalWTT / @HomeWorkingSubmissionCount) * @HomeWorkingHeadCount,
          TotalTND = (TotalTND / @HomeWorkingSubmissionCount) * @HomeWorkingHeadCount,
          TotalTNDWTT = (TotalTNDWTT / @HomeWorkingSubmissionCount) * @HomeWorkingHeadCount;
          
    -- Get Emission data for C&HW (Commuting)
    Select @CommutingSubmissionCount = COUNT(*),
           @CommutingSubmissionIds = STRING_AGG(CAST(submissionId AS NVARCHAR(MAX)), ',')
    From #CHWSubmissions
    Where CHWType='COMMUTING';
    
    CREATE TABLE #CommutingData (
			formName NVARCHAR(255),
			category NVARCHAR(255),
			TotalEF DECIMAL(18, 2),
			TotalWTT DECIMAL(18, 2),
			TotalTND DECIMAL(18, 2),
			TotalTNDWTT DECIMAL(18, 2),
      isMBD INT
		);

    INSERT INTO #CommutingData (formName, category, TotalEF, TotalWTT, TotalTND, TotalTNDWTT, isMBD)
    SELECT formName, category, TotalEF, TotalWTT, TotalTND, TotalTNDWTT, isMBD
    FROM DataModel.fnSilver_DataOutput_Portal(@CommutingSubmissionIds, @emissionProfileId); 
    
    Update #CommutingData 
      set TotalEF = (TotalEF / @CommutingSubmissionCount) * @CommutingHeadCount,
          TotalWTT = (TotalWTT / @CommutingSubmissionCount) * @CommutingHeadCount,
          TotalTND = (TotalTND / @CommutingSubmissionCount) * @CommutingHeadCount,
          TotalTNDWTT = (TotalTNDWTT / @CommutingSubmissionCount) * @CommutingHeadCount;

  -- Get the silver submission data
    CREATE TABLE #SilverData (
        formName NVARCHAR(255),
        category NVARCHAR(255),
        TotalEF DECIMAL(18, 2),
        TotalWTT DECIMAL(18, 2),
        TotalTND DECIMAL(18, 2),
        TotalTNDWTT DECIMAL(18, 2),
        isMBD INT
      );
		
	INSERT INTO #SilverData (formName, category, TotalEF, TotalWTT, TotalTND, TotalTNDWTT, isMBD)
  SELECT formName, category, TotalEF, TotalWTT, TotalTND, TotalTNDWTT, isMBD
  FROM DataModel.fnSilver_DataOutput_Portal(@silverSubmissionIds, @emissionProfileId); 
  
  INSERT INTO #SilverData (formName, category, TotalEF, TotalWTT, TotalTND, TotalTNDWTT, isMBD)
  Select formName, category, TotalEF, TotalWTT, TotalTND, TotalTNDWTT, isMBD from #HomeWorkingData;
  
  INSERT INTO #SilverData (formName, category, TotalEF, TotalWTT, TotalTND, TotalTNDWTT, isMBD)
  Select formName, category, TotalEF, TotalWTT, TotalTND, TotalTNDWTT, isMBD from #CommutingData;
	-- select * from #SilverData;
  DECLARE @scope1Categories NVARCHAR(MAX) = 'Natural Gas,Company Vehicles,Refrigerents,Other Fuels';
	DECLARE @scope2Categories NVARCHAR(MAX) = 'Electricity';
	DECLARE @scope3Categories NVARCHAR(MAX) = 'Business Travel - Domestic,Business Travel - International,Commuting,Home Working,Waste and Recycling,Water,Upstream Deliveries,Downstream Deliveries,Purchased Goods and Services';
  
/*	DECLARE @scope1Categories NVARCHAR(MAX) = 'Natural Gas,Company Vehicles (KM),Company Vehicles (Electricity),Company Vehicles (No of litre - Diesel),Company Vehicles (No of litre - Petrol),Company Vehicles (Currency),Refrigerents,Other Fuels';
	DECLARE @scope2Categories NVARCHAR(MAX) = 'Electricity';
	DECLARE @scope3Categories NVARCHAR(MAX) = 'Business Travel - Domestic (KM),Business Travel - International (KM),Business Travel - Domestic (Currency),Business Travel - Domestic (No of litre - Diesel),Business Travel - Domestic (No of litre - Petrol),Business Travel - Domestic (Hotel Stay),Business Travel - International (Hotel Stay),Business Travel - Amount Spend (Hotel Stay),Commuting,Home Working,Waste and Recycling,Water,Upstream Deliveries,Downstream Deliveries,Purchased Goods and Services';
*/
	DECLARE @totalScope1 DECIMAL(18,2) = (SELECT SUM(COALESCE(s.totalEF, CASE WHEN isMBD = 1 THEN b.EF ELSE 0 END))
																					FROM #BAQDataWithBM b LEFT JOIN #SilverData s ON s.category = b.bmCategory 
																				 WHERE b.bmCategory in (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@scope1Categories, ',')));
	
	DECLARE @totalScope2 DECIMAL(18,2) = (SELECT SUM(COALESCE(s.totalEF, CASE WHEN isMBD = 1 THEN b.EF ELSE 0 END))
																					FROM #BAQDataWithBM b LEFT JOIN #SilverData s ON s.category = b.bmCategory 
																				 WHERE b.bmCategory in (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@scope2Categories, ',')));
																				 
	DECLARE @totalScope3EF DECIMAL(18,2) = (SELECT SUM(COALESCE(s.totalEF, CASE WHEN isMBD = 1 THEN b.EF ELSE 0 END))
																					FROM #BAQDataWithBM b LEFT JOIN #SilverData s ON s.category = b.bmCategory 
																				 WHERE b.bmCategory in (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@scope3Categories, ',')));
	
	DECLARE @totalScope3WTT DECIMAL(18,2) =  (SELECT SUM(COALESCE(s.totalWTT, CASE WHEN isMBD = 1 THEN b.WTT ELSE 0 END)) + 
                                                   SUM(COALESCE(s.totalTND, CASE WHEN isMBD = 1 THEN b.TND ELSE 0 END)) + 
                                                   SUM(COALESCE(s.totalTNDWTT, CASE WHEN isMBD = 1 THEN b.TNDWTT ELSE 0 END))
																					FROM #BAQDataWithBM b LEFT JOIN #SilverData s ON s.category = b.bmCategory 
																				 WHERE NULLIF(b.bmCategory, '') IS NOT NULL);
	
	DECLARE @totalScope3 DECIMAL(10,2) = @totalScope3EF + @totalScope3WTT;
	DECLARE @company nvarchar(500), @headCount NUMERIC(10,2), @revenue nvarchar(50), @submissionDate DATETIME, @name nvarchar(100), @email nvarchar(100), @jobtitle nvarchar(100), @startDate nvarchar(25), @endDate nvarchar(25), @certId int;
	
  SELECT @company = c.companyName,
         @headCount = cert.headCount, @revenue = cert.revenue,
         @submissionDate = cfs.dateSubmitted, @certId = cfs.certId, 
				 @name = c.contactName, @email = c.email, @jobtitle = c.jobtitle,
         @startDate = cert.startDate, @endDate = cert.endDate
		FROM portal.CertFormSubmissions as cfs 
    INNER JOIN portal.Certification as cert on (cfs.certId = cert.certId)
    INNER JOIN portal.Company as c on (c.companyId = cert.companyId)
		WHERE cfs.dimSubmissionId = @BAQSubmissionid;
 

	--SCOPE BASED CALCULATIONS
	
IF @dataInsert = 1
BEGIN
	
	IF EXISTS (
        SELECT 1
        FROM Reports.silverAwardByScope
        WHERE submissionId = @BAQSubmissionid
    )
    BEGIN
        DELETE
        FROM Reports.silverAwardByScope
        WHERE submissionId = @BAQSubmissionid;
    END;

	INSERT
	INTO
	Reports.silverAwardByScope
    (
    certId,
    orderNo,
	submissionId,
	submissionDate,
	companyName,
	headCount,
	revenue,
	[scope],
	category,
	subCategories,
	totalKgCO2e,
	pctOfTotalEmissionsScope,
	isModelled,
	contactName,
	email,
	jobTitle,
	reportStartDate,
	reportEndDate,
	createdDate
    )
    SELECT
    @certId,
	X.orderNo,
	@BAQSubmissionid,
	@submissionDate,
	@company,
	@headCount,
	@revenue,
	X.Scope,
	X.Category,
	STRING_AGG(X.SubCategory, ', '),
	SUM(IsNull(X.TotalKgCO2e,0)),
	SUM(IsNull(X.Pct,0)),
	X.IsModelled,
	@name,
	@email,
	@jobtitle,
	@startDate,
	@endDate,
	GETDATE()
FROM
	(
	SELECT 
				[order] as orderNo,
				'Scope-1' as Scope, 
				b.bmCategory as [Category], 
				b.category as [SubCategory], 
				(CASE WHEN s.isMBD = 1 THEN CAST((IsNull(b.EF,0)) as DECIMAL(18,2)) 
						 ELSE CAST((IsNull(s.totalEF,0)) as DECIMAL(18,2)) 
				END) as TotalKgCO2e, 
				CAST(CASE WHEN @totalScope1 = 0 THEN 0 ELSE 
					(CASE 
						WHEN s.isMBD = 1 THEN ((IsNull(b.EF,0)) / @totalScope1) * 100 
						ELSE (IsNull(s.totalEF,0) / @totalScope1) * 100 
					END)
				END AS DECIMAL(18,2)) as Pct,
        Case When s.isMBD = 1 Then 1 Else 0 END as [IsModelled]
		FROM #BAQDataWithBM b
	LEFT JOIN #SilverData s ON b.bmCategory = s.category
	 WHERE b.bmCategory in (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@scope1Categories, ','))

	UNION
	
	SELECT
		100 AS orderNo,
		'Scope-1' AS Scope,
		'Total Scope-1' AS Category,
		'' AS SubCategory,
		@totalScope1 AS TotalKgCO2e,
		100 AS Pct,
		0 AS IsModelled
	
	UNION

	-- SCOPE 2 Calculations
	SELECT 
				[order] as orderNo,
				'Scope-2' as Scope, 
				b.bmCategory as [Category], 
				b.category as [SubCategory],
				(CASE WHEN s.isMBD = 1 THEN CAST((IsNull(b.EF,0)) as DECIMAL(18,2)) 
						 ELSE CAST((IsNull(s.totalEF,0)) as DECIMAL(18,2)) 
				END) as TotalKgCO2e, 
				CAST(CASE WHEN @totalScope2 = 0 THEN 0 ELSE 
					(CASE 
						WHEN s.isMBD = 1 THEN ((IsNull(b.EF,0)) / @totalScope2) * 100 
						ELSE (IsNull(s.totalEF,0) / @totalScope2) * 100 
					END)
				END AS DECIMAL(18,2)) as Pct,
        Case When s.isMBD = 1 Then 1 Else 0 END as [IsModelled]
		FROM #BAQDataWithBM b
	LEFT JOIN #SilverData s ON b.bmCategory = s.category
	 WHERE b.bmCategory in (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@scope2Categories, ','))

	UNION
	
	SELECT
        100 AS orderNo,
        'Scope-2' AS Scope,
        'Total Scope-2' AS Category,
        '' AS SubCategory,
        @totalScope2 AS TotalKgCO2e,
        100 AS Pct,
        0 AS IsModelled
	
	UNION

	-- SCOPE 3 Calculations
	SELECT 
					[order] as orderNo,
					'Scope-3' as Scope, 
					b.bmCategory as [Category], 
					b.category as [SubCategory], 
					(CASE WHEN s.isMBD = 1 THEN CAST((IsNull(b.EF,0)) as DECIMAL(18,2)) 
						 ELSE CAST((IsNull(s.totalEF,0)) as DECIMAL(18,2)) 
					END) as TotalKgCO2e, 
					CAST(CASE WHEN @totalScope3 = 0 THEN 0 ELSE 
						(CASE 
							WHEN s.isMBD = 1 THEN ((IsNull(b.EF,0)) / @totalScope3) * 100 
							ELSE (IsNull(s.totalEF,0) / @totalScope3) * 100 
						END)
					END AS DECIMAL(18,2)) as Pct,
          Case When s.isMBD = 1 Then 1 Else 0 END as [IsModelled]
			FROM #BAQDataWithBM b
	LEFT JOIN #SilverData s ON b.bmCategory = s.category
	 WHERE b.bmCategory in (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@scope3Categories, ','))
	
	UNION

	-- SCOPE 3 WTT Calculations
	SELECT 
					b.[order] as orderNo,
					'Scope-3' as Scope, 
					CONCAT('WTT-',b.bmCategory) as [Category], 
					CONCAT('WTT-',b.category) as [SubCategory],
					(CASE WHEN s.isMBD = 1 THEN CAST(((ISNULL(b.WTT, 0) + ISNULL(b.TND, 0) + ISNULL(b.TNDWTT, 0))) as DECIMAL(18,2)) 
						 ELSE CAST(((ISNULL(TotalWTT, 0) + ISNULL(TotalTND, 0) + ISNULL(TotalTNDWTT, 0))) as DECIMAL(18,2))
					END) as TotalKgCO2e, 
					CAST(CASE WHEN @totalScope3 = 0 THEN 0 ELSE 
						(CASE 
							WHEN s.isMBD = 1 THEN CAST((((ISNULL(b.WTT, 0) + ISNULL(b.TND, 0) + ISNULL(b.TNDWTT, 0))) / @totalScope3) * 100 AS DECIMAL(18,2))
							ELSE CAST((((ISNULL(totalWTT, 0) + ISNULL(TotalTND, 0) + ISNULL(TotalTNDWTT, 0))) / @totalScope3) * 100 AS DECIMAL(18,2)) 
						END)
					END AS DECIMAL(18,2)) as Pct,
          Case When s.isMBD = 1 Then 1 Else 0 END as [IsModelled]
		FROM #BAQDataWithBM b
		LEFT JOIN #SilverData s ON b.bmCategory = s.category
	 WHERE NULLIF(bmCategory, '') IS NOT NULL AND bmCategory NOT IN ('Purchased Goods and Services','Waste and Recycling')
	
	UNION
	
	 SELECT
        100 AS orderNo,
        'Scope-3' AS Scope,
        'Total Scope-3' AS Category,
        '' AS SubCategory,
        @totalScope3 AS TotalKgCO2e,
        100 AS Pct,
        0 AS IsModelled

) X
GROUP BY X.orderNo, X.Scope, X.Category, X.IsModelled;

END
ELSE
BEGIN	
	

SELECT MAX(id) as [ID], MAX([order]) as [Order], @BAQSubmissionid as [Submission Id], @submissionDate as [Submission Date], @company as [Company], @headCount as [Head Count], @revenue as [Revenue],
			 [Scope], [Category], STRING_AGG([Sub Category], ', ') as [Sub Categories], SUM(ISNULL([Total Kg CO2e], 0)) as [Total Kg CO2e], 
       SUM(ISNULL([% of total emissions scope wise], 0)) as [% of total emissions scope wise], [IsModelled],
       @name as [Name], @email as [Email], @jobtitle as [Job Title], @startDate as [Report Start Date], @endDate as [Report End Date]
 FROM (
	-- SCOPE 1 Calculations
	SELECT 1 as [id], 
				[order],
				'Scope-1' as Scope, 
				b.bmCategory as [Category], 
				b.category as [Sub Category], 
				(CASE WHEN s.isMBD = 1 THEN CAST((b.EF) as DECIMAL(18,2)) 
						 ELSE CAST((s.totalEF) as DECIMAL(18,2)) 
				END) as [Total Kg CO2e], 
				CAST(CASE WHEN @totalScope1 = 0 THEN 0 ELSE 
					(CASE 
						WHEN s.isMBD = 1 THEN ((b.EF) / @totalScope1) * 100 
						ELSE (s.totalEF / @totalScope1) * 100 
					END)
				END AS DECIMAL(18,2)) as [% of total emissions scope wise],
        Case When s.isMBD = 1 Then 1 Else 0 END as [IsModelled]
		FROM #BAQDataWithBM b
	LEFT JOIN #SilverData s ON b.bmCategory = s.category
	 WHERE b.bmCategory in (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@scope1Categories, ','))

	UNION
	
	SELECT 2 as [id], '100', 'Total Scope-1' as [Scope], '', '', @totalScope1, '100' , 0
	
	UNION

	-- SCOPE 2 Calculations
	SELECT 3 as [id], 
				[order],
				'Scope-2' as Scope, 
				b.bmCategory as [Category], 
				b.category as [Sub Category],
				(CASE WHEN s.isMBD = 1 THEN CAST((b.EF) as DECIMAL(18,2)) 
						 ELSE CAST((s.totalEF) as DECIMAL(18,2)) 
				END) as [Total Kg CO2e], 
				CAST(CASE WHEN @totalScope2 = 0 THEN 0 ELSE 
					(CASE 
						WHEN s.isMBD = 1 THEN ((b.EF) / @totalScope2) * 100 
						ELSE (s.totalEF / @totalScope2) * 100 
					END)
				END AS DECIMAL(18,2)) as [% of total emissions scope wise],
        Case When s.isMBD = 1 Then 1 Else 0 END as [IsModelled]
		FROM #BAQDataWithBM b
	LEFT JOIN #SilverData s ON b.bmCategory = s.category
	 WHERE b.bmCategory in (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@scope2Categories, ','))

	UNION
	
	SELECT 4 as [id], '100', 'Total Scope-2' ,'', '',  @totalScope2 , '100' , 0
	
	UNION

	-- SCOPE 3 Calculations
	SELECT 5 as [id], 
					[order],
					'Scope-3', 
					b.bmCategory, 
					b.category, 
					(CASE WHEN s.isMBD = 1 THEN CAST((b.EF) as DECIMAL(18,2)) 
						 ELSE CAST((s.totalEF) as DECIMAL(18,2)) 
					END) as [Total Kg CO2e], 
					CAST(CASE WHEN @totalScope3 = 0 THEN 0 ELSE 
						(CASE 
							WHEN s.isMBD = 1 THEN ((b.EF) / @totalScope3) * 100 
							ELSE (s.totalEF / @totalScope3) * 100 
						END)
					END AS DECIMAL(18,2)) as [% of total emissions scope wise],
          Case When s.isMBD = 1 Then 1 Else 0 END as [IsModelled]
			FROM #BAQDataWithBM b
	LEFT JOIN #SilverData s ON b.bmCategory = s.category
	 WHERE b.bmCategory in (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@scope3Categories, ','))
	
	UNION

	-- SCOPE 3 WTT Calculations
	SELECT 6 as [id], 
					b.[order],
					'Scope-3' as Scope, 
					CONCAT('WTT-',b.bmCategory), 
					CONCAT('WTT-',b.category),
					(CASE WHEN s.isMBD = 1 THEN CAST(((ISNULL(b.WTT, 0) + ISNULL(b.TND, 0) + ISNULL(b.TNDWTT, 0))) as DECIMAL(18,2)) 
						 ELSE CAST(((ISNULL(TotalWTT, 0) + ISNULL(TotalTND, 0) + ISNULL(TotalTNDWTT, 0))) as DECIMAL(18,2))
					END) as [Total Kg CO2e], 
					CAST(CASE WHEN @totalScope3 = 0 THEN 0 ELSE 
						(CASE 
							WHEN s.isMBD = 1 THEN CAST((((ISNULL(b.WTT, 0) + ISNULL(b.TND, 0) + ISNULL(b.TNDWTT, 0))) / @totalScope3) * 100 AS DECIMAL(18,2))
							ELSE CAST((((ISNULL(totalWTT, 0) + ISNULL(TotalTND, 0) + ISNULL(TotalTNDWTT, 0))) / @totalScope3) * 100 AS DECIMAL(18,2)) 
						END)
					END AS DECIMAL(18,2)) as [% of total emissions scope wise],
          Case When s.isMBD = 1 Then 1 Else 0 END as [IsModelled]
		FROM #BAQDataWithBM b
		LEFT JOIN #SilverData s ON b.bmCategory = s.category
	 WHERE NULLIF(bmCategory, '') IS NOT NULL AND bmCategory NOT IN ('Purchased Goods and Services','Waste and Recycling')
	
	UNION
	
	SELECT 7 as [id], '100', 'Total Scope-3','', '', @totalScope3, '100', 0

) as tbl 	
	GROUP BY [Scope], [Category], [IsModelled]
	ORDER BY [id], [order]
	
END	

-- 	SELECT * FROM #BAQData;
-- 	SELECT * FROM #SilverData;
-- 	SELECT * FROM #BAQDataWithBM;
-- 	SELECT @totalScope3EF as totalScope3EF, @totalScope3WTT as totalScope3WTT;
	
	DROP TABLE #BAQData;
	DROP TABLE #BAQDataWithBM;
	DROP TABLE #SilverData;
  drop table if EXISTS #HomeWorkingData;
  drop table if EXISTS #CommutingData;
  drop table if EXISTS #CHWSubmissions;

END
GO


-- ----------------------------
-- procedure structure for spSilver_DataOutputDetailedWrapper_Portal
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[DataModel].[spSilver_DataOutputDetailedWrapper_Portal]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [DataModel].[spSilver_DataOutputDetailedWrapper_Portal]
GO

CREATE PROCEDURE [DataModel].[spSilver_DataOutputDetailedWrapper_Portal] 
	@certId int,
	@emissionProfileId INT,
	@dataInsert int = 0
AS
BEGIN
	
    DECLARE @SAQSubmissionId bigint;
    DECLARE @SilverSubmissionIds nvarchar(max), @CHWSubmissionIds nvarchar(max);
    
    SET @SilverSubmissionIds = (SELECT STRING_AGG([dimSubmissionId], ',') FROM portal.CertFormSubmissions 
                                WHERE dimFormId not in (14, 29, 33, 11, 26) and certId = @certId and isProcessed=1);
    
    SELECT @SAQSubmissionId = MAX(dimSubmissionId)
    FROM portal.CertFormSubmissions
    WHERE dimFormId IN (14, 29, 33) AND certId = @certId AND isProcessed = 1;
    
    IF @SilverSubmissionIds IS NULL
    BEGIN
      SELECT 'Could not find Silver submissionIds' as [error]
    END
    
    IF @SAQSubmissionId IS NULL
    BEGIN
      SELECT 'Could not find BAQ submissionId' as [error]
    END
    
    Declare @HomeWorkingHeadCount int, @CommutingHeadCount int, @TotalHeadCount int;
       
    Select @TotalHeadCount = cert.headCount, @HomeWorkingHeadCount = sum(hc.headCount)
    from portal.CertFormSubmissions as cfs 
        INNER JOIN portal.CertificationHeadCount as hc on (cfs.certId = hc.certId)
        INNER JOIN portal.Certification as cert on (cert.certId = cfs.certId)
    where cfs.dimSubmissionId = @SAQSubmissionId
    GROUP BY cfs.certId, cert.headCount;
    
    set @CommutingHeadCount = @TotalHeadCount - @HomeWorkingHeadCount;
        
    SET @CHWSubmissionIds = (SELECT STRING_AGG([dimSubmissionId], ',') FROM portal.CertFormSubmissions 
                              WHERE dimFormId in (11, 26) and certId = @certId and isProcessed=1);                          
  
    DECLARE @hwRatio decimal(10,4) = NULL, @cmRatio decimal(10,4) = NULL;
    
    IF @CHWSubmissionIds IS NULL OR @HomeWorkingHeadCount Is Null OR @CommutingHeadCount Is Null
      BEGIN
        SET @hwRatio = 1.0;
        SET @cmRatio = 1.0;
      END
    ELSE
      BEGIN
        Declare @HomeWorkingSubmissionCount int, @CommutingSubmissionCount int;
      
        SELECT @CommutingSubmissionCount = Count(distinct submissionId) ,
               @HomeWorkingSubmissionCount = Sum(CASE WHEN emissionActivityId IN (357, 358, 359) THEN 1 ELSE 0 END)
        FROM DataModel.vSilverSubmissions 
        WHERE submissionId IN (
              SELECT value FROM STRING_SPLIT(@CHWSubmissionIds, ',')
          );
        
        Set @CommutingSubmissionCount = @CommutingSubmissionCount - @HomeWorkingSubmissionCount;

        IF @HomeWorkingSubmissionCount > 0
            SET @hwRatio = 1.0 * @HomeWorkingHeadCount / @HomeWorkingSubmissionCount;
        else
          set @hwRatio = 1.0;

        IF @CommutingSubmissionCount > 0
            SET @cmRatio = 1.0 * @CommutingHeadCount / @CommutingSubmissionCount;
        else
          set @cmRatio = 1.0;
      END
      
    EXEC DataModel.spSilver_DataOutputDetailed_Portal	
            @silverSubmissionIds = @SilverSubmissionIds, 
            @emissionProfileId = @emissionProfileId,
            @hwRatio = @hwRatio,
            @cmRatio = @cmRatio,
            @certId =  @certId,
            @dataInsert = @dataInsert;
	
END
GO


-- ----------------------------
-- procedure structure for spLocation_GetDDL
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[portal].[spLocation_GetDDL]') AND type IN ('P', 'PC', 'RF', 'X'))
	DROP PROCEDURE [portal].[spLocation_GetDDL]
GO

CREATE PROCEDURE [portal].[spLocation_GetDDL]
  @certId int,
  @forCMP bit = 0,
	@uCompanyId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
		
			IF ([portal].[fnCheckUserAccess]('CERTIFICATION', @certId, @uCompanyId) = 0)
			BEGIN
					RETURN;
			END;
    
    if(@forCMP = 1)
      begin
        -- Locations of company profile, must have only one for a location
        SELECT L.locationId, L.locationName ,
               case when (cfs.certsubmissionId is not NULL) then 1 else 0 end as hasCMPSubmission,
               case when (cfs.certsubmissionId is not NULL AND cfs.submissionId is not NULL) then 1 else 0 end as isCMPSubmitted,
               case when (cfs.certsubmissionId is not NULL AND cfs.parentCertsubmissionId is NULL) then cfs.certsubmissionId else 0 end as isParentCertsubmissionId,
               case when (hc.headCount is not NULL And hc.headCount > 0) then 1 else 0 end as hasHeadCount,
               case when (hc.revenue is not NULL And hc.revenue > 0) then 1 else 0 end as hasRevenue
        From portal.Location as L 
        INNER JOIN portal.Certification as Cert on (Cert.companyId = L.companyId and L.isDeleted = 0 )
        LEFT JOIN portal.CertificationHeadCount as hc on (hc.certId = cert.certId and hc.locationId = l.locationId)
        Left join (  
          -- Company profile submissions which were submitted/draft saved
          Select cfs.certId, cfs.locationId, cfs.submissionId, cfs.certsubmissionId, cfs.parentCertsubmissionId, pf.progId
          from portal.ProgrammeForms as pf 
          INNER JOIN portal.CertFormSubmissions as cfs on ( pf.dimFormId = cfs.dimFormId and cfs.isDraft = 0)
          Where pf.progFormId in (201,301,401) AND pf.isActive = 1 
          and cfs.certId = @certId) as cfs 
          on (Cert.certId = cfs.certId and cfs.locationId = l.locationId and Cert.progId = cfs.progId)
        Where Cert.certId = @certId
        ORDER BY L.isPrimary desc, l.locationName;
      END
    ELSE
      BEGIN
        -- Locations of company by CertificationID
        SELECT L.locationId, L.locationName
        From portal.Location as L INNER JOIN portal.Certification as Cert on (Cert.companyId = L.companyId)
        Where L.isDeleted = 0 and Cert.certId = @certId
        ORDER BY L.isPrimary desc, l.locationName;
      END

END
GO

