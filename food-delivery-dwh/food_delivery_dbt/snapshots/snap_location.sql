{% snapshot snap_location %}
{{ config(target_schema='consumption_sch', unique_key='location_id', strategy='check', check_cols='all') }}
select * from {{ ref('clean_location') }}
{% endsnapshot %}