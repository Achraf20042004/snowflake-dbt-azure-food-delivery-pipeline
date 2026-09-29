{{ config(materialized='table', schema='clean_sch') }}

select
    try_cast(menu_id as number)       as menu_id,
    try_cast(restaurant_id as number) as restaurant_id_fk,
    try_cast(item_name as string)     as item_name,
    try_cast(description as string)   as description,
    try_cast(price as number(10,2))   as price,
    try_cast(category as string)      as category,
    try_cast(availability as string)  as availability,
    try_cast(item_type as string)     as item_type,
    try_to_timestamp_ntz(created_date, 'YYYY-MM-DD HH24:MI:SS.FF9')  as created_dt,
    try_to_timestamp_ntz(modified_date, 'YYYY-MM-DD HH24:MI:SS.FF9') as modified_dt
from {{ ref('stg_menu') }}