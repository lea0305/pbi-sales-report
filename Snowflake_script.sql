USE DATABASE OLIST_DB;
USE SCHEMA CURATED;
-------------------------------------------------------------
CREATE OR REPLACE TABLE DIM_CUSTOMERS AS
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM RAW.OLIST_CUSTOMERS;
------------------------------------------------------------

CREATE OR REPLACE TABLE DIM_PRODUCTS AS
SELECT
    p.product_id,
    t.product_category_name_english AS category,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM RAW.OLIST_PRODUCTS p
LEFT JOIN RAW.CATEGORY_TRANSLATION t
       ON p.product_category_name = t.product_category_name;
-----------------------------------------------------------

CREATE OR REPLACE TABLE DIM_SELLERS AS
SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM RAW.OLIST_SELLERS;
------------------------------------------------------------

CREATE OR REPLACE TABLE DIM_DATE AS
WITH dates AS (
    SELECT DATEADD(day, seq4(), '2016-01-01') AS dt
    FROM TABLE(GENERATOR(ROWCOUNT => 2000))
)
SELECT
    dt AS date,
    YEAR(dt) AS year,
    MONTH(dt) AS month,
    DAY(dt) AS day,
    TO_CHAR(dt, 'MMMM') AS month_name,
    MONTH(dt) AS month_num,
    WEEKOFYEAR(dt) AS week_num
FROM dates;
------------------------------------------------------------


CREATE OR REPLACE TABLE FACT_ORDERS AS
WITH orders AS (
    SELECT
        o.order_id,
        TRY_TO_TIMESTAMP(o.order_purchase_timestamp) AS order_date,
        o.customer_id,
        o.order_status
    FROM RAW.OLIST_ORDERS o
),

items AS (
    SELECT
        order_id,
        product_id,
        seller_id,
        TRY_TO_DECIMAL(price) AS price,
        TRY_TO_DECIMAL(freight_value) AS freight
    FROM RAW.OLIST_ORDER_ITEMS
),

payments AS (
    SELECT
        order_id,
        SUM(TRY_TO_DECIMAL(payment_value)) AS revenue
    FROM RAW.OLIST_ORDER_PAYMENTS
    GROUP BY order_id
),

reviews AS (
    SELECT
        order_id,
        AVG(TRY_TO_NUMBER(review_score)) AS review_score
    FROM RAW.OLIST_ORDER_REVIEWS
    GROUP BY order_id
)

SELECT
    o.order_id,
    o.order_date,
    o.customer_id,
    i.product_id,
    i.seller_id,
    i.price,
    i.freight,
    pay.revenue,
    r.review_score
FROM orders o
LEFT JOIN items i   ON o.order_id = i.order_id
LEFT JOIN payments pay ON o.order_id = pay.order_id
LEFT JOIN reviews r ON o.order_id = r.order_id;







