use role sysadmin;
use database sandbox;

alter schema stage_sch rename to stage_sch_tf_empty;
undrop schema stage_sch;
drop schema stage_sch_tf_empty;

alter schema clean_sch rename to clean_sch_tf_empty;
undrop schema clean_sch;
drop schema clean_sch_tf_empty;

alter schema consumption_sch rename to consumption_sch_tf_empty;
undrop schema consumption_sch;
drop schema consumption_sch_tf_empty;

alter schema common rename to common_tf_empty;
undrop schema common;
drop schema common_tf_empty;



list @sandbox.stage_sch.csv_stg;

show tables in schema sandbox.clean_sch;
show tables in schema sandbox.consumption_sch;
show masking policies in schema sandbox.common;




DESC STORAGE INTEGRATION AZURE_STORAGE_INT;
use role accountadmin;

grant create integration on account to role sysadmin;
DESC STORAGE INTEGRATION AZURE_STORAGE_INT;






use role sysadmin;
use database sandbox;
use schema stage_sch;

create or replace stage stage_sch.azure_stg
  storage_integration = azure_storage_int
  url = 'azure://fooddeliverydwhadls.blob.core.windows.net/raw/'
  file_format = stage_sch.csv_file_format
  comment = 'External stage pointing to Azure ADLS raw container';

  list @stage_sch.azure_stg;



  list @stage_sch.azure_stg;