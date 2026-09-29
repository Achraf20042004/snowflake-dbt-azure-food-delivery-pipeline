use role sysadmin;
use warehouse adhoc_wh;
use database sandbox;
use schema consumption_sch;


truncate table stage_sch.location;
truncate table stage_sch.restaurant;
truncate table stage_sch.customer;


-- LOCATION
copy into stage_sch.location (locationid, city, state, zipcode, activeflag, createddate, modifieddate,
    _stg_file_name, _stg_file_load_ts, _stg_file_md5, _copy_data_ts)
from (select t.$1::text,t.$2::text,t.$3::text,t.$4::text,t.$5::text,t.$6::text,t.$7::text,
    metadata$filename, metadata$file_last_modified, metadata$file_content_key, current_timestamp
    from @stage_sch.azure_stg/01-location-csv/01.01-initial-load/location-5rows.csv t)
file_format = (format_name = 'stage_sch.csv_file_format') on_error = abort_statement;

-- RESTAURANT
copy into stage_sch.restaurant (restaurantid, name, cuisinetype, pricing_for_2, restaurant_phone,
    operatinghours, locationid, activeflag, openstatus, locality, restaurant_address, latitude, longitude,
    createddate, modifieddate, _stg_file_name, _stg_file_load_ts, _stg_file_md5, _copy_data_ts)
from (select t.$1::text,t.$2::text,t.$3::text,t.$4::text,t.$5::text,t.$6::text,t.$7::text,t.$8::text,
    t.$9::text,t.$10::text,t.$11::text,t.$12::text,t.$13::text,t.$14::text,t.$15::text,
    metadata$filename, metadata$file_last_modified, metadata$file_content_key, current_timestamp
    from @stage_sch.azure_stg/02-restaurant-csv/02.01-initial-load/restaurant-delhi+NCR.csv t)
file_format = (format_name = 'stage_sch.csv_file_format') on_error = abort_statement;

-- CUSTOMER
copy into stage_sch.customer (customerid, name, mobile, email, loginbyusing, gender, dob, anniversary,
    preferences, createddate, modifieddate, _stg_file_name, _stg_file_load_ts, _stg_file_md5, _copy_data_ts)
from (select t.$1::text,t.$2::text,t.$3::text,t.$4::text,t.$5::text,t.$6::text,t.$7::text,t.$8::text,
    t.$9::text,t.$10::text,t.$11::text,
    metadata$filename, metadata$file_last_modified, metadata$file_content_key, current_timestamp
    from @stage_sch.azure_stg/03-customer-csv/03.01-initial-load/customers-initial.csv t)
file_format = (format_name = 'stage_sch.csv_file_format') on_error = abort_statement;




truncate table stage_sch.customeraddress;
truncate table stage_sch.menu;
truncate table stage_sch.orders;
truncate table stage_sch.orderitem;
truncate table stage_sch.deliveryagent;
truncate table stage_sch.delivery;


-- CUSTOMER ADDRESS
copy into stage_sch.customeraddress (addressid, customerid, flatno, houseno, floor, building, landmark,
    locality, city, state, pincode, coordinates, primaryflag, addresstype, createddate, modifieddate,
    _stg_file_name, _stg_file_load_ts, _stg_file_md5, _copy_data_ts)
from (select t.$1::text,t.$2::text,t.$3::text,t.$4::text,t.$5::text,t.$6::text,t.$7::text,t.$8::text,
    t.$9::text,t.$10::text,t.$11::text,t.$12::text,t.$13::text,t.$14::text,t.$15::text,t.$16::text,
    metadata$filename, metadata$file_last_modified, metadata$file_content_key, current_timestamp
    from @stage_sch.azure_stg/04-customer-address-csv/04.01-initial-load/customer_address_book_initial.csv t)
file_format = (format_name = 'stage_sch.csv_file_format') on_error = abort_statement;

-- MENU
copy into stage_sch.menu (menuid, restaurantid, itemname, description, price, category, availability,
    itemtype, createddate, modifieddate, _stg_file_name, _stg_file_load_ts, _stg_file_md5, _copy_data_ts)
