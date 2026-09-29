# food_delivery_dbt

dbt models for the food delivery warehouse: **staging** (Bronze), **clean** (Silver), **marts** (Gold facts + KPI views), plus **snapshots** for SCD Type 2 dimensions.

## Setup

1. Install [dbt-snowflake](https://docs.getdbt.com/docs/core/connect-data-platform/snowflake-setup).
2. Copy `profiles.yml.example` → `~/.dbt/profiles.yml` and set account, user, and key path.
3. From this directory:

```bash
dbt run
dbt test
```

Project profile name: `food_delivery_dbt` (see `dbt_project.yml`).

Repository overview and Terraform/Azure steps: [../../README.md](../../README.md).
