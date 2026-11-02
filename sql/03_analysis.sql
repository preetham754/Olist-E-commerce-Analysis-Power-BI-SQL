-- =====================================================================
-- 03_analysis.sql
-- Olist E-Commerce analysis (PostgreSQL). Amounts are in Brazilian reais (R$).
-- All queries use delivered orders only.
-- In DBeaver: click inside ONE query and press Command + Return to run it.
-- After each query, export the result to CSV with the file name shown.
-- =====================================================================


-- ---------------------------------------------------------------------
-- Query 1: How big is the business?            -> q01_kpis.csv
-- ---------------------------------------------------------------------
SELECT COUNT(DISTINCT o.order_id)                              AS orders,
       COUNT(DISTINCT c.customer_unique_id)                    AS customers,
       ROUND(SUM(oi.price), 2)                                 AS revenue,
       ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2)    AS avg_order_value
FROM orders o
JOIN customers c   ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id  = o.order_id
WHERE o.order_status = 'delivered';


-- ---------------------------------------------------------------------
-- Query 2: Monthly revenue and growth vs last month  -> q02_monthly_revenue.csv
-- ---------------------------------------------------------------------
WITH monthly AS (
  SELECT DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month,
         COUNT(DISTINCT o.order_id)                            AS orders,
         SUM(oi.price)                                         AS revenue
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.order_status = 'delivered'
  GROUP BY 1
)
SELECT month,
       orders,
       ROUND(revenue, 2) AS revenue,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
             / LAG(revenue) OVER (ORDER BY month), 1) AS mom_growth_pct
FROM monthly
ORDER BY month;


-- ---------------------------------------------------------------------
-- Query 3: Revenue by month and state          -> q03_revenue_by_state.csv
-- ---------------------------------------------------------------------
SELECT DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month,
       c.customer_state,
       COUNT(DISTINCT o.order_id)                            AS orders,
       ROUND(SUM(oi.price), 2)                               AS revenue
FROM orders o
JOIN customers c    ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id   = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY 1, 2
ORDER BY 1, 2;


-- ---------------------------------------------------------------------
-- Query 4: Top 10 product categories          -> q04_top_categories.csv
-- ---------------------------------------------------------------------
SELECT t.product_category_name_english AS category,
       COUNT(DISTINCT o.order_id)      AS orders,
       ROUND(SUM(oi.price), 2)         AS revenue
FROM orders o
JOIN order_items oi          ON oi.order_id = o.order_id
JOIN products p              ON p.product_id = oi.product_id
JOIN category_translation t  ON t.product_category_name = p.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY revenue DESC
LIMIT 10;


-- ---------------------------------------------------------------------
-- Query 5: Average order value by state       -> q05_aov_by_state.csv
-- ---------------------------------------------------------------------
SELECT c.customer_state,
       COUNT(DISTINCT o.order_id)                           AS orders,
       ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders o
JOIN customers c    ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id   = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY avg_order_value DESC;


-- ---------------------------------------------------------------------
-- Query 6: One-time vs repeat customers       -> q06_repeat_customers.csv
-- ---------------------------------------------------------------------
WITH cust AS (
  SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS n
  FROM orders o
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status = 'delivered'
  GROUP BY 1
)
SELECT CASE WHEN n = 1 THEN 'One-time' ELSE 'Repeat' END AS customer_type,
       COUNT(*)                                            AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)  AS pct
FROM cust
GROUP BY 1;


-- ---------------------------------------------------------------------
-- Query 7: Customer segments (RFM)            -> q07_rfm_segments.csv
-- Recency = days since last purchase, Frequency = number of orders,
-- Monetary = total spend.
-- ---------------------------------------------------------------------
WITH rfm AS (
  SELECT c.customer_unique_id,
         (SELECT MAX(order_purchase_timestamp)::date + 1
          FROM orders WHERE order_status = 'delivered')
           - MAX(o.order_purchase_timestamp)::date AS recency,
         COUNT(DISTINCT o.order_id)                AS frequency,
         SUM(p.payment_value)                      AS monetary
  FROM orders o
  JOIN customers c ON c.customer_id = o.customer_id
  JOIN payments p  ON p.order_id    = o.order_id
  WHERE o.order_status = 'delivered'
  GROUP BY 1
),
scored AS (
  SELECT *,
         NTILE(5) OVER (ORDER BY recency DESC) AS r,
         NTILE(5) OVER (ORDER BY monetary)     AS m
  FROM rfm
)
SELECT CASE WHEN r >= 4 AND m >= 4 THEN 'Champions'
            WHEN r >= 4            THEN 'Recent'
            WHEN m >= 4            THEN 'Big spenders at risk'
            ELSE 'Low value' END   AS segment,
       COUNT(*)                    AS customers,
       ROUND(AVG(monetary), 2)     AS avg_spend,
       ROUND(SUM(monetary), 2)     AS total_spend
