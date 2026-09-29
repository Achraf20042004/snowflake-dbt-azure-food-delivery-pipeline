{{ config(materialized='table', schema='clean_sch') }}

select
    try_cast(order_id as number)       as order_id,
    try_cast(customer_id as number)    as customer_id_fk,
    try_cast(restaurant_id as number)  as restaurant_id_fk,
    try_to_timestamp_ntz(order_date, 'YYYY-MM-DD HH24:MI:SS.FF9') as order_date,
    try_cast(total_amount as number(10,2)) as total_amount,
    try_cast(status as string)         as status,
    try_cast(payment_method as string) as payment_method,
    try_to_timestamp_ntz(created_date, 'YYYY-MM-DD HH24:MI:SS.FF9')  as created_dt,
    try_to_timestamp_ntz(modified_date, 'YYYY-MM-DD HH24:MI:SS.FF9') as modified_dt
from {{ ref('stg_orders') }}