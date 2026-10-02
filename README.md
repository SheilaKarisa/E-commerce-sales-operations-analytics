
# E-Commerce Commercial Analysis & Fulfillment Operations Audit
> **An End-to-End Enterprise Data Warehouse & Business Intelligence Pipeline**

## Executive Project Summary
This project delivers a production-grade relational database and business intelligence framework built to audit global retail sales vectors and logistics fulfillment efficiencies. Transitioning raw e-commerce transaction logs through a structured ETL pipeline into a customized Star Schema configuration, this analytical suite exposes deep operational friction points where premium distribution tiers fail to hit service benchmarks—directly causing consumer order drop-offs and hitting corporate profit margins.

* **Total Active Revenue Managed:** $5,284,387  
* **Total Transactions Audited:** 10,000 Distinct Orders  
* **Calculated Corporate Profit Margin:** 27.21% ($1,437,600 Net Return)
* **Total Units Marketed:** 27,313 Items Sold

---

## Interactive Dashboard Interface
![Executive Dashboard Interface](./dashboard/dashboard_preview.png)

*Features a responsive unified design utilizing rounded-shape containers, regional cross-filtering tracking geo-localization deviations, and a custom product category hierarchy slicer tracking performance by year.*

---

## Architecture Pipeline & Modeling
1. **Staging:** Ingestion of raw transactional flat text exports into an explicit operational workspace.
2. **Database Engine & Transformation:** Structured validation handling formatting faults (e.g., text date conversions, duplicate handling) on a local **MySQL Server**.
3. **Data Modeling:** Decoupling flat records into a highly scalable, one-to-many **Star Schema framework** connecting central facts (`fact_sales_orders`) directly to distinct dimensional indices (`dim_customers`, `dim_products`, `dim_date`, `dim_shipping`).
4. **Visual Intelligence Canvas:** Native live data connection to **Power BI Desktop**, incorporating dynamic DAX calculation layers.

---

## Key Strategic Discoveries
* **Fulfillment Failure Bottleneck:** Comprehensive logistics aggregation proved that **Overnight and Express shipping options flatten out to an identical 11.5-day delivery average**—completely failing to outperform standard pipelines.
* **The Revenue Drain Connection:** Proved extended wait times across low-cost consumer lines (such as supplements and beauty products) trigger localized purchase fatigue, inflating processing queues to **962 backlogged units** due to cancellation ripples.
* **Macroeconomic Year-over-Year Trajectory:** Annual trend metrics isolate massive growth velocity scaling aggressively through **2021 and 2022, peaking spectacularly in 2023** via the Electronics sector, before facing a sharp global market contraction across all territories in **2024**.

---

## Technical Code Highlights

### Advanced Trajectory Analytics (SQL Window Functions)
```sql
WITH MonthlySales AS (
    SELECT d.year, d.month, SUM(f.revenue) AS current_month_revenue
    FROM fact_sales_orders f
    JOIN dim_date d ON f.order_date = d.order_date
    GROUP BY d.year, d.month
)
SELECT year, month, ROUND(current_month_revenue, 2) AS revenue,
       ROUND(LAG(current_month_revenue, 1) OVER (ORDER BY year, month), 2) AS previous_month_revenue,
       ROUND(((current_month_revenue - LAG(current_month_revenue, 1) OVER (ORDER BY year, month)) / LAG(current_month_revenue, 1) OVER (ORDER BY year, month)) * 100, 2) AS mom_growth_pct
FROM MonthlySales
ORDER BY year ASC, month ASC;
```
### 📉 Deep-Dive Revenue Trajectory Analysis
* **Early 2021 Performance:** Revenue exhibited an initial decline, **dropping ~20% total over Q1**, before experiencing a pivotal inflection point in April with a **+275.42% MoM revenue surge**. Subsequent months (May through July) demonstrated a healthy stabilization phase, maintaining a consistent monthly baseline **above \$30,000** with steady single-digit growth.
* **Late 2024 Performance:** 2024 reveals a sustained and compounding revenue decline. Unlike the rapid Q2 recovery seen in 2021, late 2024 exhibited severe fatigue, culminating in a **-68.53% drop in November** and an all-time low of **\$5,898.51 in December**.
* **Strategic Outlook:** This multi-month acceleration of revenue losses suggests severe underlying **operational, inventory, or demand disruption** toward the end of 2024 that requires immediate root-cause investigation before setting 2025 targets.

### True Weighted Corporate Efficiency (Power BI DAX)
```dax
Total Profit Margin % = 
DIVIDE(
    SUM(fact_sales_orders[profit]), 
    SUM(fact_sales_orders[revenue])
)
```

