-- Question: Grouped by first-purchase month, do customers come back to buy in later months?
-- Scope: cohort = the month of a customer's first order (2017-01 to 2018-08);
--        retention = share of the cohort that placed another order N months after their first purchase;
--        a second order in the same month does not count; canceled orders excluded
--        Note: data ends 2018-08, so later 0.00 values mean "hasn't happened yet", not "nobody returned"
-- Method: multi-layer CTE + MIN for first-purchase month + TIMESTAMPDIFF for month offset + CASE WHEN conditional aggregation
-- Finding: One-month retention is only 0.2%-0.7% across cohorts, staying under 0.5% in most later months,
--          with no sign of improving over time; the Nov 2017 promotional cohort did not retain better than others.
--          Early cohorts have small sample sizes (e.g. 2017-01 has only 762 customers), so their numbers are noisy
--          and shouldn't be over-interpreted.

WITH first_month AS (
    -- Each customer's first-purchase month (based on their full order history; only keep cohorts from 2017-01 to 2018-08)
    SELECT c.customer_unique_id,
           MIN(DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01')) AS cohort_month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status <> 'canceled'
    GROUP BY c.customer_unique_id
    HAVING cohort_month >= '2017-01-01' AND cohort_month < '2018-09-01'
),
activity AS (
    -- For each cohort, how many distinct customers placed an order N months after their first purchase
    SELECT f.cohort_month,
           TIMESTAMPDIFF(MONTH, f.cohort_month,
                         DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01')) AS month_offset,
           COUNT(DISTINCT f.customer_unique_id) AS active_customers
    FROM orders o
    JOIN customers c   ON o.customer_id = c.customer_id
    JOIN first_month f ON c.customer_unique_id = f.customer_unique_id
    WHERE o.order_status <> 'canceled'
      AND o.order_purchase_timestamp < '2018-09-01'
    GROUP BY f.cohort_month, month_offset
)
SELECT cohort_month,
       MAX(CASE WHEN month_offset = 0 THEN active_customers END) AS cohort_size,
       ROUND(COALESCE(MAX(CASE WHEN month_offset = 1 THEN active_customers END), 0) * 100
             / MAX(CASE WHEN month_offset = 0 THEN active_customers END), 2) AS m1_pct,
       ROUND(COALESCE(MAX(CASE WHEN month_offset = 2 THEN active_customers END), 0) * 100
             / MAX(CASE WHEN month_offset = 0 THEN active_customers END), 2) AS m2_pct,
       ROUND(COALESCE(MAX(CASE WHEN month_offset = 3 THEN active_customers END), 0) * 100
             / MAX(CASE WHEN month_offset = 0 THEN active_customers END), 2) AS m3_pct,
       ROUND(COALESCE(MAX(CASE WHEN month_offset = 6 THEN active_customers END), 0) * 100
             / MAX(CASE WHEN month_offset = 0 THEN active_customers END), 2) AS m6_pct
FROM activity
GROUP BY cohort_month
ORDER BY cohort_month;