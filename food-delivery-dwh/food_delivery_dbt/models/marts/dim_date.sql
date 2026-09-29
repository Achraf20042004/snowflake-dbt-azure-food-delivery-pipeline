{{ config(materialized='table', schema='consumption_sch') }}

with recursive date_cte as (
    select current_date() as calendar_date
    union all
    select dateadd('day', -1, calendar_date)
    from date_cte
    where calendar_date > (select date(min(order_date)) from {{ ref('clean_orders') }})
)

select
    hash(sha1_hex(calendar_date::string)) as date_dim_hk,
    calendar_date,
    year(calendar_date)       as year,
    quarter(calendar_date)    as quarter,
    month(calendar_date)      as month,
    week(calendar_date)       as week,
    dayofyear(calendar_date)  as day_of_year,
    dayofweek(calendar_date)  as day_of_week,
    day(calendar_date)        as day_of_the_month,
    dayname(calendar_date)    as day_name
from date_cte