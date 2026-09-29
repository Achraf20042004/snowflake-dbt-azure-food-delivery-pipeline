# Food Delivery Data Warehouse (Snowflake + Azure)

End-to-end analytics pipeline for a fictional food-delivery domain: raw CSVs land in Azure ADLS, Snowflake loads and transforms them through a **medallion** layout (Bronze → Silver → Gold), **dbt** automates transformations and tests, **Terraform** provisions Azure + Snowflake integration, and a **Streamlit** app surfaces revenue KPIs in Snowflake.

For a full walkthrough in plain language, see [PROJECT_EXPLAINED.txt](./PROJECT_EXPLAINED.txt).

## Stack

| Layer | Tool / location |
|--------|------------------|
| Cloud DWH | Snowflake (`sandbox` database) |
| Raw files | Azure Data Lake Storage Gen2 |
| IaC | Terraform (Snowflake + Azure providers) |
| Transformations | dbt (staging → clean → marts) |
| Dashboard | Streamlit in Snowflake (`food-delivery-dwh/streamlit/`) |

## Repository layout

```
├── DATA/Sample_Swiggy_Data/     Sample CSVs for local / stage uploads
├── food-delivery-dwh/
│   ├── snowflake_scripts/       Manual SQL path (01–15) + terraform_conn.example.sql
│   ├── sql/                     Alternate SQL layout (dimensions, facts, KPIs)
│   ├── terraform/               Azure RG, ADLS, ADF, Snowflake integration
│   ├── food_delivery_dbt/       dbt project (automated path)
│   └── streamlit/               Revenue dashboard
└── PROJECT_EXPLAINED.txt        Deep-dive documentation
```

Two build paths share the same target architecture:

1. **Manual** — run numbered scripts in `snowflake_scripts/` (upload CSVs to an internal stage first).
2. **Automated** — Terraform + external Azure stage + `dbt run` / `dbt test`.

## Prerequisites

- Snowflake account with `SYSADMIN` (and steps in scripts that use `ACCOUNTADMIN` where noted)
- Azure subscription
- [Terraform](https://www.terraform.io/) ≥ 1.5
- [dbt](https://docs.getdbt.com/) with `dbt-snowflake`
- Snowflake key-pair auth for Terraform (RSA `.p8` private key, never committed)

## Credentials (local only)

Copy examples and fill in real values. These files are **gitignored**:

| Secret file | Template |
|-------------|----------|
| `food-delivery-dwh/terraform/terraform.tfvars` | `terraform/terraform.tfvars.example` |
| `food-delivery-dwh/snowflake_scripts/terraform_conn.sql` | `snowflake_scripts/terraform_conn.example.sql` |
| `~/.dbt/profiles.yml` | `food_delivery_dbt/profiles.yml.example` |

Generate a Snowflake key pair for the Terraform service user; register the **public** key via `terraform_conn.sql` (from the example).

## Quick start (automated path)

1. **Terraform** — from `food-delivery-dwh/terraform/`:
   - Copy `terraform.tfvars.example` → `terraform.tfvars` and set Snowflake + Azure IDs and `private_key_path`.
   - Run `terraform init` then `terraform apply`.
2. **Snowflake** — run `snowflake_scripts/15_azure_integration_setup.sql` (and earlier scripts if bootstrapping from scratch).
3. **Upload sample data** to the Azure `raw` container under paths matching `14_azure_load.sql` / `DATA/Sample_Swiggy_Data/`.
4. **dbt** — from `food-delivery-dwh/food_delivery_dbt/`:
   - Copy `profiles.yml.example` to `~/.dbt/profiles.yml` (or merge the `food_delivery_dbt` profile).
   - `dbt deps` (if using packages), `dbt run`, `dbt test`.
5. **Streamlit** — deploy `streamlit/streamlit_app.py` in Snowflake (uses `get_active_session()`; no secrets in code).

## Sample data

Small Swiggy-style CSVs live under `DATA/Sample_Swiggy_Data/`. One large file (`order-item-initial-v2.csv`) is excluded from Git via `.gitignore`; use the included `order-Item-initial.csv` for demos.

## Security notes

- Do not commit `terraform.tfvars`, `terraform_conn.sql`, `*.p8`, or `.env`.
- PII masking policies and tags are defined in the manual SQL bootstrap scripts.
- Terraform and SQL reference a demo storage account name; use your own names when deploying to a new environment.

## License

Portfolio / educational project. Sample data naming references Swiggy-style entities; not affiliated with Swiggy.
