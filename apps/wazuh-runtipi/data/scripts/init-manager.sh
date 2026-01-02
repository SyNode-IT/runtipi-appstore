#!/bin/bash
set -e

echo "MANAGER_INIT: Starting manager initialization..."

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
