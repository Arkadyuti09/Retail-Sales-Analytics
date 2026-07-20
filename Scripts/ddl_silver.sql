/*
===============================================================================
Script:      ddl_silver.sql
Purpose:     Creates cleansed, properly-typed tables in the Silver schema.
             Source "NA" strings become real NULLs, dates become DATE,
             numerics become DECIMAL/FLOAT, booleans become BIT.
             A dwh_load_date audit column is added to every table.
Layer:       SILVER
===============================================================================
*/

USE WalmartDWH;
GO

IF OBJECT_ID('silver.stores', 'U') IS NOT NULL
    DROP TABLE silver.stores;
GO

CREATE TABLE silver.stores (
    store_id        INT             NOT NULL,
    store_type      NVARCHAR(5)     NOT NULL,   -- A, B, or C
    store_size      INT             NOT NULL,   -- square footage
    dwh_load_date   DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_silver_stores PRIMARY KEY (store_id)
);
GO

IF OBJECT_ID('silver.features', 'U') IS NOT NULL
    DROP TABLE silver.features;
GO

CREATE TABLE silver.features (
    store_id        INT             NOT NULL,
    week_date       DATE            NOT NULL,
    temperature     DECIMAL(6,2)    NULL,       -- avg regional temp (F)
    fuel_price      DECIMAL(6,3)    NULL,       -- regional fuel cost
    markdown1       DECIMAL(12,2)   NULL,       -- anonymized promo markdown
    markdown2       DECIMAL(12,2)   NULL,
    markdown3       DECIMAL(12,2)   NULL,
    markdown4       DECIMAL(12,2)   NULL,
    markdown5       DECIMAL(12,2)   NULL,
    cpi             DECIMAL(10,4)   NULL,       -- consumer price index
    unemployment    DECIMAL(6,3)    NULL,       -- regional unemployment %
    is_holiday      BIT             NOT NULL,
    dwh_load_date   DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_silver_features PRIMARY KEY (store_id, week_date)
);
GO

IF OBJECT_ID('silver.sales', 'U') IS NOT NULL
    DROP TABLE silver.sales;
GO

CREATE TABLE silver.sales (
    sales_sk        BIGINT IDENTITY(1,1) NOT NULL, -- surrogate key (no natural PK: same store/dept/date can repeat in source)
    store_id        INT             NOT NULL,
    dept_id         INT             NOT NULL,
    week_date       DATE            NOT NULL,
    weekly_sales    DECIMAL(14,2)   NOT NULL,
    is_holiday      BIT             NOT NULL,
    is_negative_sale BIT            NOT NULL,   -- data-quality flag: TRUE if weekly_sales < 0 (return/adjustment)
    dwh_load_date   DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_silver_sales PRIMARY KEY (sales_sk)
);
GO

CREATE INDEX IX_silver_sales_store_dept_date
    ON silver.sales (store_id, dept_id, week_date);
GO
