-- =====================================================================
-- RESTAURANT PIPELINE  (stage -> clean -> dim)  — corrected order
-- Run top to bottom. Each MERGE follows the object it depends on.
-- =====================================================================

use role sysadmin;
use database sandbox;
use schema stage_sch;
use warehouse adhoc_wh;

-- =====================================================================
-- OPTIONAL RESET (run once if you executed an older version before)
-- =====================================================================
drop table if exists stage_sch.restaurant;
drop table if exists clean_sch.restaurant;
drop table if exists consumption_sch.restaurant_dim;

-- =====================================================================
-- 1. STAGE TABLE + STREAM
-- =====================================================================
create or replace table stage_sch.restaurant (
    restaurantid text,
    name text,
    cuisinetype text,
    pricing_for_2 text,
    restaurant_phone text WITH TAG (common.pii_policy_tag = 'SENSITIVE'),
    operatinghours text,
    locationid text,
    activeflag text,
    openstatus text,
    locality text,
    restaurant_address text,
    latitude text,
    longitude text,
    createddate text,
    modifieddate text,
    _stg_file_name text,
    _stg_file_load_ts timestamp,
    _stg_file_md5 text,
    _copy_data_ts timestamp default current_timestamp
)
comment = 'Restaurant stage/raw table. As-is data from source, all text except audit columns.';

create or replace stream stage_sch.restaurant_stm
on table stage_sch.restaurant
append_only = true
comment = 'Append-only stream on stage restaurant table (delta only).';

-- =====================================================================
-- 2. INITIAL COPY  ->  STAGE
-- =====================================================================
copy into stage_sch.restaurant (restaurantid, name, cuisinetype, pricing_for_2, restaurant_phone,
                      operatinghours, locationid, activeflag, openstatus,
                      locality, restaurant_address, latitude, longitude,
                      createddate, modifieddate,
                      _stg_file_name, _stg_file_load_ts, _stg_file_md5, _copy_data_ts)
from (
    select
        t.$1::text, t.$2::text, t.$3::text, t.$4::text, t.$5::text,
        t.$6::text, t.$7::text, t.$8::text, t.$9::text, t.$10::text,
        t.$11::text, t.$12::text, t.$13::text, t.$14::text, t.$15::text,
        metadata$filename,
        metadata$file_last_modified,
        metadata$file_content_key,
        current_timestamp()
     from @stage_sch.csv_stg/initial/restaurant/restaurant-delhi+NCR.csv t
)
file_format = (format_name = 'stage_sch.csv_file_format')
on_error = abort_statement;

-- =====================================================================
-- 3. CLEAN TABLE + STREAM
-- =====================================================================
create or replace table clean_sch.restaurant (
    restaurant_sk number autoincrement primary key,
    restaurant_id number unique,
    name string(100) not null,
    cuisine_type string,
    pricing_for_two number(10, 2),
    restaurant_phone string(15) WITH TAG (common.pii_policy_tag = 'SENSITIVE'),
    operating_hours string(100),
    location_id_fk number,
    active_flag string(10),
    open_status string(10),
    locality string(100),
    restaurant_address string,
    latitude number(9, 6),
    longitude number(9, 6),
    created_dt timestamp_tz,
    modified_dt timestamp_tz,
    _stg_file_name string,
    _stg_file_load_ts timestamp_ntz,
    _stg_file_md5 string,
    _copy_data_ts timestamp_ntz default current_timestamp
)
comment = 'Restaurant clean entity with proper data types. Populated via MERGE from stage. No SCD2.';

create or replace stream clean_sch.restaurant_stm
on table clean_sch.restaurant
comment = 'Standard stream on clean restaurant table (insert/update/delete).';

