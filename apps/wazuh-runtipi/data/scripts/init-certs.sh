#!/bin/sh
set -e

echo "CERTS_INIT: Starting certificate initialization..."

# Create all required directories
echo "CERTS_INIT: Creating directories..."
mkdir -p /indexer-data \
         /manager-api \
         /manager-logs \
         /manager-queue \
         /dashboard-config \
         /indexer-security

# Super-Janitor Sweep: Remove any files/directories that were incorrectly created as directories
echo "CERTS_INIT: Starting Super-Janitor Sweep..."
for path in /certificates/*.pem \
            /certificates/*.key \
            /dashboard-config/opensearch_dashboards.yml \
            /indexer-security/config.yml \
            /indexer-security/nodes_dn.yml \
            /indexer-security/tenants.yml \
            /indexer-security/whitelist.yml \
            /indexer-security/roles.yml \
            /indexer-security/roles_mapping.yml \
            /indexer-security/internal_users.yml \
            /indexer-security/action_groups.yml; do
    if [ -d "$path" ]; then
        echo "CERTS_INIT: Purging fake directory: $path"
        rm -rf "$path"
    fi
done

# Generate certificates if they don't exist
if [ ! -f /certificates/root-ca.pem ]; then
    echo "CERTS_INIT: Generating new certificates..."
    /entrypoint.sh
else
    echo "CERTS_INIT: Certificates already exist, skipping generation"
fi

# Create symlinks for easier reference
echo "CERTS_INIT: Creating certificate symlinks..."
ln -sf wazuh.indexer.pem /certificates/indexer.pem
ln -sf wazuh.indexer-key.pem /certificates/indexer-key.pem
ln -sf wazuh.manager.pem /certificates/server.pem
ln -sf wazuh.manager-key.pem /certificates/server-key.pem
ln -sf wazuh.dashboard.pem /certificates/dashboard.pem
ln -sf wazuh.dashboard-key.pem /certificates/dashboard-key.pem

# Set correct ownership
# - 1000:1000 for indexer and dashboard (opensearch/kibana user)
# - 999:999 for manager directories (wazuh user in manager container)
echo "CERTS_INIT: Setting ownership and permissions..."
chown -R 1000:1000 /certificates \
                   /indexer-data \
                   /dashboard-config \
                   /indexer-security

chown -R 999:999 /manager-api \
                 /manager-logs \
                 /manager-queue

# Set correct permissions
chmod 700 /certificates
chmod 644 /certificates/*.pem 2>/dev/null || true
chmod 600 /certificates/*.key 2>/dev/null || true

echo "CERTS_INIT: Certificates ready"

# Keep container alive (Runtipi requirement)
tail -f /dev/null
