{{ config(materialized='table', schema='clean_sch') }}

select
    try_cast(address_id as number)   as address_id,
    try_cast(customer_id as number)  as customer_id_fk,
    try_cast(flat_no as string)      as flat_no,
    try_cast(house_no as string)     as house_no,
    try_cast(floor as string)        as floor,
    try_cast(building as string)     as building,
    try_cast(landmark as string)     as landmark,
    try_cast(locality as string)     as locality,
    try_cast(city as string)         as city,
    try_cast(state as string)        as state,
    try_cast(pincode as string)      as pincode,
    try_cast(coordinates as string)  as coordinates,
    try_cast(primary_flag as string) as primary_flag,
    try_cast(address_type as string) as address_type,
    try_to_timestamp_ntz(created_date, 'YYYY-MM-DD HH24:MI:SS.FF9')  as created_dt,
    try_to_timestamp_ntz(modified_date, 'YYYY-MM-DD HH24:MI:SS.FF9') as modified_dt
from {{ ref('stg_customeraddress') }}