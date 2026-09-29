import {
  to = snowflake_warehouse.adhoc_wh
  id = "\"ADHOC_WH\""
}

resource "snowflake_warehouse" "adhoc_wh" {
  name                                = "ADHOC_WH"
  warehouse_type                      = "STANDARD"
  warehouse_size                      = "XSMALL"
  generation                          = "2"
  min_cluster_count                   = 1
  max_cluster_count                   = 1
  auto_suspend                        = 60
  auto_resume                         = "true"
  initially_suspended                 = true
  enable_query_acceleration           = "false"
  query_acceleration_max_scale_factor = 8
  scaling_policy                      = "STANDARD"
  comment                             = "This is the adhoc-wh"
}