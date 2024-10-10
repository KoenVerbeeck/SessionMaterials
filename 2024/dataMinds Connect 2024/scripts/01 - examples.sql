-- 1 - grand total & subtotal
SELECT DISTINCT
        SalesYear        = YEAR(OrderDate)
       ,SalesPerYear     = SUM(SalesAmount) OVER (PARTITION BY YEAR(OrderDate))
       ,SalesGrandTotal  = SUM(SalesAmount) OVER ()
FROM AdventureWorksDW2019.dbo.FactInternetSales
ORDER BY SalesYear;

-- 2 - rank
SELECT
     tmp.CustomerAlternateKey
    ,tmp.SalesAmount
    ,CustomerRank = RANK() OVER (ORDER BY tmp.SalesAmount DESC)
FROM
( -- first calculate the sales amount for each customer
    SELECT
         c.CustomerAlternateKey
        ,SalesAmount = SUM(f.SalesAmount)
    FROM dbo.FactInternetSales f
    JOIN dbo.DimCustomer       c ON c.CustomerKey = f.CustomerKey
    GROUP BY c.CustomerAlternateKey
) tmp;

-- 3 - Running Total
WITH CTE_source AS
(
    SELECT
         YearMonth      = YEAR(OrderDate) * 100 + MONTH(OrderDate)
        ,[Year]         = YEAR(OrderDate)
        ,OrderQuantity  = SUM(OrderQuantity)
    FROM dbo.FactResellerSales
    GROUP BY YEAR(OrderDate) * 100 + MONTH(OrderDate)
            ,YEAR(OrderDate)
)
SELECT
     YearMonth
    ,OrderQuantity
    ,RunningTotal = SUM(OrderQuantity) OVER (PARTITION BY [Year]
                                             ORDER BY YearMonth
                                             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                                            )
FROM CTE_source
ORDER BY YearMonth;

-- 4 - wut?
SELECT
     [Year]         = YEAR(OrderDate)
    ,[Sales Amount] = SUM(SalesAmount)
    ,GrandTotal     = SUM(SUM(SalesAmount)) OVER ()
FROM dbo.FactResellerSales
GROUP BY YEAR(OrderDate);