#!/bin/bash
set -e

echo "INDEXER_INIT: Starting security initialization..."

# Check if security files already exist
if [ ! -f /mnt/host-security/internal_users.yml ]; then
    echo "INDEXER_INIT: Copying security configs..."

    SRC_PATH="/usr/share/wazuh-indexer/config/opensearch-security"

    for file in config.yml roles.yml roles_mapping.yml internal_users.yml action_groups.yml tenants.yml nodes_dn.yml whitelist.yml; do
        if [ -f "$SRC_PATH/$file" ]; then
            cp "$SRC_PATH/$file" /mnt/host-security/
            echo "INDEXER_INIT: Copied $file"
        else
            echo "INDEXER_INIT: $file not found, skipping"
        fi
    done

    echo "INDEXER_INIT: Security files ready"
else
    echo "INDEXER_INIT: Security files already exist, skipping copy"
fi

# Set JAVA_HOME
export JAVA_HOME=/usr/share/wazuh-indexer/jdk

# Wait for indexer to be ready
echo "INDEXER_INIT: Waiting for indexer to be available..."
until curl -ks https://wazuh.indexer:9200 -u "${INDEXER_USERNAME:-admin}:${INDEXER_PASSWORD:-admin}"; do
    echo "INDEXER_INIT: Indexer not ready, retrying in 5 seconds..."
    sleep 5
done

echo "INDEXER_INIT: Indexer is ready, initializing security..."

# Initialize security
/usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh \
    -cd /mnt/host-security/ \
    -cacert /usr/share/wazuh-indexer/config/certs/root-ca.pem \
    -cert /usr/share/wazuh-indexer/config/certs/admin.pem \
    -key /usr/share/wazuh-indexer/config/certs/admin-key.pem \
    -h wazuh.indexer \
    -p 9200 \
    -nhnv

echo "INDEXER_INIT: Security initialization completed successfully"

# Create completion marker file
touch /mnt/host-security/.init-complete

# Keep container alive (Runtipi requirement)
# Using tail -f /dev/null keeps the container in a healthy "running" state
echo "INDEXER_INIT: Initialization complete, container will remain alive"
tail -f /dev/null
