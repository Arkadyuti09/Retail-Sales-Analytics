/*
===============================================================================
Script:      load_silver.sql
Purpose:     Transforms and loads data from Bronze into Silver.
             Cleansing rules applied:
               - 'NA' (any case) -> NULL on numeric columns
               - Text dates 'DD/MM/YYYY' -> DATE
               - Text 'TRUE'/'FALSE' -> BIT
               - Trim/standardize store_type
               - De-duplicate sales rows (exact duplicates only; see notes)
               - Flag negative Weekly_Sales rather than deleting them, since
                 they appear to represent legitimate returns/adjustments
Layer:       SILVER
===============================================================================
*/

USE WalmartDWH;
GO

CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @start_time  DATETIME2,
            @end_time    DATETIME2,
            @batch_start DATETIME2;

    BEGIN TRY
        SET @batch_start = SYSDATETIME();

        PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';

        ----------------------------------------------------------------
        -- silver.stores
        ----------------------------------------------------------------
        SET @start_time = SYSDATETIME();
        PRINT '>> Truncating Table: silver.stores';
        TRUNCATE TABLE silver.stores;

        PRINT '>> Inserting Data Into: silver.stores';
        INSERT INTO silver.stores (store_id, store_type, store_size)
        SELECT
            Store,
            UPPER(LTRIM(RTRIM(Type))),
            Size
        FROM bronze.stores
        WHERE Store IS NOT NULL;
        SET @end_time = SYSDATETIME();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS NVARCHAR) + ' ms';
        PRINT '-------------';

        ----------------------------------------------------------------
        -- silver.features
        ----------------------------------------------------------------
        SET @start_time = SYSDATETIME();
        PRINT '>> Truncating Table: silver.features';
        TRUNCATE TABLE silver.features;

        PRINT '>> Inserting Data Into: silver.features';
        INSERT INTO silver.features (
            store_id, week_date, temperature, fuel_price,
            markdown1, markdown2, markdown3, markdown4, markdown5,
            cpi, unemployment, is_holiday
        )
        SELECT
            f.Store,
            TRY_CONVERT(DATE, f.Date, 103)        AS week_date,   -- style 103 = DD/MM/YYYY
            TRY_CAST(f.Temperature AS DECIMAL(6,2)),
            TRY_CAST(f.Fuel_Price  AS DECIMAL(6,3)),
            CASE WHEN UPPER(LTRIM(RTRIM(f.MarkDown1))) = 'NA' THEN NULL ELSE TRY_CAST(f.MarkDown1 AS DECIMAL(12,2)) END,
            CASE WHEN UPPER(LTRIM(RTRIM(f.MarkDown2))) = 'NA' THEN NULL ELSE TRY_CAST(f.MarkDown2 AS DECIMAL(12,2)) END,
            CASE WHEN UPPER(LTRIM(RTRIM(f.MarkDown3))) = 'NA' THEN NULL ELSE TRY_CAST(f.MarkDown3 AS DECIMAL(12,2)) END,
            CASE WHEN UPPER(LTRIM(RTRIM(f.MarkDown4))) = 'NA' THEN NULL ELSE TRY_CAST(f.MarkDown4 AS DECIMAL(12,2)) END,
            CASE WHEN UPPER(LTRIM(RTRIM(f.MarkDown5))) = 'NA' THEN NULL ELSE TRY_CAST(f.MarkDown5 AS DECIMAL(12,2)) END,
            CASE WHEN UPPER(LTRIM(RTRIM(f.CPI)))         = 'NA' THEN NULL ELSE TRY_CAST(f.CPI AS DECIMAL(10,4)) END,
            CASE WHEN UPPER(LTRIM(RTRIM(f.Unemployment))) = 'NA' THEN NULL ELSE TRY_CAST(f.Unemployment AS DECIMAL(6,3)) END,
            CASE WHEN UPPER(LTRIM(RTRIM(f.IsHoliday))) = 'TRUE' THEN 1 ELSE 0 END
        FROM bronze.features f
        WHERE f.Store IS NOT NULL
          AND TRY_CONVERT(DATE, f.Date, 103) IS NOT NULL;  -- drop unparseable date rows
        SET @end_time = SYSDATETIME();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS NVARCHAR) + ' ms';
        PRINT '-------------';

        ----------------------------------------------------------------
        -- silver.sales
        ----------------------------------------------------------------
        SET @start_time = SYSDATETIME();
        PRINT '>> Truncating Table: silver.sales';
        TRUNCATE TABLE silver.sales;

        PRINT '>> Inserting Data Into: silver.sales';
        ;WITH deduped AS (
            SELECT
                s.Store,
                s.Dept,
                TRY_CONVERT(DATE, s.Date, 103)                         AS week_date,
                TRY_CAST(s.Weekly_Sales AS DECIMAL(14,2))              AS weekly_sales,
                CASE WHEN UPPER(LTRIM(RTRIM(s.IsHoliday))) = 'TRUE' THEN 1 ELSE 0 END AS is_holiday,
                ROW_NUMBER() OVER (
                    PARTITION BY s.Store, s.Dept, s.Date, s.Weekly_Sales, s.IsHoliday
                    ORDER BY (SELECT NULL)
                ) AS rn   -- de-dup exact duplicate rows only; keeps first occurrence
            FROM bronze.sales s
            WHERE s.Store IS NOT NULL
              AND s.Dept IS NOT NULL
              AND TRY_CONVERT(DATE, s.Date, 103) IS NOT NULL
              AND TRY_CAST(s.Weekly_Sales AS DECIMAL(14,2)) IS NOT NULL
        )
        INSERT INTO silver.sales (
            store_id, dept_id, week_date, weekly_sales, is_holiday, is_negative_sale
        )
        SELECT
            Store, Dept, week_date, weekly_sales, is_holiday,
            CASE WHEN weekly_sales < 0 THEN 1 ELSE 0 END
        FROM deduped
        WHERE rn = 1;
        SET @end_time = SYSDATETIME();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS NVARCHAR) + ' ms';
        PRINT '-------------';

        PRINT '================================================';
        PRINT 'Silver Layer Load Complete. Total Duration: '
            + CAST(DATEDIFF(SECOND, @batch_start, SYSDATETIME()) AS NVARCHAR) + ' sec';
        PRINT '================================================';
    END TRY
    BEGIN CATCH
        PRINT '================================================';
        PRINT 'ERROR OCCURRED DURING SILVER LOAD';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number:  ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error Line:    ' + CAST(ERROR_LINE() AS NVARCHAR);
        PRINT '================================================';
    END CATCH
END;
GO

-- Run it:
EXEC silver.load_silver;
