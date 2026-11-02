-- =====================================================================
-- 02_data_quality.sql
-- Run AFTER importing all 8 tables. Write down what you find
-- (it goes in the "Data quality notes" section of your README).
-- =====================================================================

-- 1. Row counts (approximate expected values in the comments)
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers          -- ~99,441
UNION ALL SELECT 'orders',               COUNT(*) FROM orders                   -- ~99,441
UNION ALL SELECT 'order_items',          COUNT(*) FROM order_items              -- ~112,650
UNION ALL SELECT 'payments',             COUNT(*) FROM payments                 -- ~103,886
UNION ALL SELECT 'reviews',              COUNT(*) FROM reviews                  -- ~99,224
UNION ALL SELECT 'products',             COUNT(*) FROM products                 -- ~32,951
UNION ALL SELECT 'sellers',              COUNT(*) FROM sellers                  -- ~3,095
UNION ALL SELECT 'category_translation', COUNT(*) FROM category_translation;    -- 71

-- 2. Orders by status (analysis uses delivered orders only)
SELECT order_status, COUNT(*) AS orders
FROM orders
GROUP BY order_status
ORDER BY orders DESC;

-- 3. Missing values
SELECT COUNT(*) AS orders_without_delivery_date
FROM orders
WHERE order_delivered_customer_date IS NULL;

SELECT COUNT(*) AS products_without_category
FROM products
WHERE product_category_name IS NULL;

-- 4. Duplicate review IDs (handled with DISTINCT ON in the analysis)
SELECT review_id, COUNT(*) AS times_seen
FROM reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY times_seen DESC
LIMIT 5;

-- 5. Date range of the data
SELECT MIN(order_purchase_timestamp) AS first_order,
       MAX(order_purchase_timestamp) AS last_order
FROM orders;

-- 6. Anomaly checks (both should be 0 or close to 0)
SELECT COUNT(*) AS delivered_before_purchase
FROM orders
WHERE order_delivered_customer_date < order_purchase_timestamp;

SELECT COUNT(*) AS non_positive_prices
FROM order_items
WHERE price <= 0;

-- 7. Product categories with no English translation
--    (these are dropped by the INNER JOIN in the category query)
SELECT DISTINCT p.product_category_name
FROM products p
LEFT JOIN category_translation t ON t.product_category_name = p.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL;

-- 8. OPTIONAL: add foreign keys so the ER diagram shows relationships.
--    If a line fails with a violation error, skip it and note it in the README.
ALTER TABLE order_items ADD FOREIGN KEY (order_id)   REFERENCES orders(order_id);
ALTER TABLE order_items ADD FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE order_items ADD FOREIGN KEY (seller_id)  REFERENCES sellers(seller_id);
ALTER TABLE payments    ADD FOREIGN KEY (order_id)   REFERENCES orders(order_id);
ALTER TABLE reviews     ADD FOREIGN KEY (order_id)   REFERENCES orders(order_id);
