/*
===============================================================================
Script:      ddl_bronze.sql
Purpose:     Creates the raw landing tables in the Bronze schema. Columns are
             typed loosely (mostly VARCHAR/NVARCHAR) so that BULK INSERT never
             fails on a malformed source row -- e.g. the "NA" strings used for
             missing values in Features_data_set.csv, or dates stored as text
             in DD/MM/YYYY format. All cleansing/casting happens in Silver.
Layer:       BRONZE
===============================================================================
*/
--CREATE DATABASE WalmartDWH;
USE WalmartDWH;
GO

CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO


IF OBJECT_ID('bronze.stores', 'U') IS NOT NULL
    DROP TABLE bronze.stores;
GO

CREATE TABLE bronze.stores (
    Store   INT,
    Type    NVARCHAR(5),
    Size    INT
);
GO

IF OBJECT_ID('bronze.features', 'U') IS NOT NULL
    DROP TABLE bronze.features;
GO

CREATE TABLE bronze.features (
    Store           INT,
    Date            NVARCHAR(20),   -- raw text date, format DD/MM/YYYY
    Temperature     NVARCHAR(20),
    Fuel_Price      NVARCHAR(20),
    MarkDown1       NVARCHAR(20),   -- contains "NA" strings, kept as text
    MarkDown2       NVARCHAR(20),
    MarkDown3       NVARCHAR(20),
    MarkDown4       NVARCHAR(20),
    MarkDown5       NVARCHAR(20),
    CPI             NVARCHAR(20),
    Unemployment    NVARCHAR(20),
    IsHoliday       NVARCHAR(10)    -- "TRUE"/"FALSE" text
);
GO

IF OBJECT_ID('bronze.sales', 'U') IS NOT NULL
    DROP TABLE bronze.sales;
GO

CREATE TABLE bronze.sales (
    Store           INT,
    Dept            INT,
    Date            NVARCHAR(20),   -- raw text date, format DD/MM/YYYY
    Weekly_Sales    NVARCHAR(20),
    IsHoliday       NVARCHAR(10)    -- "TRUE"/"FALSE" text
);
GO
