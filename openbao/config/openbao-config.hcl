# OpenBao Configuration for EHR System

# UI enabled for administration
ui = true

# MongoDB storage backend
storage "mongodb" {
  address         = "mongodb_vault:27017"
  database        = "openbao"
  collection      = "vault_storage"
  # In production, add username/password here
  # username       = "openbao_user"
  # password       = "your_secure_password_here"
}

# TCP listener configuration
listener "tcp" {
  address         = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  
  # IMPORTANT: For production, you MUST enable TLS
  # For development/testing only:
  tls_disable     = "true"
  
  # Production TLS configuration (commented out for now):
  # tls_cert_file = "/etc/openbao/tls/tls.crt"
  # tls_key_file  = "/etc/openbao/tls/tls.key"
}

# API address (how clients reach OpenBao)
api_addr         = "http://openbao:8200"
cluster_addr     = "http://openbao:8201"

# Telemetry (optional)
telemetry {
  prometheus_retention_time = "24h"
  disable_hostname = true
}