-- =====================================================================
-- 4. MERGE  STAGE stream -> CLEAN   (initial load)
-- =====================================================================
MERGE INTO clean_sch.restaurant AS target
USING (
    SELECT
        try_cast(restaurantid AS number) AS restaurant_id,
        try_cast(name AS string) AS name,
        try_cast(cuisinetype AS string) AS cuisine_type,
        try_cast(pricing_for_2 AS number(10, 2)) AS pricing_for_two,
        try_cast(restaurant_phone AS string) AS restaurant_phone,
        try_cast(operatinghours AS string) AS operating_hours,
        try_cast(locationid AS number) AS location_id_fk,
        try_cast(activeflag AS string) AS active_flag,
        try_cast(openstatus AS string) AS open_status,
        try_cast(locality AS string) AS locality,
        try_cast(restaurant_address AS string) AS restaurant_address,
        try_cast(latitude AS number(9, 6)) AS latitude,
        try_cast(longitude AS number(9, 6)) AS longitude,
        try_to_timestamp_ntz(createddate, 'YYYY-MM-DD HH24:MI:SS.FF9') AS created_dt,
        try_to_timestamp_ntz(modifieddate, 'YYYY-MM-DD HH24:MI:SS.FF9') AS modified_dt,
        _stg_file_name, _stg_file_load_ts, _stg_file_md5
    FROM stage_sch.restaurant_stm
) AS source
ON target.restaurant_id = source.restaurant_id
WHEN MATCHED THEN
    UPDATE SET
        target.name = source.name,
        target.cuisine_type = source.cuisine_type,
        target.pricing_for_two = source.pricing_for_two,
        target.restaurant_phone = source.restaurant_phone,
        target.operating_hours = source.operating_hours,
        target.location_id_fk = source.location_id_fk,
        target.active_flag = source.active_flag,
        target.open_status = source.open_status,
        target.locality = source.locality,
        target.restaurant_address = source.restaurant_address,
        target.latitude = source.latitude,
        target.longitude = source.longitude,
        target.created_dt = source.created_dt,
        target.modified_dt = source.modified_dt,
        target._stg_file_name = source._stg_file_name,
        target._stg_file_load_ts = source._stg_file_load_ts,
        target._stg_file_md5 = source._stg_file_md5
WHEN NOT MATCHED THEN
    INSERT (restaurant_id, name, cuisine_type, pricing_for_two, restaurant_phone,
        operating_hours, location_id_fk, active_flag, open_status, locality,
        restaurant_address, latitude, longitude, created_dt, modified_dt,
        _stg_file_name, _stg_file_load_ts, _stg_file_md5)
    VALUES (source.restaurant_id, source.name, source.cuisine_type, source.pricing_for_two,
        source.restaurant_phone, source.operating_hours, source.location_id_fk,
        source.active_flag, source.open_status, source.locality, source.restaurant_address,
        source.latitude, source.longitude, source.created_dt, source.modified_dt,
        source._stg_file_name, source._stg_file_load_ts, source._stg_file_md5);

-- =====================================================================
-- 5. DIM TABLE (SCD2)
-- =====================================================================
CREATE OR REPLACE TABLE CONSUMPTION_SCH.RESTAURANT_DIM (
    RESTAURANT_HK NUMBER primary key,
    RESTAURANT_ID NUMBER,
    NAME STRING(100),
    CUISINE_TYPE STRING,
    PRICING_FOR_TWO NUMBER(10, 2),
    RESTAURANT_PHONE STRING(15) WITH TAG (common.pii_policy_tag = 'SENSITIVE'),
    OPERATING_HOURS STRING(100),
    LOCATION_ID_FK NUMBER,
    ACTIVE_FLAG STRING(10),
    OPEN_STATUS STRING(10),
    LOCALITY STRING(100),
    RESTAURANT_ADDRESS STRING,
    LATITUDE NUMBER(9, 6),
    LONGITUDE NUMBER(9, 6),
    EFF_START_DATE TIMESTAMP_TZ,
    EFF_END_DATE TIMESTAMP_TZ,
    IS_CURRENT BOOLEAN
)
COMMENT = 'Dimensional table for Restaurant with hash key surrogate key and SCD2 enabled.';

-- =====================================================================
-- 6. MERGE  CLEAN stream -> DIM   (initial load)
-- =====================================================================
MERGE INTO CONSUMPTION_SCH.RESTAURANT_DIM AS target
USING CLEAN_SCH.RESTAURANT_STM AS source
ON  target.RESTAURANT_ID = source.RESTAURANT_ID AND
    target.NAME = source.NAME AND
    target.CUISINE_TYPE = source.CUISINE_TYPE AND
    target.PRICING_FOR_TWO = source.PRICING_FOR_TWO AND
    target.RESTAURANT_PHONE = source.RESTAURANT_PHONE AND
    target.OPERATING_HOURS = source.OPERATING_HOURS AND
    target.LOCATION_ID_FK = source.LOCATION_ID_FK AND
    target.ACTIVE_FLAG = source.ACTIVE_FLAG AND
    target.OPEN_STATUS = source.OPEN_STATUS AND
    target.LOCALITY = source.LOCALITY AND
    target.RESTAURANT_ADDRESS = source.RESTAURANT_ADDRESS AND
    target.LATITUDE = source.LATITUDE AND
    target.LONGITUDE = source.LONGITUDE AND
    target.IS_CURRENT = TRUE
