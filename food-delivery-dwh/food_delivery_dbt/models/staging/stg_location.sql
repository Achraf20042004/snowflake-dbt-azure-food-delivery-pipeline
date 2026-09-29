{{ config(materialized='view', schema='stage_sch') }}

select
    locationid   as location_id,
    city         as city,
    state        as state,
    zipcode      as zip_code,
    activeflag   as active_flag,
    createddate  as created_date,
    modifieddate as modified_date
from {{ source('stage_sch', 'location') }}