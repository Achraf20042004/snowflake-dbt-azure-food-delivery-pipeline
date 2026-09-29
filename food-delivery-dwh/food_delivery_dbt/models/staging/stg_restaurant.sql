{{ config(materialized='view', schema='stage_sch') }}

select
    restaurantid   as restaurant_id,
    name           as name,
    cuisinetype    as cuisine_type,
    pricing_for_2  as pricing_for_two,
    restaurant_phone,
    operatinghours as operating_hours,
    locationid     as location_id,
    activeflag     as active_flag,
    createddate    as created_date,
    modifieddate   as modified_date
from {{ source('stage_sch', 'restaurant') }}