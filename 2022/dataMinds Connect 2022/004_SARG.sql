-- 4. SARGable queries
USE AdventureWorksDW2019;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ResellerSales_OrderDate' AND object_id = OBJECT_ID('dbo.FactResellerSales'))
    DROP INDEX dbo.FactResellerSales.IX_ResellerSales_OrderDate;
CREATE INDEX IX_ResellerSales_OrderDate ON dbo.FactResellerSales
(OrderDate) INCLUDE (SalesAmount);

SET STATISTICS IO ON;
-- clear buffers
CHECKPOINT;
DBCC DROPCLEANBUFFERS;

-- 1. No functions in the WHERE clause
-- turn actual execution plan on
SELECT SUM(SalesAmount)
FROM dbo.FactResellerSales
WHERE YEAR(OrderDate) = 2013;

SELECT SUM(SalesAmount)
FROM dbo.FactResellerSales
WHERE   OrderDate >= '2013-01-01'
    AND OrderDate <= '2013-12-31';

-- 2. No implicit conversions
SELECT
     [SalesOrderID]     = CONVERT(NVARCHAR(10),[SalesOrderID])
    ,[RevisionNumber]
    ,[OrderDate]
    ,[DueDate]
    ,[ShipDate]
    ,[Status]
    ,[OnlineOrderFlag]
    ,[SalesOrderNumber]
    ,[PurchaseOrderNumber]
    ,[AccountNumber]
    ,[CustomerID]
    ,[SalesPersonID]
    ,[TerritoryID]
    ,[BillToAddressID]
    ,[ShipToAddressID]
    ,[ShipMethodID]
    ,[CreditCardID]
    ,[CreditCardApprovalCode]
    ,[CurrencyRateID]
    ,[SubTotal]
    ,[TaxAmt]
    ,[Freight]
    ,[TotalDue]
    ,[Comment]
    ,[rowguid]
    ,[ModifiedDate]
INTO #SalesOrderHeader
FROM [AdventureWorks2019].[Sales].[SalesOrderHeader];

CREATE CLUSTERED INDEX SH_OrderID ON [#SalesOrderHeader]([SalesOrderID]);

SELECT
     [SalesOrderID]         = CONVERT(VARCHAR(10),[SalesOrderID])
    ,[SalesOrderDetailID]
    ,[CarrierTrackingNumber]
    ,[OrderQty]
    ,[ProductID]
    ,[SpecialOfferID]
    ,[UnitPrice]
    ,[UnitPriceDiscount]
    ,[LineTotal]
    ,[rowguid]
    ,[ModifiedDate]
INTO #SalesOrderDetail
FROM [AdventureWorks2019].[Sales].[SalesOrderDetail];

CREATE CLUSTERED INDEX SD_OrderID_OrderDetailID ON #SalesOrderDetail([SalesOrderID],[SalesOrderDetailID]);

SELECT COUNT(1)
FROM #SalesOrderHeader sh
JOIN #SalesOrderDetail sd ON [sd].[SalesOrderID] = [sh].[SalesOrderID]
WHERE sh.[SalesOrderID] = '43659';

SELECT
     [SalesOrderID]         = CONVERT(NVARCHAR(10),[SalesOrderID])
    ,[SalesOrderDetailID]
    ,[CarrierTrackingNumber]
    ,[OrderQty]
    ,[ProductID]
    ,[SpecialOfferID]
    ,[UnitPrice]
    ,[UnitPriceDiscount]
    ,[LineTotal]
    ,[rowguid]
    ,[ModifiedDate]
INTO #SalesOrderDetail_Correct
FROM [AdventureWorks2019].[Sales].[SalesOrderDetail];

CREATE CLUSTERED INDEX SD_OrderID_OrderDetailID_Correct ON #SalesOrderDetail_Correct([SalesOrderID],[SalesOrderDetailID]);

SELECT COUNT(1)
FROM #SalesOrderHeader sh
JOIN #SalesOrderDetail_Correct sd ON [sd].[SalesOrderID] = [sh].[SalesOrderID]
WHERE sh.[SalesOrderID] = '43659';