WHEN MATCHED
    AND source.METADATA$ACTION = 'DELETE' AND source.METADATA$ISUPDATE = 'TRUE' THEN
    UPDATE SET
        target.EFF_END_DATE = CURRENT_TIMESTAMP(),
        target.IS_CURRENT = FALSE
WHEN NOT MATCHED
    AND source.METADATA$ACTION = 'INSERT' AND source.METADATA$ISUPDATE = 'TRUE' THEN
    INSERT (RESTAURANT_HK, RESTAURANT_ID, NAME, CUISINE_TYPE, PRICING_FOR_TWO,
        RESTAURANT_PHONE, OPERATING_HOURS, LOCATION_ID_FK, ACTIVE_FLAG, OPEN_STATUS,
        LOCALITY, RESTAURANT_ADDRESS, LATITUDE, LONGITUDE,
        EFF_START_DATE, EFF_END_DATE, IS_CURRENT)
    VALUES (
        hash(SHA1_hex(CONCAT(source.RESTAURANT_ID, source.NAME, source.CUISINE_TYPE,
            source.PRICING_FOR_TWO, source.RESTAURANT_PHONE, source.OPERATING_HOURS,
            source.LOCATION_ID_FK, source.ACTIVE_FLAG, source.OPEN_STATUS, source.LOCALITY,
            source.RESTAURANT_ADDRESS, source.LATITUDE, source.LONGITUDE))),
        source.RESTAURANT_ID, source.NAME, source.CUISINE_TYPE, source.PRICING_FOR_TWO,
        source.RESTAURANT_PHONE, source.OPERATING_HOURS, source.LOCATION_ID_FK,
        source.ACTIVE_FLAG, source.OPEN_STATUS, source.LOCALITY, source.RESTAURANT_ADDRESS,
        source.LATITUDE, source.LONGITUDE, CURRENT_TIMESTAMP(), NULL, TRUE)
WHEN NOT MATCHED
    AND source.METADATA$ACTION = 'INSERT' AND source.METADATA$ISUPDATE = 'FALSE' THEN
    INSERT (RESTAURANT_HK, RESTAURANT_ID, NAME, CUISINE_TYPE, PRICING_FOR_TWO,
        RESTAURANT_PHONE, OPERATING_HOURS, LOCATION_ID_FK, ACTIVE_FLAG, OPEN_STATUS,
        LOCALITY, RESTAURANT_ADDRESS, LATITUDE, LONGITUDE,
        EFF_START_DATE, EFF_END_DATE, IS_CURRENT)
    VALUES (
        hash(SHA1_hex(CONCAT(source.RESTAURANT_ID, source.NAME, source.CUISINE_TYPE,
            source.PRICING_FOR_TWO, source.RESTAURANT_PHONE, source.OPERATING_HOURS,
            source.LOCATION_ID_FK, source.ACTIVE_FLAG, source.OPEN_STATUS, source.LOCALITY,
            source.RESTAURANT_ADDRESS, source.LATITUDE, source.LONGITUDE))),
        source.RESTAURANT_ID, source.NAME, source.CUISINE_TYPE, source.PRICING_FOR_TWO,
        source.RESTAURANT_PHONE, source.OPERATING_HOURS, source.LOCATION_ID_FK,
        source.ACTIVE_FLAG, source.OPEN_STATUS, source.LOCALITY, source.RESTAURANT_ADDRESS,
        source.LATITUDE, source.LONGITUDE, CURRENT_TIMESTAMP(), NULL, TRUE);


-- =====================================================================
-- ==========  DELTA DAY 01  ===========================================
-- =====================================================================
list @stage_sch.csv_stg/delta/restaurant/;

-- 7a. COPY delta 01 -> STAGE
copy into stage_sch.restaurant (restaurantid, name, cuisinetype, pricing_for_2, restaurant_phone,
                      operatinghours, locationid, activeflag, openstatus,
                      locality, restaurant_address, latitude, longitude,
                      createddate, modifieddate,
                      _stg_file_name, _stg_file_load_ts, _stg_file_md5, _copy_data_ts)
