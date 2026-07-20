/*
===============================================================================
Script:      load_bronze.sql
Purpose:     Loads raw CSV files into the Bronze schema using BULK INSERT.
             Wrapped in a stored procedure so the whole Bronze load can be
             re-run with one call and timed/logged consistently.
Layer:       BRONZE
===============================================================================
HOW TO USE:
  1. Copy the three CSV files to a path the SQL Server *service account* can
     read (a local path on the server, or a shared/mounted path). Update
     @SourcePath below to match.
  2. EXEC bronze.load_bronze;

NOTE ON BULK INSERT:
  BULK INSERT reads files from the server's perspective, not the client's.
  If your SQL Server instance can't see the path (e.g. running in Docker, or
  files sitting on your laptop while SQL Server is elsewhere), use one of:
    - Copy files into a folder shared with / mounted into the SQL Server host
    - Use OPENROWSET with BULK + a server-visible UNC/local path
    - Import via SSMS "Import Flat File" wizard
    - Use Azure Data Studio / sqlcmd with bcp utility instead
===============================================================================
*/

USE WalmartDWH;
GO

CREATE OR ALTER PROCEDURE bronze.load_bronze
    @SourcePath NVARCHAR(500) = 'D:\dwh24\walmart_dwh\walmart_dwh\datasets\'  -- update to your path
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @start_time     DATETIME2,
            @end_time       DATETIME2,
            @batch_start    DATETIME2,
            @proc_start     DATETIME,
            @sql            NVARCHAR(MAX);

    BEGIN TRY
        SET @batch_start = SYSDATETIME();
        SET @proc_start = GETDATE();
        
        PRINT '=========================================';
        PRINT '🚀 STARTING BRONZE LAYER LOAD';
        PRINT 'Start Time: ' + CAST(@proc_start AS NVARCHAR);
        PRINT '=========================================';
        ----------------------------------------------------------------
        -- bronze.stores
        ----------------------------------------------------------------
        SET @start_time = SYSDATETIME();
        PRINT '>> Truncating Table: bronze.stores';
        TRUNCATE TABLE bronze.stores;

        PRINT '>> Loading Table: bronze.stores';
        SET @sql = N'
            BULK INSERT bronze.stores
            FROM ''' + @SourcePath + N'stores_data-set.csv''
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = '','',
                ROWTERMINATOR = ''0x0a'',
                CODEPAGE = ''65001'',
                TABLOCK
            );';
        EXEC sp_executesql @sql;
        SET @end_time = SYSDATETIME();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS NVARCHAR) + ' ms';
        PRINT '-------------';

        ----------------------------------------------------------------
        -- bronze.features
        ----------------------------------------------------------------
        SET @start_time = SYSDATETIME();
        PRINT '>> Truncating Table: bronze.features';
        TRUNCATE TABLE bronze.features;

        PRINT '>> Loading Table: bronze.features';
        SET @sql = N'
            BULK INSERT bronze.features
            FROM ''' + @SourcePath + N'Features_data_set.csv''
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = '','',
                ROWTERMINATOR = ''0x0a'',
                CODEPAGE = ''65001'',
                TABLOCK
            );';
        EXEC sp_executesql @sql;
        SET @end_time = SYSDATETIME();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS NVARCHAR) + ' ms';
        PRINT '-------------';

        ----------------------------------------------------------------
        -- bronze.sales
        ----------------------------------------------------------------
        SET @start_time = SYSDATETIME();
        PRINT '>> Truncating Table: bronze.sales';
        TRUNCATE TABLE bronze.sales;

        PRINT '>> Loading Table: bronze.sales';
        SET @sql = N'
            BULK INSERT bronze.sales
            FROM ''' + @SourcePath + N'sales_data-set.csv''
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = '','',
                ROWTERMINATOR = ''0x0a'',
                CODEPAGE = ''65001'',
                TABLOCK
            );';
        EXEC sp_executesql @sql;
        SET @end_time = SYSDATETIME();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS NVARCHAR) + ' ms';
        PRINT '-------------';

        PRINT '================================================';
        PRINT 'Bronze Layer Load Complete. Total Duration: '
            + CAST(DATEDIFF(SECOND, @batch_start, SYSDATETIME()) AS NVARCHAR) + ' sec';
        PRINT '================================================';
    END TRY
    BEGIN CATCH
        PRINT '================================================';
        PRINT 'ERROR OCCURRED DURING BRONZE LOAD';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number:  ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error Line:    ' + CAST(ERROR_LINE() AS NVARCHAR);
        PRINT '================================================';
    END CATCH
END;
GO

-- Run it:
 EXEC bronze.load_bronze @SourcePath = 'D:\dwh24\walmart_dwh\walmart_dwh\datasets\';
