use role sysadmin;
use warehouse adhoc_wh;
use database sandbox;
use schema consumption_sch;



select count(*) from clean_sch.order_item_stm;
select count(*) from clean_sch.orders_stm;
select count(*) from clean_sch.delivery_stm;








CREATE OR REPLACE TABLE consumption_sch.order_item_fact (
    order_item_fact_sk NUMBER AUTOINCREMENT comment 'Surrogate Key (EDW)', -- Surrogate key for the fact table
    order_item_id NUMBER  comment 'Order Item FK (Source System)',                    -- Natural key from the source data
    order_id NUMBER  comment 'Order FK (Source System)',                         -- Reference to the order dimension
    customer_dim_key NUMBER  comment 'Order FK (Source System)',                      -- Reference to the customer dimension
    customer_address_dim_key NUMBER,                      -- Reference to the customer dimension
    restaurant_dim_key NUMBER,                    -- Reference to the restaurant dimension
    restaurant_location_dim_key NUMBER,                    -- Reference to the restaurant dimension
    menu_dim_key NUMBER,                          -- Reference to the menu dimension
    delivery_agent_dim_key NUMBER,                -- Reference to the delivery agent dimension
    order_date_dim_key NUMBER,                         -- Reference to the date dimension
    quantity NUMBER,                          -- Measure
    price NUMBER(10, 2),                            -- Measure
    subtotal NUMBER(10, 2),                         -- Measure
    delivery_status VARCHAR,                        -- Delivery information
    estimated_time VARCHAR                          -- Delivery information
)
comment = 'The item order fact table that has item level price, quantity and other details';





MERGE INTO consumption_sch.order_item_fact AS target
USING (
    SELECT 
        oi.Order_Item_ID AS order_item_id,
        oi.Order_ID_fk AS order_id,
        c.CUSTOMER_HK AS customer_dim_key,
        ca.CUSTOMER_ADDRESS_HK AS customer_address_dim_key,
        r.RESTAURANT_HK AS restaurant_dim_key, 
        rl.restaurant_location_hk as restaurant_location_dim_key,
        m.Menu_Dim_HK AS menu_dim_key,
        da.DELIVERY_AGENT_HK AS delivery_agent_dim_key,
        dd.DATE_DIM_HK AS order_date_dim_key,
        oi.Quantity::number(2) AS quantity,
        oi.Price AS price,
        oi.Subtotal AS subtotal,
        o.PAYMENT_METHOD,
        d.delivery_status AS delivery_status,
        d.estimated_time AS estimated_time,
        FROM 
            clean_sch.order_item oi
        JOIN clean_sch.orders o    ON oi.Order_ID_fk = o.Order_ID
        JOIN clean_sch.delivery d  ON o.Order_ID = d.Order_ID_fk
        JOIN consumption_sch.customer_dim c 
            ON o.Customer_ID_fk = c.customer_id AND c.is_current = TRUE
        JOIN consumption_sch.customer_address_dim ca 
            ON d.customer_address_id_fk = ca.address_id AND ca.is_current = TRUE
        JOIN consumption_sch.restaurant_dim r 
            ON o.Restaurant_ID_fk = r.restaurant_id AND r.is_current = TRUE
        JOIN consumption_sch.menu_dim m 
            ON oi.Menu_ID_fk = m.menu_id AND m.is_current = TRUE
        JOIN consumption_sch.delivery_agent_dim da 
            ON d.Delivery_Agent_ID_fk = da.delivery_agent_id AND da.is_current = TRUE
        JOIN consumption_sch.restaurant_location_dim rl 
            ON r.Location_ID_fk = rl.location_id AND rl.current_flag = TRUE
        JOIN consumption_sch.date_dim dd 
            ON dd.calendar_date = DATE(o.order_date)
) AS source_stm
ON 
    target.order_item_id = source_stm.order_item_id and 
    target.order_id = source_stm.order_id
WHEN MATCHED THEN
    -- Update existing fact record
    UPDATE SET
        target.customer_dim_key = source_stm.customer_dim_key,
        target.customer_address_dim_key = source_stm.customer_address_dim_key,
        target.restaurant_dim_key = source_stm.restaurant_dim_key,
        target.restaurant_location_dim_key = source_stm.restaurant_location_dim_key,
        target.menu_dim_key = source_stm.menu_dim_key,
        target.delivery_agent_dim_key = source_stm.delivery_agent_dim_key,
        target.order_date_dim_key = source_stm.order_date_dim_key,
        target.quantity = source_stm.quantity,
        target.price = source_stm.price,
        target.subtotal = source_stm.subtotal,
        target.delivery_status = source_stm.delivery_status,
        target.estimated_time = source_stm.estimated_time
WHEN NOT MATCHED THEN
    -- Insert new fact record
    INSERT (
        order_item_id,
        order_id,
        customer_dim_key,
        customer_address_dim_key,
        restaurant_dim_key,
        restaurant_location_dim_key,
        menu_dim_key,
        delivery_agent_dim_key,
        order_date_dim_key,
        quantity,
        price,
        subtotal,
        delivery_status,
        estimated_time
    )
    VALUES (
        source_stm.order_item_id,
        source_stm.order_id,
        source_stm.customer_dim_key,
        source_stm.customer_address_dim_key,
        source_stm.restaurant_dim_key,
        source_stm.restaurant_location_dim_key,
        source_stm.menu_dim_key,
        source_stm.delivery_agent_dim_key,
        source_stm.order_date_dim_key,
        source_stm.quantity,
        source_stm.price,
        source_stm.subtotal,
        source_stm.delivery_status,
        source_stm.estimated_time
    );


-- start with 
alter table consumption_sch.order_item_fact
    add constraint fk_order_item_fact_customer_dim
    foreign key (customer_dim_key)
    references consumption_sch.customer_dim (customer_hk);

alter table consumption_sch.order_item_fact
    add constraint fk_order_item_fact_customer_address_dim
    foreign key (customer_address_dim_key)
    references consumption_sch.customer_address_dim (CUSTOMER_ADDRESS_HK);

alter table consumption_sch.order_item_fact
    add constraint fk_order_item_fact_restaurant_dim
    foreign key (restaurant_dim_key)
    references consumption_sch.restaurant_dim (restaurant_hk);

alter table consumption_sch.order_item_fact
    add constraint fk_order_item_fact_restaurant_location_dim
    foreign key (restaurant_location_dim_key)
    references consumption_sch.restaurant_location_dim (restaurant_location_hk);

alter table consumption_sch.order_item_fact
    add constraint fk_order_item_fact_menu_dim
    foreign key (menu_dim_key)
    references consumption_sch.menu_dim (menu_dim_hk);

alter table consumption_sch.order_item_fact
    add constraint fk_order_item_fact_delivery_agent_dim
    foreign key (delivery_agent_dim_key)
    references consumption_sch.delivery_agent_dim (delivery_agent_hk);

alter table consumption_sch.order_item_fact
    add constraint fk_order_item_fact_delivery_date_dim
    foreign key (order_date_dim_key)
    references consumption_sch.date_dim (date_dim_hk);


































select count(*) from stage_sch.orders;

list @stage_sch.csv_stg/initial/orders/;

