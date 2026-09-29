{{ config(materialized='table', schema='clean_sch') }}

select * from (
    select
        try_cast(delivery_agent_id as number) as delivery_agent_id,
        try_cast(name as string)              as name,
        try_cast(phone as string)             as phone,
        try_cast(vehicle_type as string)      as vehicle_type,
        try_cast(location_id as number)       as location_id_fk,
        try_cast(status as string)            as status,
        try_cast(gender as string)            as gender,
        try_cast(rating as number(3,2))       as rating,
        try_to_timestamp_ntz(created_date, 'YYYY-MM-DD HH24:MI:SS.FF9')  as created_dt,
        try_to_timestamp_ntz(modified_date, 'YYYY-MM-DD HH24:MI:SS.FF9') as modified_dt
    from {{ ref('stg_deliveryagent') }}
)
qualify row_number() over (
    partition by delivery_agent_id
    order by modified_dt desc nulls last, rating desc
) = 1