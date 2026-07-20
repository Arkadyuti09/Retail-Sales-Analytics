/*
===============================================================================
Script:      example_queries_gold.sql
Purpose:     Sample business questions answered using the Gold star schema.
             Use these to validate the model and as a starting point for
             BI tool reports/dashboards (Power BI, Tableau, etc.).
Layer:       GOLD (consumption)
===============================================================================
*/

USE WalmartDWH;
GO

-- 1. Total sales by store type (A/B/C)
SELECT
    ds.store_type,
    SUM(fs.weekly_sales) AS total_sales,
    COUNT(DISTINCT ds.store_key) AS num_stores
FROM gold.fact_sales fs
JOIN gold.dim_store ds ON fs.store_key = ds.store_key
GROUP BY ds.store_type
ORDER BY total_sales DESC;

-- 2. Monthly sales trend across all stores
SELECT
    dd.calendar_year,
    dd.calendar_month,
    dd.month_name,
    SUM(fs.weekly_sales) AS total_sales
FROM gold.fact_sales fs
JOIN gold.dim_date dd ON fs.date_key = dd.date_key
GROUP BY dd.calendar_year, dd.calendar_month, dd.month_name
ORDER BY dd.calendar_year, dd.calendar_month;

-- 3. Holiday vs non-holiday week average sales
SELECT
    CASE WHEN fs.is_holiday = 1 THEN 'Holiday Week' ELSE 'Regular Week' END AS week_type,
    AVG(fs.weekly_sales) AS avg_weekly_sales
FROM gold.fact_sales fs
GROUP BY fs.is_holiday;

-- 4. Top 10 best-performing (store, department) combinations by total sales
SELECT TOP 10
    ds.store_id,
    dpt.dept_id,
    SUM(fs.weekly_sales) AS total_sales
FROM gold.fact_sales fs
JOIN gold.dim_store ds      ON fs.store_key = ds.store_key
JOIN gold.dim_department dpt ON fs.department_key = dpt.department_key
GROUP BY ds.store_id, dpt.dept_id
ORDER BY total_sales DESC;

-- 5. Correlation check: average weekly sales by unemployment rate bucket
SELECT
    CASE
        WHEN fs.unemployment < 6  THEN 'Low (<6%)'
        WHEN fs.unemployment < 8  THEN 'Medium (6-8%)'
        ELSE 'High (8%+)'
    END AS unemployment_band,
    AVG(fs.weekly_sales) AS avg_weekly_sales,
    COUNT(*) AS num_weeks
FROM gold.fact_sales fs
WHERE fs.unemployment IS NOT NULL
GROUP BY
    CASE
        WHEN fs.unemployment < 6  THEN 'Low (<6%)'
        WHEN fs.unemployment < 8  THEN 'Medium (6-8%)'
        ELSE 'High (8%+)'
    END;

-- 6. Stores with the most negative-sales (returns/adjustments) weeks -- data quality lens
SELECT
    ds.store_id,
    COUNT(*) AS negative_sale_weeks,
    SUM(fs.weekly_sales) AS total_negative_value
FROM gold.fact_sales fs
JOIN gold.dim_store ds ON fs.store_key = ds.store_key
WHERE fs.is_negative_sale = 1
GROUP BY ds.store_id
ORDER BY negative_sale_weeks DESC;
