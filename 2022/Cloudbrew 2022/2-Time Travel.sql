USE DATABASE TEST;
USE SCHEMA dbo;
USE WAREHOUSE COMPUTE_WH;

-- clean up
DROP TABLE IF EXISTS dbo.TimeTravelTest;

CREATE TABLE IF NOT EXISTS dbo.TimeTravelTest
(TestString STRING);

-- insert sample data
INSERT INTO dbo.TimeTravelTest(TestString)
SELECT 'Hello'
UNION ALL
SELECT 'World';

-- Wait for some time.
SELECT * FROM dbo.TimeTravelTest;

-- Insert other sample data.
INSERT INTO dbo.TimeTravelTest(TestString)
SELECT 'This is a ...'
UNION ALL
SELECT '... test';

SELECT * FROM dbo.TimeTravelTest;

-- Query time travel data
-- Using statement ID (don't forget to change it!)
SELECT *
FROM dbo.TimeTravelTest
BEFORE (STATEMENT => '01a865fe-0c03-ed9b-0000-0819002250f6');

-- Using Offset
SELECT *
FROM dbo.TimeTravelTest
AT (OFFSET => -60*5);
-- offset is in seconds

-- What about TRUNCATE?
TRUNCATE TABLE dbo.TimeTravelTest;

SELECT *
FROM dbo.TimeTravelTest
BEFORE (STATEMENT => '01a86600-0c03-ed9b-0000-08190022513a');

-- Insert some sample data again
INSERT INTO dbo.TimeTravelTest(TestString)
SELECT 'Hello'
UNION ALL
SELECT 'World2';

-- What about dropping the table?

DROP TABLE IF EXISTS dbo.TimeTravelTest;

SELECT *
FROM dbo.TimeTravelTest
AT (OFFSET => -60*2);

SHOW TABLES HISTORY;

UNDROP TABLE dbo.TimeTravelTest;

SELECT *
FROM dbo.TimeTravelTest;

SELECT *
FROM dbo.TimeTravelTest
BEFORE (STATEMENT => '01a24348-0a02-ac99-0000-081900171066');


/**********
* CLONING *
**********/

create database STACKOVERFLOW_CLONE clone stackoverflow;

-- Clean-up
DROP DATABASE IF EXISTS STACKOVERFLOW_CLONE;