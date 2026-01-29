#!/bin/bash
set -e

echo "MANAGER_INIT: Starting manager initialization..."

# ============================================================================
# AGENT GROUPS (SHARED) INITIALIZATION
# ============================================================================
# When /var/ossec/etc/shared is mounted as an empty volume, the default files
# are missing. We need to create them for group management to work.

SHARED_DIR="/var/ossec/etc/shared"
TEMPLATE_FILE="$SHARED_DIR/agent-template.conf"
DEFAULT_DIR="$SHARED_DIR/default"
DEFAULT_AGENT_CONF="$DEFAULT_DIR/agent.conf"

echo "MANAGER_INIT: Checking agent groups shared directory..."

# Create default group directory if it doesn't exist
if [ ! -d "$DEFAULT_DIR" ]; then
    echo "MANAGER_INIT: Creating default group directory..."
    mkdir -p "$DEFAULT_DIR"
fi

# Create agent-template.conf if it doesn't exist (required for creating new groups)
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "MANAGER_INIT: Creating agent-template.conf..."
    cat > "$TEMPLATE_FILE" << 'TEMPLATE_EOF'
<!-- Agent configuration template -->
<!-- This file is used as a template when creating new groups -->
<agent_config>
</agent_config>
TEMPLATE_EOF
fi

# Create default/agent.conf if it doesn't exist
if [ ! -f "$DEFAULT_AGENT_CONF" ]; then
    echo "MANAGER_INIT: Creating default/agent.conf..."
    cat > "$DEFAULT_AGENT_CONF" << 'AGENT_EOF'
<!-- Default agent configuration -->
<agent_config>
</agent_config>
AGENT_EOF
fi

# Set correct ownership (ossec:ossec = 1000:1000 in container)
chown -R wazuh:wazuh "$SHARED_DIR" 2>/dev/null || chown -R 1000:1000 "$SHARED_DIR" 2>/dev/null || true

echo "MANAGER_INIT: Agent groups directory ready"

# ============================================================================
# OSSEC.CONF CONFIGURATION
# ============================================================================
# The official Wazuh /init script creates ossec.conf during initialization.
# We use a watchdog to copy it to custom storage for persistence after /init.

OSSEC_CUSTOM="/var/ossec/etc/custom/ossec.conf"
OSSEC_DEFAULT="/var/ossec/etc/ossec.conf"

# Create custom directory if it doesn't exist
mkdir -p /var/ossec/etc/custom

# NOTE: Filebeat SSL configuration is now handled via environment variables:
#   - FILEBEAT_SSL_VERIFICATION_MODE=full
#   - SSL_CERTIFICATE_AUTHORITIES=/var/ossec/etc/certs/root-ca.pem
#   - SSL_CERTIFICATE=/var/ossec/etc/certs/server.pem
#   - SSL_KEY=/var/ossec/etc/certs/server-key.pem
# The official cont-init.d/1-config-filebeat script will generate the correct
# configuration automatically. No manual filebeat.yml management needed!

# ============================================================================
# POST-INIT WATCHDOG
# ============================================================================
# The Wazuh /init script creates ossec.conf during initialization.
# This watchdog waits for init completion, then makes ossec.conf persistent.

(
    echo "WATCHDOG: Waiting for Wazuh services to be fully started..."

    # Wait for wazuh-db to be running (not just starting)
    # wazuh-db is one of the last services to start and needs a valid ossec.conf
    TIMEOUT=180
    ELAPSED=0
    while [ $ELAPSED -lt $TIMEOUT ]; do
        # Check if wazuh-db process is running
        if pgrep -x "wazuh-db" > /dev/null 2>&1; then
            echo "WATCHDOG: wazuh-db is running, waiting additional 5s for stability..."
            sleep 5
            break
        fi
        sleep 2
        ELAPSED=$((ELAPSED + 2))

        if [ $((ELAPSED % 20)) -eq 0 ]; then
            echo "WATCHDOG: Still waiting for wazuh-db to start (${ELAPSED}s elapsed)..."
        fi
    done

    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo "WATCHDOG: WARNING - Timeout waiting for wazuh-db startup!"
        echo "WATCHDOG: Will proceed anyway, but persistence may fail"
    fi

    # Now make ossec.conf persistent
    if [ -f "$OSSEC_DEFAULT" ] && [ ! -L "$OSSEC_DEFAULT" ]; then
        echo "WATCHDOG: Making ossec.conf persistent..."

        # If custom file doesn't exist or is empty, copy current to custom
        if [ ! -s "$OSSEC_CUSTOM" ]; then
            echo "WATCHDOG: Backing up current ossec.conf to custom storage..."
            cp "$OSSEC_DEFAULT" "$OSSEC_CUSTOM"
        fi

        # Create symlink for persistence
        echo "WATCHDOG: Creating symlink /var/ossec/etc/ossec.conf -> custom/ossec.conf"
        rm -f "$OSSEC_DEFAULT"
        ln -s "$OSSEC_CUSTOM" "$OSSEC_DEFAULT"

        # Verify symlink was created
        if [ -L "$OSSEC_DEFAULT" ]; then
            echo "WATCHDOG: ✓ ossec.conf is now persistent (symlink verified)"
        else
            echo "WATCHDOG: ✗ ERROR - Failed to create symlink!"
        fi
    else
        echo "WATCHDOG: ossec.conf already persistent (symlink exists)"
    fi

    echo "WATCHDOG: Initialization complete, entering monitoring mode"

    # Keep watchdog alive
    while true; do
        sleep 3600
    done
) &

# ============================================================================
# START WAZUH
# ============================================================================
echo "MANAGER_INIT: Configuration complete, starting Wazuh..."

# Execute the original Wazuh entrypoint
# The cont-init.d/1-config-filebeat script will automatically configure Filebeat
# using the SSL environment variables we defined in docker-compose.json
exec /init
