#!/bin/bash
# EAP 7.4 Keycloak SAML Extension Verification Script

# Set EAP_HOME (adjust path as needed)
EAP_HOME=${EAP_HOME:-"/app/jboss/EAP7"}
SERVER_HOST=${SERVER_HOST:-"localhost"}
MGMT_PORT=${MGMT_PORT:-"9990"}

echo "JBoss EAP 7.4 Keycloak SAML Extension Verification"
echo "=================================================="
echo "EAP_HOME: $EAP_HOME"
echo ""

# Test 1: Check EAP version
echo "1. Checking EAP Version..."
if [ -f "$EAP_HOME/bin/standalone.sh" ]; then
    EAP_VERSION=$($EAP_HOME/bin/standalone.sh --version 2>/dev/null | head -1)
    echo "   ✅ $EAP_VERSION"
else
    echo "   ❌ EAP installation not found at $EAP_HOME"
    exit 1
fi

# Test 2: Check Keycloak modules in EAP
echo "2. Checking Keycloak modules..."
KEYCLOAK_MODULES=("keycloak-saml-adapter-subsystem" "keycloak-saml-wildfly-elytron-adapter" "keycloak-adapter-core")

for module in "${KEYCLOAK_MODULES[@]}"; do
    if [ -d "$EAP_HOME/modules/system/add-ons/keycloak/org/keycloak/$module" ] || 
       [ -d "$EAP_HOME/modules/system/layers/base/org/keycloak/$module" ]; then
        echo "   ✅ Module $module found"
    else
        echo "   ❌ Module $module NOT found"
    fi
done

# Test 3: Check if RH-SSO adapter is installed
echo "3. Checking RH-SSO/Keycloak adapter installation..."
if [ -d "$EAP_HOME/modules/system/add-ons/keycloak" ]; then
    echo "   ✅ Keycloak add-on modules directory exists"
    ls -la "$EAP_HOME/modules/system/add-ons/keycloak/org/keycloak/" 2>/dev/null | head -5
else
    echo "   ❌ Keycloak add-on not installed - you may need to install RH-SSO adapter"
fi

# Test 4: Check management interface
echo "4. Testing management interface..."
MGMT_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://$SERVER_HOST:$MGMT_PORT/management 2>/dev/null)
if [[ "$MGMT_RESPONSE" == "200" ]]; then
    echo "   ✅ Management interface accessible (HTTP $MGMT_RESPONSE)"
else
    echo "   ❌ Management interface not accessible (HTTP $MGMT_RESPONSE)"
fi

# Test 5: Check domain configuration
echo "5. Checking domain configuration files..."
DOMAIN_CONFIG="$EAP_HOME/domain/configuration/domain.xml"
if [ -f "$DOMAIN_CONFIG" ]; then
    if grep -q "keycloak-saml-adapter-subsystem" "$DOMAIN_CONFIG"; then
        echo "   ✅ Keycloak extension found in domain.xml"
    else
        echo "   ❌ Keycloak extension NOT found in domain.xml"
    fi
    
    if grep -q "keycloak-saml:1.4" "$DOMAIN_CONFIG"; then
        echo "   ✅ Keycloak SAML subsystem found in domain.xml"
    else
        echo "   ❌ Keycloak SAML subsystem NOT found in domain.xml"
    fi
else
    echo "   ❌ Domain configuration not found"
fi

echo ""
echo "=================================================="
echo "Next steps for verification:"
echo "1. Run EAP CLI script: ./verify-eap74-keycloak.cli"
echo "2. Check server logs: tail -f $EAP_HOME/domain/servers/*/log/server.log"
echo "3. Deploy test application with KEYCLOAK-SAML auth-method"
echo ""
echo "If Keycloak modules are missing, install RH-SSO adapter:"
echo "- Download RH-SSO EAP7 Adapter from Red Hat Customer Portal"
echo "- Install using: unzip -o rh-sso-*-eap7-adapter.zip -d \$EAP_HOME"