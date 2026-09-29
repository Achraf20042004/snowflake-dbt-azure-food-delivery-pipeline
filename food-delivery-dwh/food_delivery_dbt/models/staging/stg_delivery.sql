{{ config(materialized='view', schema='stage_sch') }}

select
    deliveryid      as delivery_id,
    orderid         as order_id,
    deliveryagentid as delivery_agent_id,
    deliverystatus  as delivery_status,
    estimatedtime   as estimated_time,
    addressid       as address_id,
    deliverydate    as delivery_date,
    createddate     as created_date,
    modifieddate    as modified_date
from {{ source('stage_sch', 'delivery') }}