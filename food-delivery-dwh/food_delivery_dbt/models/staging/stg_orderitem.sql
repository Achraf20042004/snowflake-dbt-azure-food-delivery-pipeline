{{ config(materialized='view', schema='stage_sch') }}

select
    orderitemid  as order_item_id,
    orderid      as order_id,
    menuid       as menu_id,
    quantity     as quantity,
    price        as price,
    subtotal     as subtotal,
    createddate  as created_date,
    modifieddate as modified_date
from {{ source('stage_sch', 'orderitem') }}