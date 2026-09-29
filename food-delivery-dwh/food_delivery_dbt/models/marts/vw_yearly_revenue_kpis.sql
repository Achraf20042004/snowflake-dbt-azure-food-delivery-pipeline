{{ config(materialized='view', schema='consumption_sch') }}

select
    d.year as year,
    sum(fact.subtotal) as total_revenue,
    count(distinct fact.order_id) as total_orders,
    round(sum(fact.subtotal) / count(distinct fact.order_id), 2) as avg_revenue_per_order,
    round(sum(fact.subtotal) / count(fact.order_item_id), 2) as avg_revenue_per_item,
    max(fact.subtotal) as max_order_value
from {{ ref('fact_order_item') }} fact
join {{ ref('dim_date') }} d
    on fact.order_date_dim_key = d.date_dim_hk
group by d.year