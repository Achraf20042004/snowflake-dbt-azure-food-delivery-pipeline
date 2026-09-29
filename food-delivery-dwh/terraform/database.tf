resource "snowflake_database" "sandbox" {
  name = "SANDBOX"
  lifecycle {
    prevent_destroy = true
  }
}

resource "snowflake_schema" "stage_sch" {
  database = snowflake_database.sandbox.name
  name     = "STAGE_SCH"
  lifecycle {
    prevent_destroy = true
  }
}

resource "snowflake_schema" "clean_sch" {
  database = snowflake_database.sandbox.name
  name     = "CLEAN_SCH"
  lifecycle {
    prevent_destroy = true
  }
}

resource "snowflake_schema" "consumption_sch" {
  database = snowflake_database.sandbox.name
  name     = "CONSUMPTION_SCH"
  lifecycle {
    prevent_destroy = true
  }
}

resource "snowflake_schema" "common" {
  database = snowflake_database.sandbox.name
  name     = "COMMON"
  lifecycle {
    prevent_destroy = true
  }
}




