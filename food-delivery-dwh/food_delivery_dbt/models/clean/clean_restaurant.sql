{{ config(materialized='table', schema='clean_sch') }}

select * from (
    select
        try_cast(restaurant_id as number)         as restaurant_id,
        try_cast(name as string)                  as name,
        try_cast(cuisine_type as string)          as cuisine_type,
        try_cast(pricing_for_two as number(10,2)) as pricing_for_two,
        try_cast(restaurant_phone as string)      as restaurant_phone,
        try_cast(operating_hours as string)       as operating_hours,
        try_cast(location_id as number)           as location_id_fk,
        try_cast(active_flag as string)           as active_flag,
        try_to_timestamp_ntz(created_date, 'YYYY-MM-DD HH24:MI:SS.FF9') as created_dt,
        try_to_timestamp_ntz(modified_date, 'YYYY-MM-DD HH24:MI:SS.FF9') as modified_dt
    from {{ ref('stg_restaurant') }}
)
qualify row_number() over (partition by restaurant_id order by modified_dt desc nulls last) = 1