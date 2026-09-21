-- Question: Does delivery delay affect customer review scores?
-- Scope: Only orders with status 'delivered' and at least one review (95,823 orders);
--        delay_days = actual delivery date - estimated delivery date;
--        orders with multiple reviews are averaged first to avoid double-counting after the JOIN;
--        low score = review score of 1 or 2
-- Method: CTE + DATEDIFF + CASE WHEN bucketing + conditional aggregation
-- Finding: On-time or early orders (93.3% of the total) average 4.29 with a 9.2% low-score rate;
--          1-3 days late drops to 3.29 (32.2%); 4-7 days late drops to 2.11 (67.6%);
--          more than 7 days late drops to just 1.70 (79.2%).
--          Delay is strongly correlated with low scores; customer tolerance appears to be around 3 days.
--          This may be one driver of low retention, but correlation here does not prove causation.

WITH review_by_order AS (
    -- Some orders have multiple reviews; average per order first to avoid duplication after the JOIN
    SELECT order_id, AVG(review_score) AS score
    FROM order_reviews
    GROUP BY order_id
),
delivered AS (
    SELECT o.order_id,
           DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) AS delay_days,
           r.score
    FROM orders o
    JOIN review_by_order r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
)
SELECT CASE
           WHEN delay_days <= 0 THEN '1. On time or early'
           WHEN delay_days <= 3 THEN '2. 1-3 days late'
           WHEN delay_days <= 7 THEN '3. 4-7 days late'
           ELSE                      '4. More than 7 days late'
       END                                        AS delivery_group,
       COUNT(*)                                   AS orders,
       ROUND(AVG(score), 2)                       AS avg_score,
       ROUND(SUM(score <= 2) * 100 / COUNT(*), 1) AS low_score_pct
FROM delivered
GROUP BY delivery_group
ORDER BY delivery_group;