from (
    select
        t.$1::text, t.$2::text, t.$3::text, t.$4::text, t.$5::text,
        t.$6::text, t.$7::text, t.$8::text, t.$9::text, t.$10::text,
        t.$11::text, t.$12::text, t.$13::text, t.$14::text, t.$15::text,
        metadata$filename, metadata$file_last_modified, metadata$file_content_key,
        current_timestamp()
     from @stage_sch.csv_stg/delta/restaurant/day-01-insert-restaurant-delhi+NCR.csv t
)
file_format = (format_name = 'stage_sch.csv_file_format')
on_error = abort_statement;

-- 7b. MERGE stage -> clean  (delta 01)
MERGE INTO clean_sch.restaurant AS target
USING (
    SELECT
        try_cast(restaurantid AS number) AS restaurant_id,
        try_cast(name AS string) AS name,
        try_cast(cuisinetype AS string) AS cuisine_type,
        try_cast(pricing_for_2 AS number(10, 2)) AS pricing_for_two,
        try_cast(restaurant_phone AS string) AS restaurant_phone,
        try_cast(operatinghours AS string) AS operating_hours,
        try_cast(locationid AS number) AS location_id_fk,
        try_cast(activeflag AS string) AS active_flag,
        try_cast(openstatus AS string) AS open_status,
        try_cast(locality AS string) AS locality,
        try_cast(restaurant_address AS string) AS restaurant_address,
        try_cast(latitude AS number(9, 6)) AS latitude,
        try_cast(longitude AS number(9, 6)) AS longitude,
        try_to_timestamp_ntz(createddate, 'YYYY-MM-DD HH24:MI:SS.FF9') AS created_dt,
        try_to_timestamp_ntz(modifieddate, 'YYYY-MM-DD HH24:MI:SS.FF9') AS modified_dt,
        _stg_file_name, _stg_file_load_ts, _stg_file_md5
    FROM stage_sch.restaurant_stm
) AS source
ON target.restaurant_id = source.restaurant_id
WHEN MATCHED THEN
    UPDATE SET
        target.name = source.name,
        target.cuisine_type = source.cuisine_type,
        target.pricing_for_two = source.pricing_for_two,
        target.restaurant_phone = source.restaurant_phone,
        target.operating_hours = source.operating_hours,
        target.location_id_fk = source.location_id_fk,
        target.active_flag = source.active_flag,
        target.open_status = source.open_status,
        target.locality = source.locality,
        target.restaurant_address = source.restaurant_address,
        target.latitude = source.latitude,
        target.longitude = source.longitude,
        target.created_dt = source.created_dt,
        target.modified_dt = source.modified_dt,
        target._stg_file_name = source._stg_file_name,
        target._stg_file_load_ts = source._stg_file_load_ts,
        target._stg_file_md5 = source._stg_file_md5
WHEN NOT MATCHED THEN
    INSERT (restaurant_id, name, cuisine_type, pricing_for_two, restaurant_phone,
        operating_hours, location_id_fk, active_flag, open_status, locality,
        restaurant_address, latitude, longitude, created_dt, modified_dt,
        _stg_file_name, _stg_file_load_ts, _stg_file_md5)
    VALUES (source.restaurant_id, source.name, source.cuisine_type, source.pricing_for_two,
        source.restaurant_phone, source.operating_hours, source.location_id_fk,
        source.active_flag, source.open_status, source.locality, source.restaurant_address,
        source.latitude, source.longitude, source.created_dt, source.modified_dt,
        source._stg_file_name, source._stg_file_load_ts, source._stg_file_md5);

-- 7c. MERGE clean -> dim  (delta 01)
MERGE INTO CONSUMPTION_SCH.RESTAURANT_DIM AS target
USING CLEAN_SCH.RESTAURANT_STM AS source
ON  target.RESTAURANT_ID = source.RESTAURANT_ID AND
    target.NAME = source.NAME AND
    target.CUISINE_TYPE = source.CUISINE_TYPE AND
    target.PRICING_FOR_TWO = source.PRICING_FOR_TWO AND
    target.RESTAURANT_PHONE = source.RESTAURANT_PHONE AND
    target.OPERATING_HOURS = source.OPERATING_HOURS AND
    target.LOCATION_ID_FK = source.LOCATION_ID_FK AND
    target.ACTIVE_FLAG = source.ACTIVE_FLAG AND
    target.OPEN_STATUS = source.OPEN_STATUS AND
    target.LOCALITY = source.LOCALITY AND
    target.RESTAURANT_ADDRESS = source.RESTAURANT_ADDRESS AND
    target.LATITUDE = source.LATITUDE AND
    target.LONGITUDE = source.LONGITUDE AND
    target.IS_CURRENT = TRUE
