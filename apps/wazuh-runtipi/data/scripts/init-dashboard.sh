#!/bin/bash
set -e

echo "DASHBOARD_INIT: Starting dashboard initialization..."

CUSTOM_CONFIG="/usr/share/wazuh-dashboard/config/custom/opensearch_dashboards.yml"

# Ensure custom directory exists
echo "DASHBOARD_INIT: Ensuring custom config directory exists..."
mkdir -p /usr/share/wazuh-dashboard/config/custom

# Check if custom config exists, if not create default
if [ ! -s "$CUSTOM_CONFIG" ]; then
    echo "DASHBOARD_INIT: Creating default dashboard config..."

    cat > "$CUSTOM_CONFIG" << EOF
server.host: 0.0.0.0
server.port: 5601
opensearch.hosts: https://wazuh.indexer:9200
opensearch.ssl.verificationMode: certificate
opensearch.username: ${DASHBOARD_USERNAME:-kibanaserver}
opensearch.password: ${DASHBOARD_PASSWORD:-kibanaserver}
opensearch.requestHeadersWhitelist: ["securitytenant","Authorization"]
opensearch_security.multitenancy.enabled: false
opensearch_security.readonly_mode.roles: ["kibana_read_only"]
server.ssl.enabled: true
server.ssl.certificate: /usr/share/wazuh-dashboard/config/certs/dashboard.pem
server.ssl.key: /usr/share/wazuh-dashboard/config/certs/dashboard-key.pem
opensearch.ssl.certificateAuthorities: ["/usr/share/wazuh-dashboard/config/certs/root-ca.pem"]
uiSettings.overrides.defaultRoute: /app/wazuh
EOF

    echo "DASHBOARD_INIT: Default dashboard config created"
else
    echo "DASHBOARD_INIT: Custom dashboard config already exists, skipping"
fi

# Create symlink if it doesn't exist
if [ ! -L /usr/share/wazuh-dashboard/config/opensearch_dashboards.yml ]; then
    echo "DASHBOARD_INIT: Creating symlink to custom config..."
    rm -f /usr/share/wazuh-dashboard/config/opensearch_dashboards.yml
    ln -s "$CUSTOM_CONFIG" /usr/share/wazuh-dashboard/config/opensearch_dashboards.yml
else
    echo "DASHBOARD_INIT: Symlink already exists"
fi

echo "DASHBOARD_INIT: Configuration complete, starting dashboard..."

# Remove keystore to avoid interactive prompt on fresh installs
# The official entrypoint will recreate it automatically without prompting
KEYSTORE_PATH="/usr/share/wazuh-dashboard/config/opensearch_dashboards.keystore"
if [ -f "$KEYSTORE_PATH" ]; then
    echo "DASHBOARD_INIT: Removing existing keystore to avoid interactive prompt..."
    rm -f "$KEYSTORE_PATH"
fi

# Just exec the official entrypoint - let it handle everything!
exec /entrypoint.sh
