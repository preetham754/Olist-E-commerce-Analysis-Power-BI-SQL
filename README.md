# Olist-E-commerce-Analysis-Power-BI-SQL
# Olist E-Commerce: Sales, Customer & Delivery Analysis

## Business problem
[Two lines. Example: An online marketplace wants to understand where its revenue
comes from, whether customers return, and how delivery delays affect satisfaction.]

## Dataset
Brazilian E-Commerce Public Dataset by Olist (Kaggle): about 100k orders from
2016 to 2018 across 8 related tables. Amounts are in Brazilian reais (R$).

## Tools
PostgreSQL, DBeaver, Power BI

## Approach
1. Loaded 8 CSV files into PostgreSQL and checked row counts and data quality.
2. Wrote 12 queries using joins, CTEs and window functions (LAG, RANK, NTILE).
3. Exported the results as CSV files and built a 3-page Power BI dashboard.

## Data quality notes
- [Example: about 3% of orders had no delivery date and were excluded.]
- [Example: analyzed delivered orders only.]
- [Example: review comment text was dropped because it was not needed.]

## Key insights
1. [Late deliveries lowered the average review score from X to Y.]
2. [Only X% of customers made a repeat purchase.]
3. [Revenue peaked in Month Year at R$X.]
4. [Top 3 categories made up X% of revenue.]

## Recommendations
1. [Example: focus on the sellers with the highest late-delivery rates.]
2. [Example: run a retention campaign for high-value customers.]

## Dashboard
![Overview](dashboard/overview.png)
![Customers](dashboard/customers.png)
![Delivery](dashboard/delivery.png)

## Files
- `sql/` - schema, data quality checks and analysis queries
- `exports/` - query results used in Power BI
- `dashboard/` - screenshots and the Power BI file

## Dataset link
[Paste the Kaggle URL here]
