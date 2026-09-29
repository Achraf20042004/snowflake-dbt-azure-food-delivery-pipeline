{{ config(materialized='view', schema='stage_sch') }}

select
    customerid    as customer_id,
    name          as name,
    mobile        as mobile,
    email         as email,
    loginbyusing  as login_by_using,
    gender        as gender,
    dob           as dob,
    anniversary   as anniversary,
    preferences   as preferences,
    createddate   as created_date,
    modifieddate  as modified_date
from {{ source('stage_sch', 'customer') }}