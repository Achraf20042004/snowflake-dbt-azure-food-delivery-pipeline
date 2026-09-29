{{ config(materialized='view', schema='stage_sch') }}

select
    addressid    as address_id,
    customerid   as customer_id,
    flatno       as flat_no,
    houseno      as house_no,
    floor        as floor,
    building     as building,
    landmark     as landmark,
    locality     as locality,
    city         as city,
    state        as state,
    pincode      as pincode,
    coordinates  as coordinates,
    primaryflag  as primary_flag,
    addresstype  as address_type,
    createddate  as created_date,
    modifieddate as modified_date
from {{ source('stage_sch', 'customeraddress') }}