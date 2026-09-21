-- Question: Which product categories generate the most revenue?
-- Scope: GMV = sum of item price (freight not included); canceled orders excluded;
--        category name uses the English translation table, falling back to the
--        original Portuguese name or 'unknown' when missing;
--        orders is counted per category, so a multi-category order is counted more than once
-- Method: JOIN + LEFT JOIN translation table + RANK + SUM() OVER (share and cumulative share)
-- Finding: Revenue is fairly spread out — the top 10 categories account for about 62% of GMV,
--          the largest single category (health_beauty) is only 9.3%.
--          Order count and GMV rank don't always match: watches_gifts ranks #2 in GMV with
--          fewer orders than several categories below it, driven by a much higher average order value.

WITH cat AS (
    SELECT COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
           COUNT(DISTINCT oi.order_id) AS orders,
           ROUND(SUM(oi.price), 2)     AS gmv
    FROM order_items oi
    JOIN orders o   ON oi.order_id = o.order_id
    JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN category_translation t ON p.product_category_name = t.product_category_name
    WHERE o.order_status <> 'canceled'
    GROUP BY category
)
SELECT RANK() OVER (ORDER BY gmv DESC)                                   AS gmv_rank,
       category,
       orders,
       gmv,
       ROUND(gmv / orders, 2)                                            AS avg_order_value,
       ROUND(gmv * 100 / SUM(gmv) OVER (), 2)                            AS gmv_share_pct,
       ROUND(SUM(gmv) OVER (ORDER BY gmv DESC
                            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
             * 100 / SUM(gmv) OVER (), 2)                                AS cumulative_share_pct
FROM cat
ORDER BY gmv_rank
LIMIT 10;