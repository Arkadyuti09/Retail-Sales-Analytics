# 🛒 Retail Sales Analytics — Power BI Dashboard

An interactive Power BI dashboard for analyzing weekly retail sales performance across stores and departments, built on top of a **star-schema data warehouse (`WalmartDWH`)**. The report gives leadership, store managers, and analysts a single view into revenue trends, store/department performance, seasonality, and macroeconomic drivers such as fuel price, CPI, and unemployment.

1. 📊 Overview

This project transforms raw retail transaction data into a curated **gold-layer** dimensional model and visualizes it through a three-page Power BI report:

| Page | Purpose |
|---|---|
| **Executive Overview** | High-level KPIs, YoY sales trends, sales vs. target achievement, and holiday impact |
| **Store Performance** | Store-level sales breakdown, rankings by store type/size, and comparative trends |
| **Department Performance** | Department-level sales contribution, rankings, and cumulative (Pareto-style) analysis |


2. Architecture

```
 stores.csv   features.csv   sales.csv
      |            |              |
      v            v              v
 +------------------------------------------+
 |  BRONZE   raw load, loose text types     |
 +------------------------------------------+
                    |  cleanse, cast, dedup
                    v
 +------------------------------------------+
 |  SILVER   typed, conformed, audited      |
 +------------------------------------------+
                    |  model as star schema
                    v
 +------------------------------------------+
 |  GOLD     dims + fact, exposed as views  |
 +------------------------------------------+
```
3. 🗂️ Data Model

The report connects to a SQL Server database (`WalmartDWH`) and consumes tables from its **gold schema**, following a classic **star schema** design:

```
                     ┌────────────────────┐
                     │   gold dim_date     │
                     └─────────┬──────────┘
                               │
┌───────────────────┐   ┌─────▼──────────┐   ┌───────────────────────┐
│ gold dim_store     ├───┤ gold fact_sales├───┤  gold dim_department  │
└───────────────────┘   └────────────────┘   └───────────────────────┘
```

**Fact table**
- `gold fact_sales` — weekly sales grain, including `weekly_sales`, `is_holiday`, `temperature`, `fuel_price`, `cpi`, `unemployment`, and markdown promotions (`markdown1`–`markdown5`)

**Dimension tables**
- `gold dim_date` — calendar attributes (year, quarter, month, week, day name)
- `gold dim_store` — store ID, type, size, and size band
- `gold dim_department` — department ID and name

4. 📐 Key Measures (DAX)

The model includes a dedicated measures table with calculations such as:

- `Total_Sales`, `Avg_WeeklySales`, `Total_Sales_M` — core aggregations
- `Previous Year Sales`, `YoY Sales Change`, `YoY Sales Growth %` — year-over-year trend analysis
- `Achievement %`, `Sales Target`, `Gauge Max` — performance vs. target tracking
- `Department Rank`, `Cumulative Sales`, `Cumulative Sales %`, `Best Department` — Pareto/ranking analysis for departments
- `Store_Type_Rank` — comparative ranking across store types
- `Holiday Flag` — isolates holiday-week sales impact
- `Total Stores`, `Total Departments`, `Average Cpi` — descriptive summary metrics

5. 🛠️ Tech Stack

- **Power BI Desktop** (report authoring & modeling)
- **Power Query (M)** — data cleansing and transformation (trimming text, replacing nulls, type casting)
- **DAX** — measures and calculated logic
- **SQL Server** — source data warehouse (`WalmartDWH`, gold schema)

6. 📁 Repository Contents

```
Retail_Analytics.pbit    # Power BI Template file (structure + queries + DAX, no data)
```

> This is a `.pbit` **template** file — it ships with the full data model, Power Query logic, and report layout, but **no data is embedded**. Opening it will prompt you to connect to your own SQL Server instance and supply the `WalmartDWH` database (or point it at a compatible data source).

## 🚀 Getting Started

7. Prerequisites
- [Power BI Desktop](https://powerbi.microsoft.com/desktop/) (latest version recommended)
- Access to a SQL Server instance hosting a `WalmartDWH` database with the following gold-layer tables:
  - `gold.dim_date`
  - `gold.dim_store`
  - `gold.dim_department`
  - `gold.fact_sales`

8. 📈 Report Pages in Detail

**Executive Overview**
KPI cards, a sales trend column/area chart, YoY waterfall breakdown, and a department contribution donut — designed as a first-glance summary for stakeholders.

**Store Performance**
Treemap and ranked bar/column charts comparing stores by size, type, and sales; a pivot table and slicers for drill-down; a scatter chart to explore relationships between store attributes and sales.

**Department Performance**
Ranked bar chart and cumulative-sales (Pareto) view to identify top-contributing departments, alongside a pivot table and slicers for filtering by date/store.

9. Steps
1. Clone this repository:
   ```bash
   git clone <repo-url>
   cd retail-analytics
   ```
2. Open `Retail_Analytics.pbit` in Power BI Desktop.
3. When prompted, enter your SQL Server connection details (server name and database).
4. Power BI will load the schema and refresh the visuals using your data.
5. (Optional) Once loaded, save as `.pbix` to persist data alongside the report.

> 💡 If your source tables live in a different database/schema, update the source step in **Power Query Editor → Transform Data** for each table to point to the correct location.

10. Screenshots
    example : Page 1: https://github.com/Arkadyuti09/Retail-Sales-Analytics/blob/main/Page%201%20of%20the%20Dashbaord.png
              Page 2: 
