-- =====================================================================
-- 01_schema.sql
-- Olist E-Commerce project (PostgreSQL)
-- Run this once, on the "olist" database, BEFORE importing the CSV files.
-- Import order: customers, sellers, products, category_translation,
--               orders, order_items, payments, reviews
-- =====================================================================

CREATE TABLE customers (
  customer_id              TEXT PRIMARY KEY,
  customer_unique_id       TEXT,
  customer_zip_code_prefix TEXT,
  customer_city            TEXT,
  customer_state           TEXT
);

CREATE TABLE sellers (
  seller_id              TEXT PRIMARY KEY,
  seller_zip_code_prefix TEXT,
  seller_city            TEXT,
  seller_state           TEXT
);

CREATE TABLE products (
  product_id                 TEXT PRIMARY KEY,
  product_category_name      TEXT,
  product_name_lenght        INT,   -- spelling matches the original dataset
  product_description_lenght INT,
  product_photos_qty         INT,
  product_weight_g           INT,
  product_length_cm          INT,
  product_height_cm          INT,
  product_width_cm           INT
);

CREATE TABLE category_translation (
  product_category_name         TEXT PRIMARY KEY,
  product_category_name_english TEXT
);

CREATE TABLE orders (
  order_id                      TEXT PRIMARY KEY,
  customer_id                   TEXT REFERENCES customers(customer_id),
  order_status                  TEXT,
  order_purchase_timestamp      TIMESTAMP,
  order_approved_at             TIMESTAMP,
  order_delivered_carrier_date  TIMESTAMP,
  order_delivered_customer_date TIMESTAMP,
  order_estimated_delivery_date TIMESTAMP
);

CREATE TABLE order_items (
  order_id            TEXT,
  order_item_id       INT,
  product_id          TEXT,
  seller_id           TEXT,
  shipping_limit_date TIMESTAMP,
  price               NUMERIC(10,2),
  freight_value       NUMERIC(10,2),
  PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE payments (
  order_id             TEXT,
  payment_sequential   INT,
  payment_type         TEXT,
  payment_installments INT,
  payment_value        NUMERIC(10,2)
);

-- No primary key: review_id repeats in the raw data.
CREATE TABLE reviews (
  review_id               TEXT,
  order_id                TEXT,
  review_score            INT,
  review_comment_title    TEXT,
  review_comment_message  TEXT,
  review_creation_date    TIMESTAMP,
  review_answer_timestamp TIMESTAMP
);
