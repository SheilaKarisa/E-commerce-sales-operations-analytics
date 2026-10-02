-- 1. Initialise Data Warehouse Environment and Disable constraint checks for Bulk data
USE bat_commercial_analysis;
SET foreign_key_checks =0;

-- 2. Populate Date Dimension (dim_date) with parsed temporal values 
INSERT IGNORE INTO bat_commercial_analysis.dim_date (order_date, year, month, quarter, season) 
SELECT DISTINCT
    STR_TO_DATE(Order_date, '%m/%d/%Y'), 
    Year, 
    Month, 
    Quarter, 
    Season 
FROM bat_commercial_analysis.ecommerce_sales_dataset
WHERE Order_date IS NOT NULL 
  AND Order_date != '' 
  AND Order_date != '####';

-- 3. Populate Customers Dimension (dim_customers) inclusions
INSERT IGNORE INTO bat_commercial_analysis.dim_customers (customer_id, customer_gender, customer_segment, region, country)
SELECT DISTINCT
	Customer_ID, 
    Customer_Gender, 
    Customer_Segment, 
    Region, 
    Country
FROM bat_commercial_analysis.ecommerce_sales_dataset;

-- 4. Populate Products Dimension (dim_products)
INSERT IGNORE INTO bat_commercial_analysis.dim_products (product_name, category, sub_category, unit_price)
SELECT DISTINCT Product_Name, Category, Sub_Category, Unit_Price
FROM bat_commercial_analysis.ecommerce_sales_dataset;

-- 5. Populate New Shipping Dimension (dim_shipping)

INSERT IGNORE INTO bat_commercial_analysis.dim_shipping (shipping_cost, shipping_method, shipping_days)
SELECT DISTINCT Shipping_Cost, Shipping_Method, Shipping_Days 
FROM bat_commercial_analysis.ecommerce_sales_dataset;

-- 6. Populate Central Transactional Fact Table (fact_sales_orders)
INSERT IGNORE INTO bat_commercial_analysis.fact_sales_orders (
    order_id, order_date, customer_id, product_name, country, 
    quantity, discount, revenue, cost, profit, profit_margin, 
    shipping_cost, shipping_method, shipping_days, payment_method, order_status
) 
SELECT DISTINCT  
    Order_id, 
    STR_TO_DATE(Order_date, '%m/%d/%Y'), 
    Customer_ID, 
    Product_Name, 
    Country, 
    Quantity, 
    Discount,  
    Revenue, 
    Cost, 
    Profit, 
    `Profit_Margin_%`, 
    Shipping_Cost,     
    Shipping_Method, 
    Shipping_Days, 
    Payment_Method, 
    Order_Status 
FROM bat_commercial_analysis.ecommerce_sales_dataset 
WHERE Order_date IS NOT NULL    
  AND Order_date != ''    
  AND Order_date != '####';

-- 7. Re-enable Security Integrity Constraint Checks
SET FOREIGN_KEY_CHECKS = 1;

-- EXPLORATORY DATA ANALYTICS:
-- 1. Executive Financial Overview Metrics
SELECT 
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(quantity) AS total_items_sold,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND((SUM(profit) / SUM(revenue)) * 100, 2) AS overall_profit_margin_pct
FROM bat_commercial_analysis.fact_sales_orders;
-- An overall profit margin of 27.21% yielding over $1.4M in profit on 27,313 units sold. 
-- This confirms that the business operates with a highly lucrative healthy bottomline.

-- 2. Regional Performance and Customer Segments:
SELECT 
    c.region, 
    c.customer_segment, 
    COUNT(DISTINCT f.order_id) AS order_count, 
    ROUND(SUM(f.revenue), 2) AS total_revenue, 
    ROUND(SUM(f.profit), 2) AS total_profit 
FROM bat_commercial_analysis.fact_sales_orders f 
JOIN bat_commercial_analysis.dim_customers c 
    ON c.customer_id = f.customer_id
GROUP BY c.region, c.customer_segment
ORDER BY total_revenue DESC;
-- From the Asian Market, Regular customers contributed $722,737 in total revenue across 1258 orders.
-- North America generated $184,617 total profit, slightly higher than Asia ($184,539).
-- Regular customers across Asia, North America, Europe and Middle East are performing relatively closely to each other ($600K - $722K range)
-- This shows that the standard baseline repeat buyers are steady across the entire planet.

