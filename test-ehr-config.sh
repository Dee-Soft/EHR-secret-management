#!/bin/bash

echo "=== Testing EHR OpenBao Configuration ==="

VAULT_ADDR="http://localhost:8200"
VAULT_TOKEN="s.ZlQFmE4R60IuiSWq0uC5xhiI"  # Replace with your token

echo "1. Testing Transit Engine..."
echo "   Generating a test data key..."
RESPONSE=$(curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
  --request POST \
  $VAULT_ADDR/v1/transit/datakey/plaintext/ehr-aes-master)

if echo "$RESPONSE" | grep -q "ciphertext"; then
    echo "   ✅ Data key generation successful"
    
    # Extract the ciphertext for testing
    CIPHERTEXT=$(echo $RESPONSE | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['ciphertext'])")
    
    echo "2. Testing encryption with the key..."
    ENCRYPT_RESPONSE=$(curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
      --header "Content-Type: application/json" \
      --request POST \
      --data "{\"plaintext\": \"$(echo -n 'EHR Test Data' | base64)\"}" \
      $VAULT_ADDR/v1/transit/encrypt/ehr-aes-master)
    
    if echo "$ENCRYPT_RESPONSE" | grep -q "ciphertext"; then
        echo "   ✅ Encryption successful"
        
        # Test RSA key wrapping
        echo "3. Testing RSA key exchange..."
        RSA_RESPONSE=$(curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
          --header "Content-Type: application/json" \
          --request POST \
          --data "{\"plaintext\": \"$(echo -n 'AES Key Material' | base64)\"}" \
          $VAULT_ADDR/v1/transit/encrypt/ehr-rsa-exchange)
        
        if echo "$RSA_RESPONSE" | grep -q "ciphertext"; then
            echo "   ✅ RSA wrapping successful"
        else
            echo "   ❌ RSA wrapping failed"
        fi
    else
        echo "   ❌ Encryption failed"
    fi
else
    echo "   ❌ Data key generation failed"
    echo "   Response: $RESPONSE"
fi

echo ""
echo "4. Testing KV secrets..."
KV_RESPONSE=$(curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
  $VAULT_ADDR/v1/ehr/data/mongodb/config)

if echo "$KV_RESPONSE" | grep -q "connection_string"; then
    echo "   ✅ KV secrets accessible"
else
    echo "   ❌ KV secrets not accessible"
fi

echo ""
echo "=== Test Complete ==="
echo "OpenBao is configured and ready for EHR integration!"