from (select t.$1::text,t.$2::text,t.$3::text,t.$4::text,t.$5::text,t.$6::text,t.$7::text,t.$8::text,
    t.$9::text,t.$10::text,
    metadata$filename, metadata$file_last_modified, metadata$file_content_key, current_timestamp
    from @stage_sch.azure_stg/06-menu/06.01-initial-load/menu-initial-load.csv t)
file_format = (format_name = 'stage_sch.csv_file_format') on_error = abort_statement;

-- ORDERS
copy into stage_sch.orders (orderid, customerid, restaurantid, orderdate, totalamount, status,
    paymentmethod, createddate, modifieddate, _stg_file_name, _stg_file_load_ts, _stg_file_md5, _copy_data_ts)
from (select t.$1::text,t.$2::text,t.$3::text,t.$4::text,t.$5::text,t.$6::text,t.$7::text,t.$8::text,
    t.$9::text,
    metadata$filename, metadata$file_last_modified, metadata$file_content_key, current_timestamp
    from @stage_sch.azure_stg/07-order-csv/07.01-initial-load/orders-initial.csv t)
file_format = (format_name = 'stage_sch.csv_file_format') on_error = abort_statement;

-- ORDER ITEM
copy into stage_sch.orderitem (orderitemid, orderid, menuid, quantity, price, subtotal,
    createddate, modifieddate, _stg_file_name, _stg_file_load_ts, _stg_file_md5, _copy_data_ts)
from (select t.$1::text,t.$2::text,t.$3::text,t.$4::text,t.$5::text,t.$6::text,t.$7::text,t.$8::text,
    metadata$filename, metadata$file_last_modified, metadata$file_content_key, current_timestamp
    from @stage_sch.azure_stg/08-order-item-csv/08.01-initial-load/order-Item-initial.csv t)
file_format = (format_name = 'stage_sch.csv_file_format') on_error = abort_statement;

-- DELIVERY AGENT
copy into stage_sch.deliveryagent (deliveryagentid, name, phone, vehicletype, locationid, status,
    gender, rating, createddate, modifieddate, _stg_file_name, _stg_file_load_ts, _stg_file_md5, _copy_data_ts)
from (select t.$1::text,t.$2::text,t.$3::text,t.$4::text,t.$5::text,t.$6::text,t.$7::text,t.$8::text,
    t.$9::text,t.$10::text,
    metadata$filename, metadata$file_last_modified, metadata$file_content_key, current_timestamp
    from @stage_sch.azure_stg/09-delivery-agent/09.01-initial-load/delivery-agent-initial.csv t)
file_format = (format_name = 'stage_sch.csv_file_format') on_error = abort_statement;

-- DELIVERY
copy into stage_sch.delivery (deliveryid, orderid, deliveryagentid, deliverystatus, estimatedtime,
    addressid, deliverydate, createddate, modifieddate, _stg_file_name, _stg_file_load_ts, _stg_file_md5, _copy_data_ts)
from (select t.$1::text,t.$2::text,t.$3::text,t.$4::text,t.$5::text,t.$6::text,t.$7::text,t.$8::text,
    t.$9::text,
    metadata$filename, metadata$file_last_modified, metadata$file_content_key, current_timestamp
    from @stage_sch.azure_stg/10-delivery-csv/10.01-initial-load/delivery-initial-load.csv t)
file_format = (format_name = 'stage_sch.csv_file_format') on_error = abort_statement;









create or replace view sandbox.consumption_sch.vw_monthly_revenue_kpis as
SELECT
    d.YEAR AS year,
    d.MONTH AS month,
    SUM(fact.subtotal) AS total_revenue,
    COUNT(DISTINCT fact.order_id) AS total_orders,
    ROUND(SUM(fact.subtotal) / COUNT(DISTINCT fact.order_id), 2) AS avg_revenue_per_order,
    ROUND(SUM(fact.subtotal) / COUNT(fact.order_item_id), 2) AS avg_revenue_per_item,
    MAX(fact.subtotal) AS max_order_value
FROM consumption_sch.fact_order_item fact      -- ← dbt fact table
JOIN consumption_sch.dim_date d
    ON fact.order_date_dim_key = d.date_dim_hk
WHERE fact.delivery_status = 'Delivered'
GROUP BY d.YEAR, d.MONTH
ORDER BY d.YEAR, d.MONTH;



select delivery_status, count(*)
from consumption_sch.fact_order_item
group by delivery_status;