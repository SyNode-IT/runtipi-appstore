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

# Handle keystore initialization idempotently to avoid interactive prompts
KEYSTORE_PATH="/usr/share/wazuh-dashboard/config/opensearch_dashboards.keystore"
if [ ! -f "$KEYSTORE_PATH" ]; then
    echo "DASHBOARD_INIT: Creating dashboard keystore..."
    # The --allow-root flag is often needed if running as root
    /usr/share/wazuh-dashboard/bin/opensearch-dashboards-keystore create 2>/dev/null || true
fi

# Start dashboard in background
echo "DASHBOARD_INIT: Configuration complete, starting dashboard..."
/entrypoint.sh &
DASHBOARD_PID=$!

# Give the process a moment to start and resolve its sub-processes
sleep 5

# Robust PID tracking: looking for the actual Node.js process if entrypoint isn't using exec
if ! kill -0 $DASHBOARD_PID 2>/dev/null; then
    echo "DASHBOARD_INIT: Main PID $DASHBOARD_PID died, checking for sub-processes..."
    # Look for opensearch-dashboards node process
    ACTUAL_PID=$(pgrep -f "opensearch-dashboards" || echo "")
    if [ -n "$ACTUAL_PID" ]; then
        DASHBOARD_PID=$ACTUAL_PID
        echo "DASHBOARD_INIT: Found actual dashboard process at PID $DASHBOARD_PID"
    else
        echo "DASHBOARD_INIT: ERROR - No dashboard process found!"
        exit 1
    fi
fi

# Periodic monitoring with migration lock detection
echo "MIGRATION_WATCHDOG: Monitoring dashboard startup (PID: $DASHBOARD_PID)..."
TIMEOUT=600 # Increase timeout to 10 minutes due to Indexer slowness
ELAPSED=0
MIGRATION_LOCK_DETECTED_AT=0

while [ $ELAPSED -lt $TIMEOUT ]; do
    # Check if dashboard process is still alive
    if ! kill -0 $DASHBOARD_PID 2>/dev/null; then
        echo "MIGRATION_WATCHDOG: ERROR - Dashboard process (PID: $DASHBOARD_PID) died after ${ELAPSED}s!"
        exit 1
    fi

    # Check if dashboard API is responding
    API_STATUS=$(curl -sk -o /dev/null -w "%{http_code}" https://localhost:5601/api/status 2>/dev/null)
    if [[ "$API_STATUS" == "200" || "$API_STATUS" == "302" || "$API_STATUS" == "401" ]]; then
        echo "MIGRATION_WATCHDOG: Dashboard is responding (HTTP $API_STATUS) after ${ELAPSED}s"
        # We don't break yet, we continue monitoring until it's "Stable" (HTTP 200)
        if [ "$API_STATUS" == "200" ]; then
            echo "MIGRATION_WATCHDOG: Dashboard is fully UP and Stable."
            break
        fi
    fi

    # Check for migration lock (stuck .kibana_1)
    HTTP_CODE=$(curl -sk -u "${INDEXER_USERNAME:-admin}:${INDEXER_PASSWORD:-admin}" -o /dev/null -w "%{http_code}" "https://wazuh.indexer:9200/.kibana_1" 2>/dev/null)

    if [ "$HTTP_CODE" = "200" ] && [ $MIGRATION_LOCK_DETECTED_AT -eq 0 ]; then
        MIGRATION_LOCK_DETECTED_AT=$ELAPSED
        echo "MIGRATION_WATCHDOG: Detected .kibana_1 index at ${ELAPSED}s, waiting for natural migration..."
    fi

    if [ "$HTTP_CODE" = "200" ] && [ $MIGRATION_LOCK_DETECTED_AT -gt 0 ]; then
        STUCK_DURATION=$((ELAPSED - MIGRATION_LOCK_DETECTED_AT))
        if [ $STUCK_DURATION -ge 240 ]; then # Increase to 4 minutes
            echo "MIGRATION_WATCHDOG: Index stuck for ${STUCK_DURATION}s, cleaning up..."
            curl -sk -u "${INDEXER_USERNAME:-admin}:${INDEXER_PASSWORD:-admin}" -X DELETE "https://wazuh.indexer:9200/.kibana_1" 2>/dev/null || true
            kill $DASHBOARD_PID 2>/dev/null || true
            exit 0
        fi
    fi

    sleep 15
    ELAPSED=$((ELAPSED + 15))

    if [ $((ELAPSED % 60)) -eq 0 ]; then
        echo "MIGRATION_WATCHDOG: Still waiting for dashboard (${ELAPSED}s, Status: $API_STATUS)..."
    fi
done

echo "MIGRATION_WATCHDOG: Finalizing monitoring. Entering persistent loop."
# Keep watching the dashboard process
while kill -0 $DASHBOARD_PID 2>/dev/null; do
    sleep 60
done

echo "DASHBOARD_INIT: Process died. Exiting."
exit 1
