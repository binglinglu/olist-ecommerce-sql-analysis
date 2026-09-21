-- Olist Data Import
-- Before running:
--   1. Replace every /path/to/olist/ below with the folder where your CSVs are stored (keep the trailing slash)
--   2. Run SET GLOBAL local_infile = 1;  (requires the necessary privileges)
--   3. In Workbench: Connection settings -> Advanced -> Others, add a line: OPT_LOCAL_INFILE=1, then reconnect
-- If your CSVs use Windows line endings, change '\n' to '\r\n' below
 
USE olist;
SET FOREIGN_KEY_CHECKS = 0;
SET NAMES utf8mb4;
 
-- Customers
LOAD DATA LOCAL INFILE '/path/to/olist/olist_customers_dataset.csv'
INTO TABLE customers
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state);
 
-- Sellers
LOAD DATA LOCAL INFILE '/path/to/olist/olist_sellers_dataset.csv'
INTO TABLE sellers
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(seller_id, seller_zip_code_prefix, seller_city, seller_state);
 
-- Products (blank values converted to NULL)
LOAD DATA LOCAL INFILE '/path/to/olist/olist_products_dataset.csv'
INTO TABLE products
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(product_id, @cat, @nl, @dl, @pq, @wg, @len, @hei, @wid)
SET product_category_name      = NULLIF(@cat, ''),
    product_name_length        = NULLIF(@nl, ''),
    product_description_length = NULLIF(@dl, ''),
    product_photos_qty         = NULLIF(@pq, ''),
    product_weight_g           = NULLIF(@wg, ''),
    product_length_cm          = NULLIF(@len, ''),
    product_height_cm          = NULLIF(@hei, ''),
    product_width_cm           = NULLIF(@wid, '');
 
-- Category translation
LOAD DATA LOCAL INFILE '/path/to/olist/product_category_name_translation.csv'
INTO TABLE category_translation
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(product_category_name, product_category_name_english);
 
-- Orders (blank dates converted to NULL)
LOAD DATA LOCAL INFILE '/path/to/olist/olist_orders_dataset.csv'
INTO TABLE orders
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, customer_id, order_status, @purchase, @approved, @carrier, @delivered, @estimated)
SET order_purchase_timestamp      = NULLIF(@purchase, ''),
    order_approved_at             = NULLIF(@approved, ''),
    order_delivered_carrier_date  = NULLIF(@carrier, ''),
    order_delivered_customer_date = NULLIF(@delivered, ''),
    order_estimated_delivery_date = NULLIF(@estimated, '');
 
-- Order items
LOAD DATA LOCAL INFILE '/path/to/olist/olist_order_items_dataset.csv'
INTO TABLE order_items
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value);
 
-- Payments
LOAD DATA LOCAL INFILE '/path/to/olist/olist_order_payments_dataset.csv'
INTO TABLE order_payments
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, payment_sequential, payment_type, payment_installments, payment_value);
 
-- Reviews (comments may contain line breaks and quotes; ENCLOSED BY handles this)
LOAD DATA LOCAL INFILE '/path/to/olist/olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(review_id, order_id, review_score, @title, @message, @created, @answered)
SET review_comment_title    = NULLIF(@title, ''),
    review_comment_message  = NULLIF(@message, ''),
    review_creation_date    = NULLIF(@created, ''),
    review_answer_timestamp = NULLIF(@answered, '');
 
SET FOREIGN_KEY_CHECKS = 1;
 
-- ========== Post-import validation ==========
-- 1) Row counts (expected: customers 99441, orders 99441, order_items 112650,
--    payments 103886, reviews ~99224, products 32951, sellers 3095)
SELECT 'customers' AS t, COUNT(*) AS n FROM customers
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'sellers', COUNT(*) FROM sellers;
 
-- 2) Orphan record check (all should return 0)
SELECT COUNT(*) AS orphan_items
FROM order_items oi LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;
 
SELECT COUNT(*) AS orphan_orders
FROM orders o LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
 