WHEN MATCHED
    AND source.METADATA$ACTION = 'DELETE' AND source.METADATA$ISUPDATE = 'TRUE' THEN
    UPDATE SET target.EFF_END_DATE = CURRENT_TIMESTAMP(), target.IS_CURRENT = FALSE
WHEN NOT MATCHED
    AND source.METADATA$ACTION = 'INSERT' AND source.METADATA$ISUPDATE = 'TRUE' THEN
    INSERT (RESTAURANT_HK, RESTAURANT_ID, NAME, CUISINE_TYPE, PRICING_FOR_TWO,
        RESTAURANT_PHONE, OPERATING_HOURS, LOCATION_ID_FK, ACTIVE_FLAG, OPEN_STATUS,
        LOCALITY, RESTAURANT_ADDRESS, LATITUDE, LONGITUDE,
        EFF_START_DATE, EFF_END_DATE, IS_CURRENT)
    VALUES (
        hash(SHA1_hex(CONCAT(source.RESTAURANT_ID, source.NAME, source.CUISINE_TYPE,
            source.PRICING_FOR_TWO, source.RESTAURANT_PHONE, source.OPERATING_HOURS,
            source.LOCATION_ID_FK, source.ACTIVE_FLAG, source.OPEN_STATUS, source.LOCALITY,
            source.RESTAURANT_ADDRESS, source.LATITUDE, source.LONGITUDE))),
        source.RESTAURANT_ID, source.NAME, source.CUISINE_TYPE, source.PRICING_FOR_TWO,
        source.RESTAURANT_PHONE, source.OPERATING_HOURS, source.LOCATION_ID_FK,
        source.ACTIVE_FLAG, source.OPEN_STATUS, source.LOCALITY, source.RESTAURANT_ADDRESS,
        source.LATITUDE, source.LONGITUDE, CURRENT_TIMESTAMP(), NULL, TRUE)
WHEN NOT MATCHED
    AND source.METADATA$ACTION = 'INSERT' AND source.METADATA$ISUPDATE = 'FALSE' THEN
    INSERT (RESTAURANT_HK, RESTAURANT_ID, NAME, CUISINE_TYPE, PRICING_FOR_TWO,
        RESTAURANT_PHONE, OPERATING_HOURS, LOCATION_ID_FK, ACTIVE_FLAG, OPEN_STATUS,
        LOCALITY, RESTAURANT_ADDRESS, LATITUDE, LONGITUDE,
        EFF_START_DATE, EFF_END_DATE, IS_CURRENT)
    VALUES (
        hash(SHA1_hex(CONCAT(source.RESTAURANT_ID, source.NAME, source.CUISINE_TYPE,
            source.PRICING_FOR_TWO, source.RESTAURANT_PHONE, source.OPERATING_HOURS,
            source.LOCATION_ID_FK, source.ACTIVE_FLAG, source.OPEN_STATUS, source.LOCALITY,
            source.RESTAURANT_ADDRESS, source.LATITUDE, source.LONGITUDE))),
        source.RESTAURANT_ID, source.NAME, source.CUISINE_TYPE, source.PRICING_FOR_TWO,
        source.RESTAURANT_PHONE, source.OPERATING_HOURS, source.LOCATION_ID_FK,
        source.ACTIVE_FLAG, source.OPEN_STATUS, source.LOCALITY, source.RESTAURANT_ADDRESS,
        source.LATITUDE, source.LONGITUDE, CURRENT_TIMESTAMP(), NULL, TRUE);


-- =====================================================================
-- ==========  DELTA DAY 02  ===========================================
-- =====================================================================
list @stage_sch.csv_stg/delta/restaurant/;

-- 8a. COPY delta 02 -> STAGE
copy into stage_sch.restaurant (restaurantid, name, cuisinetype, pricing_for_2, restaurant_phone,
                      operatinghours, locationid, activeflag, openstatus,
                      locality, restaurant_address, latitude, longitude,
                      createddate, modifieddate,
                      _stg_file_name, _stg_file_load_ts, _stg_file_md5, _copy_data_ts)
