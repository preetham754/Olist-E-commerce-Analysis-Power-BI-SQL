# Olist E-Commerce: Sales, Customer & Delivery Analysis

## Business problem
An online marketplace wants to understand where its revenue comes from, whether customers come back to buy again, and how late deliveries affect customer satisfaction.

## Dataset
Brazilian E-Commerce Public Dataset by Olist (Kaggle): about 100k orders from 2016 to 2018 across 8 related tables. Amounts are in Brazilian reais (R$).

## Tools
PostgreSQL, DBeaver, Power BI

## Approach
1. Loaded 8 CSV files into PostgreSQL and checked row counts and data quality.
2. Wrote 12 queries using joins, CTEs and window functions (LAG, RANK, NTILE).
3. Exported the results as CSV files and built a 3-page Power BI dashboard.

## Data quality notes
- Analysis covers delivered orders only.
- Orders without a delivery date were excluded from the delivery analysis.
- Review comment text was not used, so only review scores and dates were loaded.
- Duplicate review records were reduced to one review per order.

## Key insights
1. Late deliveries lowered the average review score from ___ (on time) to ___ (late).
2. Only ___% of customers made a repeat purchase.
3. Monthly revenue peaked in ___ at R$___.
4. The top 3 categories made up ___% of revenue.

## Recommendations
1. Prioritize delivery improvements for the sellers with the highest late-delivery rates.
2. Run a retention campaign for high-value customers, since most customers buy only once.

## Dashboard
![Overview](Dashboard/overview.png)
![Customers](Dashboard/customers.png)
![Delivery](Dashboard/delivery.png)

## Files
- `sql/` - schema, data quality checks and analysis queries
- `exports/` - query results used in Power BI
- `dashboard/` - screenshots and the Power BI file

## Dataset link
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
