{{ config(materialized='view', schema='consumption_sch') }}

SELECT
    d.YEAR AS year,
    d.MONTH AS month,
    SUM(fact.subtotal) AS total_revenue,
    COUNT(DISTINCT fact.order_id) AS total_orders,
    ROUND(SUM(fact.subtotal) / COUNT(DISTINCT fact.order_id), 2) AS avg_revenue_per_order,
    ROUND(SUM(fact.subtotal) / COUNT(fact.order_item_id), 2) AS avg_revenue_per_item,
    MAX(fact.subtotal) AS max_order_value
FROM {{ ref('fact_order_item') }} fact
JOIN {{ ref('dim_date') }} d
    ON fact.order_date_dim_key = d.date_dim_hk
GROUP BY d.YEAR, d.MONTH