from (
    select
        t.$1::text, t.$2::text, t.$3::text, t.$4::text, t.$5::text,
        t.$6::text, t.$7::text, t.$8::text, t.$9::text, t.$10::text,
        t.$11::text, t.$12::text, t.$13::text, t.$14::text, t.$15::text,
        metadata$filename, metadata$file_last_modified, metadata$file_content_key,
        current_timestamp()
     from @stage_sch.csv_stg/delta/restaurant/day-02-upsert-restaurant-delhi+NCR.csv t
)
file_format = (format_name = 'stage_sch.csv_file_format')
on_error = abort_statement;

-- 8b. MERGE stage -> clean  (delta 02)
MERGE INTO clean_sch.restaurant AS target
USING (
    SELECT
        try_cast(restaurantid AS number) AS restaurant_id,
        try_cast(name AS string) AS name,
        try_cast(cuisinetype AS string) AS cuisine_type,
        try_cast(pricing_for_2 AS number(10, 2)) AS pricing_for_two,
        try_cast(restaurant_phone AS string) AS restaurant_phone,
        try_cast(operatinghours AS string) AS operating_hours,
        try_cast(locationid AS number) AS location_id_fk,
        try_cast(activeflag AS string) AS active_flag,
        try_cast(openstatus AS string) AS open_status,
        try_cast(locality AS string) AS locality,
        try_cast(restaurant_address AS string) AS restaurant_address,
        try_cast(latitude AS number(9, 6)) AS latitude,
        try_cast(longitude AS number(9, 6)) AS longitude,
        try_to_timestamp_ntz(createddate, 'YYYY-MM-DD HH24:MI:SS.FF9') AS created_dt,
        try_to_timestamp_ntz(modifieddate, 'YYYY-MM-DD HH24:MI:SS.FF9') AS modified_dt,
        _stg_file_name, _stg_file_load_ts, _stg_file_md5
    FROM stage_sch.restaurant_stm
) AS source
ON target.restaurant_id = source.restaurant_id
WHEN MATCHED THEN
    UPDATE SET
        target.name = source.name,
        target.cuisine_type = source.cuisine_type,
        target.pricing_for_two = source.pricing_for_two,
        target.restaurant_phone = source.restaurant_phone,
        target.operating_hours = source.operating_hours,
        target.location_id_fk = source.location_id_fk,
        target.active_flag = source.active_flag,
        target.open_status = source.open_status,
        target.locality = source.locality,
        target.restaurant_address = source.restaurant_address,
        target.latitude = source.latitude,
        target.longitude = source.longitude,
        target.created_dt = source.created_dt,
        target.modified_dt = source.modified_dt,
        target._stg_file_name = source._stg_file_name,
        target._stg_file_load_ts = source._stg_file_load_ts,
        target._stg_file_md5 = source._stg_file_md5
WHEN NOT MATCHED THEN
    INSERT (restaurant_id, name, cuisine_type, pricing_for_two, restaurant_phone,
        operating_hours, location_id_fk, active_flag, open_status, locality,
        restaurant_address, latitude, longitude, created_dt, modified_dt,
        _stg_file_name, _stg_file_load_ts, _stg_file_md5)
    VALUES (source.restaurant_id, source.name, source.cuisine_type, source.pricing_for_two,
        source.restaurant_phone, source.operating_hours, source.location_id_fk,
        source.active_flag, source.open_status, source.locality, source.restaurant_address,
        source.latitude, source.longitude, source.created_dt, source.modified_dt,
        source._stg_file_name, source._stg_file_load_ts, source._stg_file_md5);

-- 8c. MERGE clean -> dim  (delta 02)
MERGE INTO CONSUMPTION_SCH.RESTAURANT_DIM AS target
USING CLEAN_SCH.RESTAURANT_STM AS source
ON  target.RESTAURANT_ID = source.RESTAURANT_ID AND
    target.NAME = source.NAME AND
    target.CUISINE_TYPE = source.CUISINE_TYPE AND
    target.PRICING_FOR_TWO = source.PRICING_FOR_TWO AND
    target.RESTAURANT_PHONE = source.RESTAURANT_PHONE AND
    target.OPERATING_HOURS = source.OPERATING_HOURS AND
    target.LOCATION_ID_FK = source.LOCATION_ID_FK AND
    target.ACTIVE_FLAG = source.ACTIVE_FLAG AND
    target.OPEN_STATUS = source.OPEN_STATUS AND
    target.LOCALITY = source.LOCALITY AND
    target.RESTAURANT_ADDRESS = source.RESTAURANT_ADDRESS AND
    target.LATITUDE = source.LATITUDE AND
    target.LONGITUDE = source.LONGITUDE AND
    target.IS_CURRENT = TRUE