FROM scored
GROUP BY 1
ORDER BY customers DESC;


-- ---------------------------------------------------------------------
-- Query 8: Cohort retention                   -> q08_cohorts.csv
-- For each first-purchase month, how many customers were active
-- 0, 1, 2... months later.
-- ---------------------------------------------------------------------
WITH first_order AS (
  SELECT c.customer_unique_id,
         MIN(DATE_TRUNC('month', o.order_purchase_timestamp)) AS cohort
  FROM orders o
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status = 'delivered'
  GROUP BY 1
),
activity AS (
  SELECT DISTINCT c.customer_unique_id,
         DATE_TRUNC('month', o.order_purchase_timestamp) AS m
  FROM orders o
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status = 'delivered'
)
SELECT f.cohort::date AS cohort_month,
       (EXTRACT(YEAR FROM age(a.m, f.cohort)) * 12
        + EXTRACT(MONTH FROM age(a.m, f.cohort)))::int AS months_since_first,
       COUNT(*) AS customers
FROM first_order f
JOIN activity a ON a.customer_unique_id = f.customer_unique_id
GROUP BY 1, 2
ORDER BY 1, 2;


-- ---------------------------------------------------------------------
-- Query 9: Delivery speed by month            -> q09_delivery_by_month.csv
-- ---------------------------------------------------------------------
SELECT DATE_TRUNC('month', order_purchase_timestamp)::date AS month,
       ROUND(AVG(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp)) / 86400)::numeric, 1)
                                                           AS avg_delivery_days,
       ROUND(100.0 * AVG(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date
                              THEN 1 ELSE 0 END), 1)       AS late_pct
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
GROUP BY 1
ORDER BY 1;


-- ---------------------------------------------------------------------
-- Query 10: Late deliveries vs review score   -> q10_late_vs_review.csv
-- (headline finding; keeps one review per order)
-- ---------------------------------------------------------------------
WITH r AS (
  SELECT DISTINCT ON (order_id) order_id, review_score
  FROM reviews
  ORDER BY order_id, review_answer_timestamp DESC
)
SELECT CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 'Late' ELSE 'On time' END AS delivery,
       COUNT(*)                            AS orders,
       ROUND(AVG(r.review_score), 2)       AS avg_review
FROM orders o
JOIN r ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY 1;


-- ---------------------------------------------------------------------
-- Query 11: Top sellers and their late rate   -> q11_sellers.csv
-- Only sellers with at least 30 orders.
-- ---------------------------------------------------------------------
SELECT oi.seller_id,
       s.seller_state,
       COUNT(DISTINCT o.order_id) AS orders,
       ROUND(SUM(oi.price), 2)    AS revenue,
       ROUND(100.0 * AVG(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                              THEN 1 ELSE 0 END), 1) AS late_pct
FROM orders o
JOIN order_items oi ON oi.order_id  = o.order_id
JOIN sellers s      ON s.seller_id  = oi.seller_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY 1, 2
HAVING COUNT(DISTINCT o.order_id) >= 30
ORDER BY revenue DESC
LIMIT 25;


-- ---------------------------------------------------------------------
-- Query 12: Payment methods                   -> q12_payments.csv
-- ---------------------------------------------------------------------
SELECT payment_type,
       COUNT(*)                         AS payments,
       ROUND(SUM(payment_value), 2)     AS total_value,
       ROUND(AVG(payment_installments), 1) AS avg_installments
FROM payments
GROUP BY 1
ORDER BY total_value DESC;
