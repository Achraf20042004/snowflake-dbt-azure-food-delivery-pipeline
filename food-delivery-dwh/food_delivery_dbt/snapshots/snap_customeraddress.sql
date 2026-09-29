{% snapshot snap_customeraddress %}
{{ config(target_schema='consumption_sch', unique_key='address_id', strategy='check', check_cols='all') }}
select * from {{ ref('clean_customeraddress') }}
{% endsnapshot %}