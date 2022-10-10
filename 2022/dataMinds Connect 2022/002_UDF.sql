-- 2. UDF
USE StackOverflow2013;
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO
-- create function
CREATE FUNCTION dbo.TestMultipleLines
(@Score INT
,@Text NVARCHAR(700))
RETURNS INT
AS
BEGIN

DECLARE @lentext INT = LEN(@Text);
RETURN @Score * @lentext

END

-- This query takes a couple of seconds to run
SELECT Test = AVG(Score * LEN([Text]))
FROM [StackOverflow2013].[dbo].[Comments_Compressed];
GO

-- This query takes about a minute to run
SELECT Test = AVG(dbo.TestMultipleLines(Score,[Text]))
FROM [StackOverflow2013].[dbo].[Comments_Compressed];
GO

CREATE FUNCTION dbo.TestSingleLine
(@Score INT
,@Text NVARCHAR(700))
RETURNS INT WITH RETURNS NULL ON NULL INPUT
AS
BEGIN
RETURN @Score * LEN(@Text)
END
GO

-- This query takes about 50 secs to run
SELECT Test = AVG(dbo.TestSingleLine(Score,[Text]))
FROM [StackOverflow2013].[dbo].[Comments_Compressed];
GO

-- Possible optimization technique: calculate function over smaller set

CREATE FUNCTION dbo.TestSingleLineAdjusted
(@Score INT
,@TextLength INT)
RETURNS INT WITH RETURNS NULL ON NULL INPUT
AS
BEGIN
RETURN @Score * @TextLength
END
GO

--SELECT COUNT(1) FROM (
--SELECT DISTINCT Score, textlength = LEN([Text])
--FROM [StackOverflow2013].[dbo].[Comments_Compressed]
--) tmp;

DROP TABLE IF EXISTS #temp;

SELECT DISTINCT Score, textlength = LEN([Text])
INTO #temp
FROM [StackOverflow2013].[dbo].[Comments_Compressed];

SELECT Test = dbo.TestSingleLine(Score,textlength)
FROM #temp