-- 3. Revenue By Monthly and Year 
SELECT 
    d.year, 
    d.month, 
    COUNT(DISTINCT f.order_id) as orders_placed, 
    ROUND(SUM(f.revenue), 2) as monthly_revenue 
FROM bat_commercial_analysis.fact_sales_orders f 
JOIN bat_commercial_analysis.dim_date d ON f.order_date = d.order_date 
GROUP BY d.year, d.month 
ORDER BY d.year ASC, d.month ASC;
-- There's a strong steady order growth throughout the year 2021 scaling from 7 orders in January to 110 in October. 
-- Revenue jumped significantly from $7,377 in March to $27,697 in April, Average order Value spiked $295.11 to $629.49.
-- After starting out strongly in January 2024, order_volume experienced a steady downward slide throughout the year from 329 to 12units.
-- There was a brief surge of profit in March of 2024.

-- 4. Product Categories and Margins:
SELECT 
    product_name,
    COUNT(DISTINCT order_id) AS total_orders_placed,
    SUM(quantity) AS total_units_sold,
    ROUND(SUM(revenue), 2) AS total_category_revenue,
    ROUND(SUM(profit), 2) AS total_category_profit,
    ROUND((SUM(profit) / SUM(revenue)) * 100, 2) AS product_margin_pct
FROM bat_commercial_analysis.fact_sales_orders
GROUP BY product_name
ORDER BY total_category_revenue DESC
LIMIT 10;
-- The top revenue drivers are dominated by flagship smartphones and tablets (e.g., iPhone 14, OnePlus 11, Samsung Galaxy S23).
-- iPhone 14 leads overall product revenue at $194,633.03 across 110 orders (315 total units sold) with a profit margin of 28.80%. 
-- Among the top products, Xiaomi 13 delivers the highest profit margin at 31.93% ($50,223.76 profit on $157,315.74 revenue). 
-- This is closely followed by the Lenovo Tab P12 at 30.17% ($47,870.74 profit). 

-- 5. Logistics & Order Health
SELECT 
    shipping_method,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(AVG(shipping_days), 1) AS avg_days_to_ship,
    COUNT(CASE WHEN order_status = 'Cancelled' THEN 1 END) AS cancelled_orders,
    ROUND((COUNT(CASE WHEN order_status = 'Cancelled' THEN 1 END) / COUNT(DISTINCT order_id)) * 100, 2) AS cancellation_rate_pct
FROM bat_commercial_analysis.fact_sales_orders
GROUP BY shipping_method
ORDER BY total_orders DESC;
-- Overnight shipping is taking an average of 11.5 days to ship—identical to Economy (11.5 days) and practically indistinguishable from Standard (11.4 days) and Express (11.3 days). 
-- Customers paying extra for premium tiers (Overnight/Express) are experiencing identical warehouse fulfillment lags as budget tiers.
-- Tiers with the highest expected speed show higher cancellation rates: Economy (9.42%) and Overnight (9.20%) lead in order cancellations.   
-- Standard shipping recorded the lowest cancellation rate at 8.75%.  
-- Operational Insight: The fulfillment pipeline currently exhibits zero speed differentiation between shipping tiers. 
-- Overnight orders take 11.5 days to ship, failing to meet SLA expectations and driving higher customer cancellations (9.20%).   
-- Actionable Recommendation: Warehouse processing workflows and priority queuing must be audited immediately to ensure expedited shipping tiers receive SLA priority before being handed over to carriers.

-- ADVANCED METRICS AND DEEP DIVE
-- 1. Month-over-Month (MoM) Financial Growth Trajectory (LAG Window):
WITH MonthlySales AS (
    SELECT 
        d.year,
        d.month,
        SUM(f.revenue) AS current_month_revenue
    FROM bat_commercial_analysis.fact_sales_orders f
    JOIN bat_commercial_analysis.dim_date d ON f.order_date = d.order_date
    GROUP BY d.year, d.month
)
SELECT 
    year,
    month,
    ROUND(current_month_revenue, 2) AS revenue,
    ROUND(LAG(current_month_revenue, 1) OVER (ORDER BY year, month), 2) AS previous_month_revenue,
    ROUND(
        ((current_month_revenue - LAG(current_month_revenue, 1) OVER (ORDER BY year, month)) 
        / LAG(current_month_revenue, 1) OVER (ORDER BY year, month)) * 100, 
        2
    ) AS mom_growth_pct
