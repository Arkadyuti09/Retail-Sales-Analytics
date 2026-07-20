/*
===============================================================================
Script:      ddl_gold.sql
Purpose:     Builds the Gold layer as a business-facing star schema, exposed
             as VIEWS over Silver (no physical duplication of data, always
             reflects the latest Silver load on query).
Layer:       GOLD

Model:
    dim_store        - one row per store (45 stores)
    dim_date         - one row per calendar date covering the full data range
    dim_department    - one row per distinct department number
    fact_sales       - one row per store/dept/week, enriched with the
                        regional Features metrics (temperature, fuel price,
                        CPI, unemployment, markdowns) for that store+week
===============================================================================
*/

USE WalmartDWH;
GO

----------------------------------------------------------------------------
-- gold.dim_store
----------------------------------------------------------------------------
IF OBJECT_ID('gold.dim_store', 'V') IS NOT NULL
    DROP VIEW gold.dim_store;
GO

CREATE VIEW gold.dim_store AS
SELECT
    ROW_NUMBER() OVER (ORDER BY store_id) AS store_key,   -- surrogate key
    store_id,
    store_type,
    store_size,
    CASE
        WHEN store_size < 50000  THEN 'Small'
        WHEN store_size < 150000 THEN 'Medium'
        ELSE 'Large'
    END AS store_size_band
FROM silver.stores;
GO

----------------------------------------------------------------------------
-- gold.dim_department
----------------------------------------------------------------------------
IF OBJECT_ID('gold.dim_department', 'V') IS NOT NULL
    DROP VIEW gold.dim_department;
GO

CREATE VIEW gold.dim_department AS
SELECT
    ROW_NUMBER() OVER (ORDER BY dept_id) AS department_key,  -- surrogate key
    dept_id,
    CONCAT('Dept ', dept_id) AS department_name  -- source has no dept names, only numbers
FROM (SELECT DISTINCT dept_id FROM silver.sales) AS d;
GO

----------------------------------------------------------------------------
-- gold.dim_date
----------------------------------------------------------------------------
IF OBJECT_ID('gold.dim_date', 'V') IS NOT NULL
    DROP VIEW gold.dim_date;
GO

IF OBJECT_ID('gold.dim_date', 'V') IS NOT NULL
    DROP VIEW gold.dim_date;
GO

CREATE VIEW gold.dim_date AS
WITH bounds AS (
    SELECT
        MIN(week_date) AS min_d,
        MAX(week_date) AS max_d
    FROM (
        SELECT week_date FROM silver.sales
        UNION ALL
        SELECT week_date FROM silver.features
    ) d
),
numbers AS (
    SELECT TOP (5000)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.all_objects
)
SELECT
    CONVERT(INT, FORMAT(DATEADD(DAY,n,min_d),'yyyyMMdd')) AS date_key,
    DATEADD(DAY,n,min_d) AS full_date,
    YEAR(DATEADD(DAY,n,min_d)) AS calendar_year,
    DATEPART(QUARTER,DATEADD(DAY,n,min_d)) AS calendar_quarter,
    MONTH(DATEADD(DAY,n,min_d)) AS calendar_month,
    DATENAME(MONTH,DATEADD(DAY,n,min_d)) AS month_name,
    DATEPART(WEEK,DATEADD(DAY,n,min_d)) AS calendar_week,
    DATENAME(WEEKDAY,DATEADD(DAY,n,min_d)) AS day_name
FROM bounds
CROSS JOIN numbers
WHERE DATEADD(DAY,n,min_d) <= max_d;
GO
GO

----------------------------------------------------------------------------
-- gold.fact_sales
----------------------------------------------------------------------------
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT
    ds.store_key,
    dd.department_key,
    CONVERT(INT, FORMAT(s.week_date, 'yyyyMMdd'))  AS date_key,
    s.week_date,
    s.weekly_sales,
    s.is_holiday,
    s.is_negative_sale,
    f.temperature,
    f.fuel_price,
    f.cpi,
    f.unemployment,
    f.markdown1,
    f.markdown2,
    f.markdown3,
    f.markdown4,
    f.markdown5
FROM silver.sales s
JOIN gold.dim_store ds
    ON s.store_id = ds.store_id
JOIN gold.dim_department dd
    ON s.dept_id = dd.dept_id
LEFT JOIN silver.features f
    ON s.store_id = f.store_id
   AND s.week_date = f.week_date;
GO
