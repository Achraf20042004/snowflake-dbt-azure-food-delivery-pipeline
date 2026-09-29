{% snapshot snap_menu %}
{{ config(target_schema='consumption_sch', unique_key='menu_id', strategy='check', check_cols='all') }}
select * from {{ ref('clean_menu') }}
{% endsnapshot %}