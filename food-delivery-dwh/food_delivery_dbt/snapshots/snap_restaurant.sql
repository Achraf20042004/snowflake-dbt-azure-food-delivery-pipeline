{% snapshot snap_restaurant %}
{{
    config(
        target_schema='consumption_sch',
        unique_key='restaurant_id',
        strategy='check',
        check_cols='all'
    )
}}

select * from {{ ref('clean_restaurant') }}

{% endsnapshot %}