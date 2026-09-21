-- Olist E-commerce Project: Database & Table Creation
-- Run this entire script in MySQL Workbench

DROP DATABASE IF EXISTS olist;
CREATE DATABASE olist CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE olist;

-- 1. Customers
CREATE TABLE customers (
    customer_id              CHAR(32) PRIMARY KEY,   -- a new customer_id is generated for every order
    customer_unique_id       CHAR(32) NOT NULL,      -- the actual person-level identifier; use this for repeat-purchase analysis
    customer_zip_code_prefix INT,
    customer_city            VARCHAR(100),
    customer_state           CHAR(2),
    INDEX idx_unique (customer_unique_id)
);

-- 2. Sellers
CREATE TABLE sellers (
    seller_id              CHAR(32) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city            VARCHAR(100),
    seller_state           CHAR(2)
);

-- 3. Products
CREATE TABLE products (
    product_id                 CHAR(32) PRIMARY KEY,
    product_category_name      VARCHAR(100),
    product_name_length        INT,
    product_description_length INT,
    product_photos_qty         INT,
    product_weight_g           INT,
    product_length_cm          INT,
    product_height_cm          INT,
    product_width_cm           INT
);

-- 4. Category name translation (Portuguese -> English)
CREATE TABLE category_translation (
    product_category_name         VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

-- 5. Orders
CREATE TABLE orders (
    order_id                      CHAR(32) PRIMARY KEY,
    customer_id                   CHAR(32) NOT NULL,
    order_status                  VARCHAR(20),
    order_purchase_timestamp      DATETIME,
    order_approved_at             DATETIME,
    order_delivered_carrier_date  DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    INDEX idx_purchase (order_purchase_timestamp),
    INDEX idx_status (order_status)
);

-- 6. Order items (composite PK: order + line item number)
CREATE TABLE order_items (
    order_id            CHAR(32) NOT NULL,
    order_item_id       INT NOT NULL,
    product_id          CHAR(32) NOT NULL,
    seller_id           CHAR(32) NOT NULL,
    shipping_limit_date DATETIME,
    price               DECIMAL(10,2),
    freight_value       DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id),
    CONSTRAINT fk_items_order   FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    CONSTRAINT fk_items_product FOREIGN KEY (product_id) REFERENCES products(product_id),
    CONSTRAINT fk_items_seller  FOREIGN KEY (seller_id)  REFERENCES sellers(seller_id),
    INDEX idx_items_product (product_id),
    INDEX idx_items_seller (seller_id)
);

-- 7. Payments (composite PK: order + payment sequence number)
CREATE TABLE order_payments (
    order_id             CHAR(32) NOT NULL,
    payment_sequential   INT NOT NULL,
    payment_type         VARCHAR(20),
    payment_installments INT,
    payment_value        DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential),
    CONSTRAINT fk_pay_order FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- 8. Reviews (review_id has duplicates in the raw data, so use a surrogate auto-increment PK)
CREATE TABLE order_reviews (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    review_id               CHAR(32),
    order_id                CHAR(32) NOT NULL,
    review_score            TINYINT,
    review_comment_title    VARCHAR(255),
    review_comment_message  TEXT,
    review_creation_date    DATETIME,
    review_answer_timestamp DATETIME,
    CONSTRAINT fk_rev_order FOREIGN KEY (order_id) REFERENCES orders(order_id),
    INDEX idx_rev_order (order_id)
);