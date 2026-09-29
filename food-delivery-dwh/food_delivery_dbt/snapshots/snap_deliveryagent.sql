{% snapshot snap_deliveryagent %}
{{ config(target_schema='consumption_sch', unique_key='delivery_agent_id', strategy='check', check_cols='all') }}
select * from {{ ref('clean_deliveryagent') }}
{% endsnapshot %}