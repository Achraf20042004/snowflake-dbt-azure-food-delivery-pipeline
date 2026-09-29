{{ config(materialized='table', schema='consumption_sch') }}

select
    oi.order_item_id,
    oi.order_id_fk                    as order_id,
    c.dbt_scd_id                      as customer_dim_key,
    ca.dbt_scd_id                     as customer_address_dim_key,
    r.dbt_scd_id                      as restaurant_dim_key,
    l.dbt_scd_id                      as restaurant_location_dim_key,
    m.dbt_scd_id                      as menu_dim_key,
    da.dbt_scd_id                     as delivery_agent_dim_key,
    dd.date_dim_hk                    as order_date_dim_key,
    oi.quantity,
    oi.price,
    oi.subtotal,
    d.delivery_status,
    d.estimated_time
from {{ ref('clean_orderitem') }} oi
join {{ ref('clean_orders') }} o        on oi.order_id_fk = o.order_id
join {{ ref('clean_delivery') }} d      on o.order_id = d.order_id_fk
join {{ ref('snap_customer') }} c       on o.customer_id_fk = c.customer_id and c.dbt_valid_to is null
join {{ ref('snap_customeraddress') }} ca on d.customer_address_id_fk = ca.address_id and ca.dbt_valid_to is null
join {{ ref('snap_restaurant') }} r     on o.restaurant_id_fk = r.restaurant_id and r.dbt_valid_to is null
join {{ ref('snap_menu') }} m           on oi.menu_id_fk = m.menu_id and m.dbt_valid_to is null
join {{ ref('snap_deliveryagent') }} da on d.delivery_agent_id_fk = da.delivery_agent_id and da.dbt_valid_to is null
join {{ ref('snap_location') }} l       on r.location_id_fk = l.location_id and l.dbt_valid_to is null
join {{ ref('dim_date') }} dd           on dd.calendar_date = date(o.order_date)