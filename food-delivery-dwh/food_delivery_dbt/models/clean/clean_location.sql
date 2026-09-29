{{ config(materialized='table', schema='clean_sch') }}

select * from (
    select
        try_cast(location_id as number)  as location_id,
        try_cast(city as string)         as city,
        try_cast(state as string)        as state,
        try_cast(zip_code as string)     as zip_code,
        try_cast(active_flag as string)  as active_flag,
        try_to_timestamp_ntz(created_date, 'YYYY-MM-DD HH24:MI:SS.FF9')  as created_dt,
        try_to_timestamp_ntz(modified_date, 'YYYY-MM-DD HH24:MI:SS.FF9') as modified_dt
    from {{ ref('stg_location') }}
    where try_cast(location_id as number) is not null   -- drop the null/header rows
)
qualify row_number() over (partition by location_id order by modified_dt desc nulls last) = 1