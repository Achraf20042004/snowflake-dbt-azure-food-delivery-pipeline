{{ config(materialized='table', schema='clean_sch') }}

select * from (
    select
        try_cast(customer_id as number)   as customer_id,
        try_cast(name as string)          as name,
        try_cast(mobile as string)        as mobile,
        try_cast(email as string)         as email,
        try_cast(login_by_using as string) as login_by_using,
        try_cast(gender as string)        as gender,
        try_cast(dob as date)             as dob,
        try_cast(anniversary as date)     as anniversary,
        try_cast(preferences as string)   as preferences,
        try_to_timestamp_ntz(created_date, 'YYYY-MM-DD HH24:MI:SS.FF9')  as created_dt,
        try_to_timestamp_ntz(modified_date, 'YYYY-MM-DD HH24:MI:SS.FF9') as modified_dt
    from {{ ref('stg_customer') }}
)
qualify row_number() over (partition by customer_id order by modified_dt desc nulls last) = 1