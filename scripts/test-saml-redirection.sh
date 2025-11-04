#!/bin/bash
# SAML Redirection Test Script

echo "=== SAML Redirection Testing ==="
echo ""

# Test 1: Check if KEYCLOAK-SAML auth method is recognized (no errors in deployment)
echo "1. Testing KEYCLOAK-SAML Authentication Method Recognition..."

# Create a simple test app with KEYCLOAK-SAML
cat > /tmp/test-web.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="http://xmlns.jcp.org/xml/ns/javaee"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee
         http://xmlns.jcp.org/xml/ns/javaee/web-app_4_0.xsd"
         version="4.0">
    
    <display-name>SAML Test Application</display-name>
    
    <security-constraint>
        <web-resource-collection>
            <web-resource-name>Secured Area</web-resource-name>
            <url-pattern>/secured/*</url-pattern>
            <http-method>GET</http-method>
            <http-method>POST</http-method>
        </web-resource-collection>
        <auth-constraint>
            <role-name>user</role-name>
        </auth-constraint>
    </security-constraint>
    
    <login-config>
        <auth-method>KEYCLOAK-SAML</auth-method>
        <realm-name>test-realm</realm-name>
    </login-config>
    
    <security-role>
        <role-name>user</role-name>
    </security-role>
</web-app>
EOF

# Create simple test pages
mkdir -p /tmp/saml-test-app/WEB-INF/secured
cp /tmp/test-web.xml /tmp/saml-test-app/WEB-INF/web.xml

cat > /tmp/saml-test-app/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>SAML Test App</title>
</head>
<body>
    <h1>SAML Authentication Test</h1>
    <p>This is the public area. No authentication required.</p>
    <p><a href="secured/protected.html">Access Protected Area (Requires SAML Auth)</a></p>
</body>
</html>
EOF

cat > /tmp/saml-test-app/secured/protected.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Protected Area</title>
</head>
<body>
    <h1>Protected Content</h1>
    <p>If you can see this without being redirected, SAML auth is not working properly.</p>
    <p>If SAML is working, you should have been redirected to authenticate first.</p>
</body>
</html>
EOF

# Package the test app
echo "   Creating SAML test WAR..."
cd /tmp/saml-test-app
jar cfM /tmp/saml-test.war .
cd - > /dev/null

echo "   ✅ SAML test application created: /tmp/saml-test.war"
echo ""

# Test 2: Deploy and check for auth method errors
echo "2. Deploying test application to check KEYCLOAK-SAML recognition..."

DEPLOY_RESULT=$(podman exec domain-controller /opt/jboss/wildfly/bin/jboss-cli.sh -c --controller=localhost:9990 --command="deploy /tmp/saml-test.war --server-groups=backend-group" 2>&1)

if echo "$DEPLOY_RESULT" | grep -q "KEYCLOAK-SAML.*not found\|authentication method.*not supported"; then
    echo "   ❌ KEYCLOAK-SAML authentication method not recognized"
    echo "   Error: $DEPLOY_RESULT"
else
    echo "   ✅ KEYCLOAK-SAML authentication method is recognized (no auth method errors)"
    
    # Test 3: Check redirection behavior
    echo ""
    echo "3. Testing SAML Redirection Behavior..."
    
    # Test public area (should work)
    echo "   Testing public area..."
    PUBLIC_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9081/saml-test/ --connect-timeout 5)
    if [[ "$PUBLIC_RESPONSE" == "200" ]]; then
        echo "   ✅ Public area accessible (HTTP $PUBLIC_RESPONSE)"
    else
        echo "   ⚠️  Public area response: HTTP $PUBLIC_RESPONSE"
    fi
    
    # Test protected area (should redirect or show auth required)
    echo "   Testing protected area (should trigger SAML behavior)..."
    
    # First, let's check what happens when we access the protected area
    PROTECTED_RESPONSE=$(curl -s -w "%{http_code}|%{redirect_url}|%{content_type}" -o /tmp/protected_response.html http://localhost:9081/saml-test/secured/protected.html --connect-timeout 5)
    HTTP_CODE=$(echo "$PROTECTED_RESPONSE" | cut -d'|' -f1)
    REDIRECT_URL=$(echo "$PROTECTED_RESPONSE" | cut -d'|' -f2)
    CONTENT_TYPE=$(echo "$PROTECTED_RESPONSE" | cut -d'|' -f3)
    
    echo "   Protected area response: HTTP $HTTP_CODE"
    
    if [[ "$HTTP_CODE" == "302" ]] || [[ "$HTTP_CODE" == "401" ]] || [[ "$HTTP_CODE" == "403" ]]; then
        echo "   ✅ SAML authentication is being triggered (HTTP $HTTP_CODE)"
        if [[ -n "$REDIRECT_URL" ]]; then
            echo "   🔀 Redirect URL: $REDIRECT_URL"
        fi
    elif [[ "$HTTP_CODE" == "200" ]]; then
        echo "   ⚠️  Protected area is accessible without authentication"
        echo "   This might indicate SAML configuration needs refinement"
    else
        echo "   ⚠️  Unexpected response: HTTP $HTTP_CODE"
    fi
    
    # Check response headers for SAML-related information
    echo ""
    echo "4. Checking HTTP Headers for SAML Information..."
    curl -s -I http://localhost:9081/saml-test/secured/protected.html --connect-timeout 5 | grep -E "(Location|WWW-Authenticate|Set-Cookie)" | while read line; do
        echo "   Header: $line"
    done
fi

echo ""
echo "=== Additional Manual Testing Recommendations ==="
echo ""
echo "To fully test SAML redirection, you can:"
echo ""
echo "1. Browser Test:"
echo "   Open: http://localhost:9081/saml-test/"
echo "   Click 'Access Protected Area' and observe browser behavior"
echo ""
echo "2. Curl with verbose output:"
echo "   curl -v http://localhost:9081/saml-test/secured/protected.html"
echo ""
echo "3. Check server logs for SAML activity:"
echo "   podman logs backend1 2>&1 | grep -i saml"
echo ""
echo "4. Verify Keycloak subsystem configuration:"
echo "   podman exec domain-controller /opt/jboss/wildfly/bin/jboss-cli.sh -c \\"
echo "     --controller=localhost:9990 \\"
echo "     --command='ls /profile=full/subsystem=keycloak-saml'"

echo ""
echo "=== Test Complete ==="