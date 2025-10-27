
ui = true
cluster_name = "main"
disable_mlock = true

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = true
}


storage "file" {
  path = "/opt/vault/data"
}

log_level = "info"
telemetry {
  prometheus_retention_time = "24h"
}