WHEN MATCHED
    AND source.METADATA$ACTION = 'DELETE' AND source.METADATA$ISUPDATE = 'TRUE' THEN
    UPDATE SET target.EFF_END_DATE = CURRENT_TIMESTAMP(), target.IS_CURRENT = FALSE
WHEN NOT MATCHED
    AND source.METADATA$ACTION = 'INSERT' AND source.METADATA$ISUPDATE = 'TRUE' THEN
    INSERT (RESTAURANT_HK, RESTAURANT_ID, NAME, CUISINE_TYPE, PRICING_FOR_TWO,
        RESTAURANT_PHONE, OPERATING_HOURS, LOCATION_ID_FK, ACTIVE_FLAG, OPEN_STATUS,
        LOCALITY, RESTAURANT_ADDRESS, LATITUDE, LONGITUDE,
        EFF_START_DATE, EFF_END_DATE, IS_CURRENT)
    VALUES (
        hash(SHA1_hex(CONCAT(source.RESTAURANT_ID, source.NAME, source.CUISINE_TYPE,
            source.PRICING_FOR_TWO, source.RESTAURANT_PHONE, source.OPERATING_HOURS,
            source.LOCATION_ID_FK, source.ACTIVE_FLAG, source.OPEN_STATUS, source.LOCALITY,
            source.RESTAURANT_ADDRESS, source.LATITUDE, source.LONGITUDE))),
        source.RESTAURANT_ID, source.NAME, source.CUISINE_TYPE, source.PRICING_FOR_TWO,
        source.RESTAURANT_PHONE, source.OPERATING_HOURS, source.LOCATION_ID_FK,
        source.ACTIVE_FLAG, source.OPEN_STATUS, source.LOCALITY, source.RESTAURANT_ADDRESS,
        source.LATITUDE, source.LONGITUDE, CURRENT_TIMESTAMP(), NULL, TRUE)
WHEN NOT MATCHED
    AND source.METADATA$ACTION = 'INSERT' AND source.METADATA$ISUPDATE = 'FALSE' THEN
    INSERT (RESTAURANT_HK, RESTAURANT_ID, NAME, CUISINE_TYPE, PRICING_FOR_TWO,
        RESTAURANT_PHONE, OPERATING_HOURS, LOCATION_ID_FK, ACTIVE_FLAG, OPEN_STATUS,
        LOCALITY, RESTAURANT_ADDRESS, LATITUDE, LONGITUDE,
        EFF_START_DATE, EFF_END_DATE, IS_CURRENT)
    VALUES (
        hash(SHA1_hex(CONCAT(source.RESTAURANT_ID, source.NAME, source.CUISINE_TYPE,
            source.PRICING_FOR_TWO, source.RESTAURANT_PHONE, source.OPERATING_HOURS,
            source.LOCATION_ID_FK, source.ACTIVE_FLAG, source.OPEN_STATUS, source.LOCALITY,
            source.RESTAURANT_ADDRESS, source.LATITUDE, source.LONGITUDE))),
        source.RESTAURANT_ID, source.NAME, source.CUISINE_TYPE, source.PRICING_FOR_TWO,
        source.RESTAURANT_PHONE, source.OPERATING_HOURS, source.LOCATION_ID_FK,
        source.ACTIVE_FLAG, source.OPEN_STATUS, source.LOCALITY, source.RESTAURANT_ADDRESS,
        source.LATITUDE, source.LONGITUDE, CURRENT_TIMESTAMP(), NULL, TRUE);


-- =====================================================================
-- VERIFICATION
-- =====================================================================
select * from table(information_schema.copy_history(
    table_name => 'RESTAURANT',
    start_time => dateadd(hours, -1, current_timestamp())));

select count(*) from stage_sch.restaurant;
select count(*) from clean_sch.restaurant;
select * from consumption_sch.restaurant_dim;