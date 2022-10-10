USE [AdventureWorksDW2017];
SELECT
     AvgChildren    = AVG([TotalChildren]*1.0)
    ,AvgCars        = AVG([NumberCarsOwned]*1.0)
    ,AvgIncome      = AVG([YearlyIncome])
FROM [dbo].[DimCustomer];