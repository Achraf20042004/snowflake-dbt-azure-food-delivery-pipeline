{{ config(materialized='view', schema='stage_sch') }}

select
    orderid       as order_id,
    customerid    as customer_id,
    restaurantid  as restaurant_id,
    orderdate     as order_date,
    totalamount   as total_amount,
    status        as status,
    paymentmethod as payment_method,
    createddate   as created_date,
    modifieddate  as modified_date
from {{ source('stage_sch', 'orders') }}