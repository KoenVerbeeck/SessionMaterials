/* 5 - V-shape stock detection */
USE Test;
DROP TABLE IF EXISTS Test.dbo.StockPrices;
CREATE TABLE Test.dbo.StockPrices
(
     Symbol      VARCHAR(10) NOT NULL
    ,TradeDate   DATE NOT NULL
    ,ClosePrice  DECIMAL(10,2) NOT NULL
    ,CONSTRAINT PK_StockPrices PRIMARY KEY (Symbol, TradeDate)
);

/* Sample series contains multiple local minima and one broad V-shape */
INSERT INTO Test.dbo.StockPrices (Symbol, TradeDate, ClosePrice)
VALUES
     ('XYZ', '2024-01-01', 110.00)
    ,('XYZ', '2024-01-02', 108.00)
    ,('XYZ', '2024-01-03', 106.00)
    ,('XYZ', '2024-01-04', 103.00)
    ,('XYZ', '2024-01-05',  99.00)
    ,('XYZ', '2024-01-08', 101.00)
    ,('XYZ', '2024-01-09', 104.00)
    ,('XYZ', '2024-01-10', 107.00)
    ,('XYZ', '2024-01-11', 105.00)
    ,('XYZ', '2024-01-12', 102.00)
    ,('XYZ', '2024-01-15', 100.00)
    ,('XYZ', '2024-01-16', 103.00)
    ,('XYZ', '2024-01-17', 106.00)
    ,('XYZ', '2024-01-18', 109.00);

SELECT *
FROM Test.dbo.StockPrices
WHERE Symbol = 'XYZ'
ORDER BY TradeDate;

/*
Basic pattern: local minimum
Bottom of a V where the current value is lower than previous and next values.
*/
WITH cte_prices AS
(
    SELECT
         Symbol
        ,TradeDate
        ,ClosePrice
        ,PrevPrice = LAG(ClosePrice) OVER (PARTITION BY Symbol ORDER BY TradeDate)
        ,NextPrice = LEAD(ClosePrice) OVER (PARTITION BY Symbol ORDER BY TradeDate)
    FROM Test.dbo.StockPrices
    WHERE Symbol = 'XYZ'
)
SELECT
     Symbol
    ,TradeDate
    ,ClosePrice
FROM cte_prices
WHERE ClosePrice < PrevPrice
  AND ClosePrice < NextPrice
ORDER BY TradeDate;

/*
Stronger pattern: V-shape with minimum depth.
DepthPct filters out tiny fluctuations and keeps stronger reversal patterns.
*/
WITH cte_prices AS
(
    SELECT
         Symbol
        ,TradeDate
        ,ClosePrice
        ,PrevPrice = LAG(ClosePrice) OVER (PARTITION BY Symbol ORDER BY TradeDate)
        ,NextPrice = LEAD(ClosePrice) OVER (PARTITION BY Symbol ORDER BY TradeDate)
    FROM Test.dbo.StockPrices
    WHERE Symbol = 'XYZ'
)
SELECT
     Symbol
    ,BottomDate      = TradeDate
    ,BottomPrice     = ClosePrice
    ,LeftPrice       = PrevPrice
    ,RightPrice      = NextPrice
    ,DepthPct        = CAST((
                        ( (PrevPrice + NextPrice) / 2.0 ) - ClosePrice
                    ) / NULLIF(((PrevPrice + NextPrice) / 2.0), 0.0) * 100.0 AS DECIMAL(10,2))
FROM cte_prices
WHERE ClosePrice < PrevPrice
  AND ClosePrice < NextPrice
  AND CAST((
        ( (PrevPrice + NextPrice) / 2.0 ) - ClosePrice
      ) / NULLIF(((PrevPrice + NextPrice) / 2.0), 0.0) * 100.0 AS DECIMAL(10,2)) >= 2.00
ORDER BY BottomDate;

/* Cleanup if needed
DROP TABLE IF EXISTS Test.dbo.StockPrices;
*/
