-- Question: Do customers come back to buy again?
-- Scope: customer_unique_id identifies a unique person (customer_id is regenerated for every
--        order, so using it directly would give a false 0% repeat rate); canceled orders excluded;
--        repeat = placed 2 or more orders
-- Method: CTE + GROUP BY + conditional aggregation
-- Finding: Of 95,560 customers, only 2,924 repeated — a 3.06% repeat purchase rate;
--          97% of customers bought exactly once, and most repeat customers bought only twice;
--          combined with the rapid growth in order volume, growth is driven mainly by new customer acquisition.

WITH cust AS (
    SELECT c.customer_unique_id,
           COUNT(DISTINCT o.order_id) AS n_orders
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status <> 'canceled'
    GROUP BY c.customer_unique_id
)
SELECT COUNT(*)                                         AS customers,
       SUM(n_orders > 1)                                AS repeat_customers,
       ROUND(SUM(n_orders > 1) / COUNT(*) * 100, 2)     AS repeat_rate_pct
FROM cust;

-- Distribution of number of orders placed per customer
WITH cust AS (
    SELECT c.customer_unique_id,
           COUNT(DISTINCT o.order_id) AS n_orders
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status <> 'canceled'
    GROUP BY c.customer_unique_id
)
SELECT CASE
           WHEN n_orders = 1 THEN '1 order'
           WHEN n_orders = 2 THEN '2 orders'
           WHEN n_orders = 3 THEN '3 orders'
           ELSE                   '4+ orders'
       END                                          AS order_count_group,
       COUNT(*)                                     AS customers,
       ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER (), 2) AS pct_of_customers
FROM cust
GROUP BY order_count_group
ORDER BY MIN(n_orders);