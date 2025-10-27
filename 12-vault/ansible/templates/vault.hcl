
ui = true
cluster_name = "main"
disable_mlock = true

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = true
}


storage "raft" {
  path    = "/opt/vault/data"
  node_id = "vault-ec2-1"
}


cluster_addr = "http://127.0.0.1:8201"



log_level = "info"
telemetry {
  prometheus_retention_time = "24h"
}