FROM MonthlySales
ORDER BY year ASC, month ASC;
-- Early 2021 revenue exhibited a initial decline (dropping ~20% total over Q1) before experiencing a pivotal inflection point in April with a +275.42% MoM revenue surge. 
-- Subsequent months (May through July) demonstrate a healthy stabilization phase, maintaining a consistent monthly baseline above $30k with steady single-digit growth.
-- 2024 reveals a sustained and compounding revenue decline. 
-- Unlike early 2021 performance, which saw a rapid Q2 recovery, late 2024 exhibited severe fatigue, culminating in a -68.53% drop in November and an all-time low of $5,898.51 in December.
-- This multi-month acceleration of revenue losses suggests severe underlying operational, inventory, or demand disruption toward the end of 2024 that requires immediate root-cause investigation before setting 2025 targets.

-- 2. Customer Valuation & VIP Profit Index (DENSE-RANK window) 
-- Is the drop in sales caused by a drop in customer loyalty or its just standard seasonal trends?
SELECT 
    s.order_id, 
    c.customer_segment,
    s.revenue, 
    s.cost, 
    s.profit, 
    ROUND((s.revenue - s.cost), 2) AS calculated_profit
FROM bat_commercial_analysis.fact_sales_orders s
JOIN bat_commercial_analysis.dim_customers c 
    ON s.customer_id = c.customer_id
LIMIT 10;
-- Regular, Premium, and VIP customers consistently make a profit. 
-- However, New customers are unpredictable—bringing in our highest-profit order ($1,198.69) but also our biggest losses (up to -$50.80)
-- Action Needed: Review discounts, shipping fees, and first-time buyer promos to stop losing money on new orders without scaring away big spenders.
-- 

WITH CustomerValue AS(
SELECT
     f.customer_id,
     c.customer_segment,
     c.country,
     COUNT(DISTINCT f.order_id) as total_orders_placed,
     ROUND(SUM(f.revenue), 2) as total_spent,
     ROUND(SUM(f.profit), 2) as total_profit_generated
FROM bat_commercial_analysis.fact_sales_orders f
JOIN bat_commercial_analysis.dim_customers c ON f.customer_id = c.customer_id 
GROUP BY f.customer_id, c.customer_segment, c.country
	)
    SELECT
    DENSE_RANK() OVER (ORDER BY total_profit_generated DESC) as vip_rank,
    customer_id,
    customer_segment,
    country,
    total_orders_placed,
    total_spent,
    total_profit_generated
FROM CustomerValue
LIMIT 15;
-- CUST-04179 (Rank 1, Regular segment, Mexico) generated the highest net profit at $9,144.15 on a single order.
-- CUST-01046 (Rank 3, VIP segment, Japan) recorded the highest total spend at $20,094.80 across 2 orders, generating $8,736.84 in profit.
-- CUST-06024 (Rank 2, New segment, Canada) spent $19,700.13 across 5 orders, yielding $9,054.82 in profit. 
-- This reinforces that high-value acquisitions are entering through the "New" customer pipeline.
-- The top 15 profit contributors are spread across diverse international markets, including Mexico, Canada, Japan, USA, France, Egypt, and Jordan.

-- 3. Supply Chain Logistics Efficiency & Distribution Audit
SELECT
	shipping_method,
    COUNT(DISTINCT order_id) as total_shipments,
    ROUND(AVG(shipping_days), 1) as avg_days_to_deliver,
    MIN(shipping_days) as fastest_delivery_days,
    MAX(shipping_days) as slowest_delivery_days,
    COUNT(CASE WHEN shipping_days > 5 then 1 end) as delayed_shipments,
    ROUND((COUNT(CASE WHEN shipping_days > 5 then 1 end) / COUNT(DISTINCT order_id)) *100, 2) as delay_rate_pct
FROM bat_commercial_analysis.fact_sales_orders
GROUP BY shipping_method
ORDER BY avg_days_to_deliver ASC;
-- Shipping performance is severely broken across the board. 
-- Over 87% of orders are delayed, and premium options like Overnight take just as long as Economy (~11.5 days average).
-- Customers paying extra for fast delivery are receiving standard/delayed service, directly explaining the high cancellation rates seen across tiers.

