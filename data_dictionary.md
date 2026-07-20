# Data dictionary

## Source files

### stores_data-set.csv (45 rows)
| Column | Type in source | Description |
|--------|-----------------|--------------|
| Store  | int | Store identifier, 1-45 |
| Type   | text | Store category: A, B, or C |
| Size   | int | Store square footage |

### Features_data_set.csv (8,190 rows)
| Column | Type in source | Description |
|--------|-----------------|--------------|
| Store | int | Store identifier |
| Date | text DD/MM/YYYY | Week ending date |
| Temperature | float | Average regional temperature (°F) |
| Fuel_Price | float | Regional fuel cost |
| MarkDown1-5 | float or "NA" | Anonymized promotional markdown amounts (mostly populated only after Nov 2011) |
| CPI | float or "NA" | Consumer Price Index |
| Unemployment | float or "NA" | Regional unemployment rate (%) |
| IsHoliday | "TRUE"/"FALSE" | Whether the week contains a major holiday |

### sales_data-set.csv (421,570 rows)
| Column | Type in source | Description |
|--------|-----------------|--------------|
| Store | int | Store identifier |
| Dept | int | Department number, 1-99 |
| Date | text DD/MM/YYYY | Week ending date |
| Weekly_Sales | float | Sales for that store/department/week (can be negative — returns/adjustments) |
| IsHoliday | "TRUE"/"FALSE" | Whether the week contains a major holiday |

## Silver layer

### silver.stores
| Column | Type | Notes |
|--------|------|-------|
| store_id | INT, PK | |
| store_type | NVARCHAR(5) | Upper-cased, trimmed |
| store_size | INT | |
| dwh_load_date | DATETIME2 | Audit column, defaults to load time |

### silver.features
| Column | Type | Notes |
|--------|------|-------|
| store_id | INT, PK part 1 | |
| week_date | DATE, PK part 2 | Parsed from DD/MM/YYYY |
| temperature | DECIMAL(6,2) | |
| fuel_price | DECIMAL(6,3) | |
| markdown1-5 | DECIMAL(12,2), NULLable | "NA" converted to NULL |
| cpi | DECIMAL(10,4), NULLable | "NA" converted to NULL |
| unemployment | DECIMAL(6,3), NULLable | "NA" converted to NULL |
| is_holiday | BIT | "TRUE"/"FALSE" converted to 1/0 |
| dwh_load_date | DATETIME2 | Audit column |

### silver.sales
| Column | Type | Notes |
|--------|------|-------|
| sales_sk | BIGINT IDENTITY, PK | Surrogate key (no reliable natural key) |
| store_id | INT | |
| dept_id | INT | |
| week_date | DATE | Parsed from DD/MM/YYYY |
| weekly_sales | DECIMAL(14,2) | Can be negative |
| is_holiday | BIT | |
| is_negative_sale | BIT | 1 if weekly_sales < 0 (data-quality flag, not deleted) |
| dwh_load_date | DATETIME2 | Audit column |

## Gold layer (star schema, exposed as views)

### gold.dim_store
| Column | Description |
|--------|-------------|
| store_key | Surrogate key |
| store_id | Natural store number |
| store_type | A / B / C |
| store_size | Square footage |
| store_size_band | Derived: Small (<50k), Medium (<150k), Large (150k+) |

### gold.dim_department
| Column | Description |
|--------|-------------|
| department_key | Surrogate key |
| dept_id | Department number from source |
| department_name | Derived label ("Dept N"); source has no real dept names |

### gold.dim_date
| Column | Description |
|--------|-------------|
| date_key | Surrogate key, format YYYYMMDD |
| full_date | Calendar date |
| calendar_year / quarter / month / month_name | Standard calendar attributes |
| calendar_week | ISO-ish week number via DATEPART(WEEK, ...) |
| day_name | Day of week |

### gold.fact_sales
One row per store + department + week.

| Column | Description |
|--------|-------------|
| store_key, department_key, date_key | Foreign keys to dimensions |
| week_date | Convenience date column |
| weekly_sales | Measure |
| is_holiday | Flag |
| is_negative_sale | Data-quality flag |
| temperature, fuel_price, cpi, unemployment | Regional context metrics for that store+week (from Features) |
| markdown1-5 | Promotional markdown context for that store+week |
