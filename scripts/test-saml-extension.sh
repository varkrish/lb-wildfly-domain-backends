#!/bin/bash
# Test script to verify Keycloak SAML extension functionality

SERVER_HOST="your-server-hostname"
SERVER_PORT="8080"  # Adjust port as needed
APP_CONTEXT="your-app-name"  # Replace with actual app name

echo "Testing Keycloak SAML Extension on $SERVER_HOST:$SERVER_PORT"
echo "=================================================="

# Test 1: Check if server responds
echo "1. Testing server connectivity..."
curl -s -o /dev/null -w "%{http_code}" http://$SERVER_HOST:$SERVER_PORT/
if [ $? -eq 0 ]; then
    echo "   ✅ Server is accessible"
else
    echo "   ❌ Server not accessible"
fi

# Test 2: Try to access protected resource (should redirect to SAML)
echo "2. Testing SAML redirect..."
RESPONSE=$(curl -s -L -o /dev/null -w "%{http_code}" http://$SERVER_HOST:$SERVER_PORT/$APP_CONTEXT/protected-resource)
if [[ "$RESPONSE" == "200" ]] || [[ "$RESPONSE" == "302" ]] || [[ "$RESPONSE" == "401" ]]; then
    echo "   ✅ Protected resource responds (HTTP $RESPONSE)"
else
    echo "   ❌ Unexpected response: $RESPONSE"
fi

# Test 3: Check if SAML endpoints are available
echo "3. Testing SAML consumer endpoint..."
SAML_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://$SERVER_HOST:$SERVER_PORT/$APP_CONTEXT/saml)
echo "   SAML endpoint response: $SAML_RESPONSE"

echo "=================================================="
echo "Manual verification steps:"
echo "1. Access: http://$SERVER_HOST:$SERVER_PORT/$APP_CONTEXT"
echo "2. Should redirect to Keycloak/SAML IdP login page"
echo "3. Check server logs for SAML-related messages"