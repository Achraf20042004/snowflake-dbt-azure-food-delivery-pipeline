{{ config(materialized='view', schema='stage_sch') }}

select
    deliveryagentid as delivery_agent_id,
    name            as name,
    phone           as phone,
    vehicletype     as vehicle_type,
    locationid      as location_id,
    status          as status,
    gender          as gender,
    rating          as rating,
    createddate     as created_date,
    modifieddate    as modified_date
from {{ source('stage_sch', 'deliveryagent') }}