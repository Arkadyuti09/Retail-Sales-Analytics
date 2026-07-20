/*
===============================================================================
Script:      quality_checks_silver.sql
Purpose:     Validation queries to run after silver.load_silver. Each query
             should return ZERO rows if data quality is as expected. Any
             rows returned indicate something to investigate.
Layer:       SILVER (validation)
===============================================================================
*/

USE WalmartDWH;
GO

-- 1. silver.stores: no duplicate store_id, no nulls in key columns
SELECT store_id, COUNT(*)
FROM silver.stores
GROUP BY store_id
HAVING COUNT(*) > 1;

-- 2. silver.stores: unexpected store_type values (should only be A, B, C)
SELECT DISTINCT store_type
FROM silver.stores
WHERE store_type NOT IN ('A', 'B', 'C');

-- 3. silver.features: duplicate (store_id, week_date) -- should be none, PK enforces this
SELECT store_id, week_date, COUNT(*)
FROM silver.features
GROUP BY store_id, week_date
HAVING COUNT(*) > 1;

-- 4. silver.features: store_id values not present in silver.stores (orphans)
SELECT DISTINCT f.store_id
FROM silver.features f
LEFT JOIN silver.stores s ON f.store_id = s.store_id
WHERE s.store_id IS NULL;

-- 5. silver.sales: store_id values not present in silver.stores (orphans)
SELECT DISTINCT sl.store_id
FROM silver.sales sl
LEFT JOIN silver.stores s ON sl.store_id = s.store_id
WHERE s.store_id IS NULL;

-- 6. silver.sales: (store_id, week_date) combos not present in silver.features (orphans)
--    Informational only -- features file may not cover every sales week.
SELECT DISTINCT sl.store_id, sl.week_date
FROM silver.sales sl
LEFT JOIN silver.features f
    ON sl.store_id = f.store_id AND sl.week_date = f.week_date
WHERE f.store_id IS NULL;

-- 7. silver.sales: how many rows are flagged as negative sales (informational, not zero-expected)
SELECT COUNT(*) AS negative_sales_rows
FROM silver.sales
WHERE is_negative_sale = 1;

-- 8. silver.sales: dept_id out of plausible range (sanity check, expected 1-99)
SELECT DISTINCT dept_id
FROM silver.sales
WHERE dept_id NOT BETWEEN 1 AND 99;

-- 9. Row count reconciliation Bronze vs Silver (informational)
SELECT
    (SELECT COUNT(*) FROM bronze.stores)   AS bronze_stores,
    (SELECT COUNT(*) FROM silver.stores)   AS silver_stores,
    (SELECT COUNT(*) FROM bronze.features) AS bronze_features,
    (SELECT COUNT(*) FROM silver.features) AS silver_features,
    (SELECT COUNT(*) FROM bronze.sales)    AS bronze_sales,
    (SELECT COUNT(*) FROM silver.sales)    AS silver_sales;
