-- Question: How has the platform's sales scale changed over time? Is growth driven by order volume or order value?
-- Scope: GMV = sum of item price (freight not included); canceled orders excluded;
--        only complete months from 2017-01 to 2018-08 are included (the first/last months
--        have incomplete data, which would distort month-over-month figures)
-- Method: CTE + multi-table JOIN + window function LAG (month-over-month change)
-- Finding: Monthly orders grew from 787 to 6,421 (~8x), GMV grew from R$120K to R$849K (~7x),
--          average order value stayed flat at R$125-155 — growth is almost entirely from order volume;
--          GMV first crossed R$1M in 2017-11 (+52.1% MoM), likely tied to a seasonal promotion;
--          growth largely plateaued from 2018 onward.

USE olist;

WITH monthly AS (
    SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS ym,
           COUNT(DISTINCT o.order_id)                       AS orders,
           ROUND(SUM(oi.price), 2)                          AS gmv
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status <> 'canceled'
          AND o.order_purchase_timestamp >= '2017-01-01' AND o.order_purchase_timestamp < '2018-09-01'
    GROUP BY ym
)
SELECT ym,
       orders,
       gmv,
       ROUND(gmv / orders, 2) AS avg_order_value,
       ROUND((gmv - LAG(gmv) OVER (ORDER BY ym)) / LAG(gmv) OVER (ORDER BY ym) * 100, 1) AS gmv_mom_pct
FROM monthly
ORDER BY ym;