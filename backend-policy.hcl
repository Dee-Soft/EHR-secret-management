# Backend policy for EHR system
path "transit/encrypt/ehr-rsa-exchange" {
  capabilities = ["create", "update"]
}

path "transit/decrypt/ehr-rsa-exchange" {
  capabilities = ["create", "update"]
}

path "transit/datakey/plaintext/ehr-aes-master" {
  capabilities = ["create", "update"]
}

path "transit/encrypt/ehr-aes-master" {
  capabilities = ["create", "update"]
}

path "transit/decrypt/ehr-aes-master" {
  capabilities = ["create", "update"]
}

path "transit/keys/*" {
  capabilities = ["read"]
}

# KV storage for configuration
path "ehr/data/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
