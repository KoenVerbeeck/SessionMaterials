/* Demo 0 - Why window functions?
   Running total of Internet Sales per month: self-join vs. window function vs. cursor.
   Turn on "Include Actual Execution Plan" and compare the three batches. */

USE AdventureWorksDW2025;
GO

SET STATISTICS IO, TIME ON; -- enable actual execution plan!!!
GO

/* --------------------------------------------------------------------------
   Query 1 - The old school way: a self-join (triangular join)
   Every row is joined to all of its predecessors, so the number of rows the
   engine has to touch grows quadratically. Fun with 36 months, less fun with
   36,000.
   -------------------------------------------------------------------------- */
WITH cte_monthly_sales AS
(
    SELECT
         YearMonth  = YEAR(OrderDate) * 100 + MONTH(OrderDate)
        ,[Year]     = YEAR(OrderDate)
        ,SalesTotal = SUM(SalesAmount)
    FROM dbo.FactInternetSales
    GROUP BY YEAR(OrderDate) * 100 + MONTH(OrderDate)
            ,YEAR(OrderDate)
)
SELECT
     m.YearMonth
    ,m.SalesTotal
    ,RunningTotal = SUM(p.SalesTotal)
FROM cte_monthly_sales           AS m
JOIN cte_monthly_sales           AS p
    ON  p.[Year]     =  m.[Year]
    AND p.YearMonth  <= m.YearMonth
GROUP BY m.YearMonth
        ,m.SalesTotal
ORDER BY m.YearMonth;
GO

/* --------------------------------------------------------------------------
   Query 2 - The same result with a window function
   One pass over the data, no self-join, and the intent is readable at a glance.
   Note the explicit ROWS frame: the default is RANGE, which forces a slower
   on-disk spool.
   -------------------------------------------------------------------------- */
WITH cte_monthly_sales AS
(
    SELECT
         YearMonth  = YEAR(OrderDate) * 100 + MONTH(OrderDate)
        ,[Year]     = YEAR(OrderDate)
        ,SalesTotal = SUM(SalesAmount)
    FROM dbo.FactInternetSales
    GROUP BY YEAR(OrderDate) * 100 + MONTH(OrderDate)
            ,YEAR(OrderDate)
)
SELECT
     YearMonth
    ,SalesTotal
    ,RunningTotal = SUM(SalesTotal) OVER (
        PARTITION BY [Year]
        ORDER BY YearMonth
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
     )
FROM cte_monthly_sales
ORDER BY YearMonth;
GO

/* --------------------------------------------------------------------------
   Query 3 - The "I learned this in a procedural language" way: a cursor
   Row-by-agonizing-row. It works, it is easy to reason about, and it is by far
   the slowest of the three. Watch the elapsed time in the Messages tab.
   -------------------------------------------------------------------------- */
DECLARE @Results TABLE
(
     YearMonth    INT           NOT NULL
    ,SalesTotal   MONEY         NOT NULL
    ,RunningTotal MONEY         NOT NULL
);

DECLARE  @YearMonth    INT
        ,@Year         INT
        ,@SalesTotal   MONEY
        ,@RunningTotal MONEY = 0
        ,@PreviousYear INT   = NULL;

DECLARE curMonthlySales CURSOR LOCAL FAST_FORWARD FOR
    SELECT
         YearMonth  = YEAR(OrderDate) * 100 + MONTH(OrderDate)
        ,[Year]     = YEAR(OrderDate)
        ,SalesTotal = SUM(SalesAmount)
    FROM dbo.FactInternetSales
    GROUP BY YEAR(OrderDate) * 100 + MONTH(OrderDate)
            ,YEAR(OrderDate)
    ORDER BY YEAR(OrderDate)
            ,YEAR(OrderDate) * 100 + MONTH(OrderDate);

OPEN curMonthlySales;

FETCH NEXT FROM curMonthlySales INTO @YearMonth, @Year, @SalesTotal;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- reset the accumulator on every new year, mimicking PARTITION BY [Year]
    IF @PreviousYear IS NULL OR @Year <> @PreviousYear
        SET @RunningTotal = 0;

    SET @RunningTotal = @RunningTotal + @SalesTotal;
    SET @PreviousYear = @Year;

    INSERT INTO @Results (YearMonth, SalesTotal, RunningTotal)
    VALUES (@YearMonth, @SalesTotal, @RunningTotal);

    FETCH NEXT FROM curMonthlySales INTO @YearMonth, @Year, @SalesTotal;
END

CLOSE curMonthlySales;
DEALLOCATE curMonthlySales;

SELECT
     YearMonth
    ,SalesTotal
    ,RunningTotal
FROM @Results
ORDER BY YearMonth;
GO

SET STATISTICS IO, TIME OFF;
GO
