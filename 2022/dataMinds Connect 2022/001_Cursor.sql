-- 1. Cursor vs window function

-- Let's implement a running total
USE AdventureWorksDW2019;
GO

SET STATISTICS IO ON;

-- windows function

SELECT
     SalesTerritoryKey
    ,SalesAmount
    ,RunningTotal = SUM(SalesAmount) OVER (PARTITION BY SalesTerritoryKey ORDER BY OrderDateKey)
FROM dbo.FactInternetSales_Big
WHERE OrderDate >= '2013-12-25'; 

-- cursor
DROP TABLE IF EXISTS ##result;
CREATE TABLE ##result
(
     SalesTerritoryKey  INT
    ,OrderDate          DATETIME
    ,SalesAmount        MONEY
    ,RunningTotal       MONEY
);

DECLARE
     @mycursor      CURSOR
    ,@territoryKey  INT
    ,@prevterritory INT     = 0
    ,@orderdate     DATETIME
    ,@salesamount   MONEY   = 0
    ,@runningtotal  MONEY   = 0;

SET @mycursor = CURSOR FORWARD_ONLY STATIC READ_ONLY FOR
    SELECT SalesTerritoryKey, OrderDate, SalesAmount
    FROM dbo.FactInternetSales_Big
    WHERE OrderDate >= '2013-12-25' --> 1.023.165 rows
    ORDER BY SalesTerritoryKey, OrderDateKey;

OPEN @mycursor;
FETCH NEXT FROM @mycursor INTO @territoryKey, @orderdate, @salesamount;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @territoryKey <> @prevterritory
        SELECT @prevterritory = @territoryKey, @runningtotal = 0;

    SET @runningtotal = @runningtotal + @salesamount;

    INSERT INTO ##result
    (
         SalesTerritoryKey
        ,OrderDate
        ,SalesAmount
        ,RunningTotal
    )
    VALUES(@territoryKey,@orderdate,@salesamount,@runningtotal);

    --PRINT CONCAT(@territoryKey, '  ', @orderdate)

    FETCH NEXT FROM @mycursor INTO @territoryKey, @orderdate, @salesamount;
END

SELECT * FROM ##result;