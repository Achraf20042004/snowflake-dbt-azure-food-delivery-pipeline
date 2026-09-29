{% snapshot snap_customer %}
{{ config(target_schema='consumption_sch', unique_key='customer_id', strategy='check', check_cols='all') }}
select * from {{ ref('clean_customer') }}
{% endsnapshot %}