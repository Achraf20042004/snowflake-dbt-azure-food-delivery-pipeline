{{ config(materialized='view', schema='consumption_sch') }}

SELECT
    d.YEAR AS year,
    d.MONTH AS month,
    fact.DELIVERY_STATUS,
    r.name as restaurant_name,
    SUM(fact.subtotal) AS total_revenue,
    COUNT(DISTINCT fact.order_id) AS total_orders,
    ROUND(SUM(fact.subtotal) / COUNT(DISTINCT fact.order_id), 2) AS avg_revenue_per_order,
    ROUND(SUM(fact.subtotal) / COUNT(fact.order_item_id), 2) AS avg_revenue_per_item,
    MAX(fact.subtotal) AS max_order_value
FROM {{ ref('fact_order_item') }} fact
JOIN {{ ref('dim_date') }} d
    ON fact.order_date_dim_key = d.date_dim_hk
JOIN {{ ref('snap_restaurant') }} r
    ON fact.restaurant_dim_key = r.dbt_scd_id
GROUP BY d.YEAR, d.MONTH, fact.DELIVERY_STATUS, restaurant_name