{{ config(materialized='view', schema='stage_sch') }}

select
    menuid       as menu_id,
    restaurantid as restaurant_id,
    itemname     as item_name,
    description  as description,
    price        as price,
    category     as category,
    availability as availability,
    itemtype     as item_type,
    createddate  as created_date,
    modifieddate as modified_date
from {{ source('stage_sch', 'menu') }}