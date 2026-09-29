{{ config(materialized='table', schema='clean_sch') }}

select
    try_cast(delivery_id as number)       as delivery_id,
    try_cast(order_id as number)          as order_id_fk,
    try_cast(delivery_agent_id as number) as delivery_agent_id_fk,
    try_cast(delivery_status as string)   as delivery_status,
    try_cast(estimated_time as string)    as estimated_time,
    try_cast(address_id as number)        as customer_address_id_fk,
    try_to_timestamp_ntz(delivery_date, 'YYYY-MM-DD HH24:MI:SS.FF9')  as delivery_dt,
    try_to_timestamp_ntz(created_date, 'YYYY-MM-DD HH24:MI:SS.FF9')   as created_dt,
    try_to_timestamp_ntz(modified_date, 'YYYY-MM-DD HH24:MI:SS.FF9')  as modified_dt
from {{ ref('stg_delivery') }}