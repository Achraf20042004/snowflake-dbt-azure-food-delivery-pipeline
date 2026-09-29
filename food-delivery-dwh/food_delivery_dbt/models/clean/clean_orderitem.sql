{{ config(materialized='table', schema='clean_sch') }}

select
    try_cast(order_item_id as number) as order_item_id,
    try_cast(order_id as number)      as order_id_fk,
    try_cast(menu_id as number)       as menu_id_fk,
    try_cast(quantity as number)      as quantity,
    try_cast(price as number(10,2))   as price,
    try_cast(subtotal as number(10,2)) as subtotal,
    try_to_timestamp_ntz(created_date, 'YYYY-MM-DD HH24:MI:SS.FF9')  as created_dt,
    try_to_timestamp_ntz(modified_date, 'YYYY-MM-DD HH24:MI:SS.FF9') as modified_dt
from {{ ref('stg_orderitem') }}