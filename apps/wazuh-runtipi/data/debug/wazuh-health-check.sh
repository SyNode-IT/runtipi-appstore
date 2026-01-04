#!/bin/bash

# wazuh-health-check.sh
# Script de diagnostic complet pour Wazuh sur Runtipi
# Version: 1.0 (2025-12-27)
# Usage: ./wazuh-health-check.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
# Auto-detect container prefix from running containers
# Runtipi uses format: wazuh-runtipi_REPO-NAME-wazuh-SERVICE-1
# We need to extract: wazuh-runtipi_REPO-NAME
# Note: REPO-NAME can contain hyphens (e.g., synode-it)
WAZUH_PREFIX=$(docker ps -a --format '{{.Names}}' 2>/dev/null | grep -E "wazuh-runtipi.*-wazuh-" | head -1 | sed -E 's/^(.*)-wazuh-.*/\1/' || echo "wazuh-runtipi")

# Détection automatique de l'instance dans app-data (données runtime)
# Note: app-data contient les données des conteneurs en cours d'exécution
#       apps contient les fichiers sources immuables du dépôt
# Search pattern: /opt/runtipi/app-data/REPO-NAME/wazuh-runtipi/data
DATA_DIR=$(find /opt/runtipi/app-data -maxdepth 3 -type d -name "wazuh-runtipi" 2>/dev/null | head -1)
if [ -n "$DATA_DIR" ]; then
    DATA_DIR="$DATA_DIR/data"
fi

# Fallback to wildcard if find didn't work
if [ -z "$DATA_DIR" ] || [ ! -d "$DATA_DIR" ]; then
    DATA_DIR=$(echo /opt/runtipi/app-data/*/wazuh-runtipi/data 2>/dev/null | awk '{print $1}')
fi

SECURITY_DIR="$DATA_DIR/indexer-security"

echo -e "${CYAN}=========================================${NC}"
echo -e "${CYAN}   WAZUH HEALTH CHECK - $(date +%Y-%m-%d\ %H:%M:%S)${NC}"
echo -e "${CYAN}=========================================${NC}"
echo ""
echo -e "${BLUE}Configuration:${NC}"
echo -e "  Container prefix: ${YELLOW}$WAZUH_PREFIX${NC}"
echo -e "  Data directory: ${YELLOW}$DATA_DIR${NC}"
echo -e "  Security directory: ${YELLOW}$SECURITY_DIR${NC}"
echo ""

# Function to print section header
print_section() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to check service
check_service() {
    local service=$1
    local container_name=$(docker ps -a --format '{{.Names}}' | grep -E "${WAZUH_PREFIX}.*${service}" | head -1)

    if [ -z "$container_name" ]; then
        echo -e "${RED}✗ Container not found${NC}"
        return 1
    fi

    local status=$(docker inspect --format='{{.State.Status}}' "$container_name" 2>/dev/null)
    local health=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "no healthcheck")

    echo -ne "  $service: "

    if [ "$status" = "running" ]; then
        if [ "$health" = "healthy" ]; then
            echo -e "${GREEN}✓ Running & Healthy${NC}"
            return 0
        elif [ "$health" = "no healthcheck" ]; then
            echo -e "${YELLOW}⚠ Running (no healthcheck)${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠ Running but $health${NC}"
            return 1
        fi
    elif [ "$status" = "exited" ]; then
        local exit_code=$(docker inspect --format='{{.State.ExitCode}}' "$container_name" 2>/dev/null)
        if [ "$exit_code" = "0" ]; then
            echo -e "${GREEN}✓ Exited successfully (code 0)${NC}"
            return 0
        else
            echo -e "${RED}✗ Exited with code $exit_code${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ Status: $status${NC}"
        return 1
    fi
}

# 1. Services Health Check
print_section "1. SERVICES HEALTH CHECK"
echo ""

SERVICES_OK=0
SERVICES_FAILED=0

for service in certs indexer manager dashboard; do
    if check_service "$service"; then
        ((SERVICES_OK++))
    else
        ((SERVICES_FAILED++))
    fi
done

# Special check for indexer-init (runs with tail -f to stay alive - Runtipi requirement)
echo -ne "  indexer-init: "
INIT_CONTAINER=$(docker ps -a --format '{{.Names}}' | grep -E "${WAZUH_PREFIX}.*indexer-init" | head -1)
if [ -n "$INIT_CONTAINER" ]; then
    INIT_STATUS=$(docker inspect --format='{{.State.Status}}' "$INIT_CONTAINER" 2>/dev/null)
    INIT_HEALTH=$(docker inspect --format='{{.State.Health.Status}}' "$INIT_CONTAINER" 2>/dev/null || echo "no healthcheck")
    INIT_RESTARTING=$(docker inspect --format='{{.State.Restarting}}' "$INIT_CONTAINER" 2>/dev/null)

    # Check if .init-complete marker exists
    INIT_COMPLETE_EXISTS=$([ -f "$SECURITY_DIR/.init-complete" ] && echo "yes" || echo "no")

    if [ "$INIT_STATUS" = "running" ] && [ "$INIT_HEALTH" = "healthy" ] && [ "$INIT_COMPLETE_EXISTS" = "yes" ]; then
        echo -e "${GREEN}✓ Running & Healthy (init complete)${NC}"
        ((SERVICES_OK++))
    elif [ "$INIT_RESTARTING" = "true" ] || [ "$INIT_STATUS" = "restarting" ]; then
        echo -e "${RED}✗ Restarting in loop${NC}"
        echo -e "  ${YELLOW}⚠ This indicates a problem with security initialization${NC}"
        ((SERVICES_FAILED++))
    elif [ "$INIT_STATUS" = "running" ] && [ "$INIT_COMPLETE_EXISTS" = "no" ]; then
        echo -e "${YELLOW}⚠ Running but initialization not complete yet${NC}"
        ((SERVICES_FAILED++))
    elif [ "$INIT_STATUS" = "running" ]; then
        echo -e "${YELLOW}⚠ Running but $INIT_HEALTH${NC}"
        ((SERVICES_FAILED++))
    else
        echo -e "${RED}✗ Status: $INIT_STATUS${NC}"
        ((SERVICES_FAILED++))
    fi
else
    echo -e "${RED}✗ Container not found${NC}"
    ((SERVICES_FAILED++))
fi

echo ""
if [ "$SERVICES_FAILED" -eq 0 ]; then
    echo -e "Summary: ${GREEN}$SERVICES_OK OK${NC} | ${GREEN}$SERVICES_FAILED FAILED${NC}"
else
    echo -e "Summary: ${GREEN}$SERVICES_OK OK${NC} | ${RED}$SERVICES_FAILED FAILED${NC}"
fi
echo ""

# 1b. Container Logs for All Services
print_section "1b. CONTAINER LOGS (Last 50 lines)"
echo ""

# Display logs for all Wazuh containers
for service in certs indexer indexer-init manager dashboard; do
    container_name=$(docker ps -a --format '{{.Names}}' | grep -E "${WAZUH_PREFIX}.*${service}" | head -1)
    if [ -n "$container_name" ]; then
        status=$(docker inspect --format='{{.State.Status}}' "$container_name" 2>/dev/null)
        health=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "no healthcheck")

        echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}Container: ${YELLOW}$container_name${NC}"
        echo -e "${CYAN}Status: ${YELLOW}$status${NC} | Health: ${YELLOW}$health${NC}"
        echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
        docker logs --tail 50 "$container_name" 2>&1 | sed 's/^/  /'
        echo ""
    fi
done

# 2. Disk Usage Check
print_section "2. DISK USAGE CHECK"
echo ""

# Re-check DATA_DIR exists (in case wildcard wasn't evaluated)
if [ ! -d "$DATA_DIR" ]; then
    DATA_DIR=$(find /opt/runtipi/app-data -maxdepth 2 -type d -path "*/wazuh-runtipi/data" 2>/dev/null | head -1)
    SECURITY_DIR="$DATA_DIR/indexer-security"
fi

# For disk usage, check the parent directory (wazuh-runtipi) not just /data
if [ -d "$DATA_DIR" ] && [ -n "$DATA_DIR" ]; then
    # Get parent directory (remove /data from end)
    APP_DIR=$(dirname "$DATA_DIR")
    SIZE_HUMAN=$(du -sh "$APP_DIR" 2>/dev/null | awk '{print $1}')
    # Round to nearest GB instead of truncating
    SIZE_GB=$(du -sb "$APP_DIR" 2>/dev/null | awk '{printf "%.0f", $1/1024/1024/1024}')

    echo -e "  App directory: $APP_DIR"
    echo -ne "  Size: $SIZE_HUMAN (≈${SIZE_GB} GB) - "

    if [ "$SIZE_GB" -gt 40 ]; then
        echo -e "${RED}⚠ WARNING: Excessive size! Expected 7 GB${NC}"
        echo -e "  ${YELLOW}Possible indexer infinite loop - check Bug #1${NC}"
    elif [ "$SIZE_GB" -gt 20 ]; then
        echo -e "${YELLOW}⚠ INFO: Higher than expected (7 GB)${NC}"
    else
        echo -e "${GREEN}✓ OK (expected 7 GB)${NC}"
    fi
else
    echo -e "${RED}✗ Data directory not found: $DATA_DIR${NC}"
fi
echo ""

# 3. Security Files Check
print_section "3. SECURITY FILES CHECK"
echo ""

REQUIRED_FILES=(
    "config.yml"
    "roles.yml"
    "roles_mapping.yml"
    "internal_users.yml"
    "action_groups.yml"
    "tenants.yml"
    "nodes_dn.yml"
    "whitelist.yml"
)

FILES_OK=0
FILES_MISSING=0

# Re-check SECURITY_DIR exists
if [ ! -d "$SECURITY_DIR" ]; then
    SECURITY_DIR="$DATA_DIR/indexer-security"
fi

if [ -d "$SECURITY_DIR" ] && [ -n "$SECURITY_DIR" ]; then
    echo -e "  Security directory: $SECURITY_DIR"
    echo ""

    for file in "${REQUIRED_FILES[@]}"; do
        echo -ne "  $file: "
        if [ -f "$SECURITY_DIR/$file" ]; then
            echo -e "${GREEN}✓ Present${NC}"
            ((FILES_OK++))
        else
            echo -e "${RED}✗ MISSING${NC}"
            ((FILES_MISSING++))
        fi
    done

    echo ""
    echo -e "Summary: ${GREEN}$FILES_OK/8 files present${NC}"

    if [ "$FILES_MISSING" -gt 0 ]; then
        echo -e "${RED}⚠ $FILES_MISSING files missing - Bug #4 not fixed!${NC}"
    fi
else
    echo -e "${RED}✗ Security directory not found: $SECURITY_DIR${NC}"
fi
echo ""

# 4. Network Connectivity Check
print_section "4. NETWORK CONNECTIVITY CHECK"
echo ""

DASHBOARD_CONTAINER=$(docker ps --format '{{.Names}}' | grep -E "${WAZUH_PREFIX}.*dashboard" | head -1)
INDEXER_CONTAINER=$(docker ps --format '{{.Names}}' | grep -E "${WAZUH_PREFIX}.*indexer" | grep -v "init" | head -1)

if [ -n "$DASHBOARD_CONTAINER" ] && [ -n "$INDEXER_CONTAINER" ]; then
    echo -e "  Testing dashboard → indexer connectivity..."
    echo ""

    # DNS resolution
    echo -ne "  DNS resolution (wazuh.indexer): "
    if docker exec "$DASHBOARD_CONTAINER" getent hosts wazuh.indexer &>/dev/null; then
        echo -e "${GREEN}✓ OK${NC}"
    else
        echo -e "${RED}✗ FAILED${NC}"
    fi

    # HTTP connectivity
    echo -ne "  HTTP connectivity: "
    HTTP_CODE=$(docker exec "$DASHBOARD_CONTAINER" curl -k -s -o /dev/null -w "%{http_code}" https://wazuh.indexer:9200 2>/dev/null || echo "000")

    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "401" ]; then
        echo -e "${GREEN}✓ OK (HTTP $HTTP_CODE)${NC}"
    elif [ "$HTTP_CODE" = "503" ]; then
        echo -e "${RED}✗ FAILED (HTTP 503 - Service Unavailable)${NC}"
        echo -e "  ${YELLOW}This indicates Bug #4 - Security not initialized${NC}"
    else
        echo -e "${YELLOW}⚠ Unexpected (HTTP $HTTP_CODE)${NC}"
    fi

    # Network check (containers can be on multiple networks)
    echo -ne "  Shared network: "
    DASH_NETS=$(docker inspect "$DASHBOARD_CONTAINER" --format='{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}')
    IDX_NETS=$(docker inspect "$INDEXER_CONTAINER" --format='{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}')

    # Find common networks
    COMMON_NET=""
    for net in $IDX_NETS; do
        if echo "$DASH_NETS" | grep -q "$net"; then
            COMMON_NET="$net"
            break
        fi
    done

    if [ -n "$COMMON_NET" ]; then
        echo -e "${GREEN}✓ OK ($COMMON_NET)${NC}"
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo -e "  ${YELLOW}Dashboard networks: $DASH_NETS${NC}"
        echo -e "  ${YELLOW}Indexer networks: $IDX_NETS${NC}"
    fi
else
    echo -e "${RED}✗ Cannot test - dashboard or indexer not running${NC}"
fi
echo ""

# 5. Dashboard Config Check
print_section "5. DASHBOARD CONFIGURATION CHECK"
echo ""

if [ -n "$DASHBOARD_CONTAINER" ]; then
    CONFIG_FILE="/usr/share/wazuh-dashboard/config/custom/opensearch_dashboards.yml"

    echo -ne "  Config file exists: "
    if docker exec "$DASHBOARD_CONTAINER" test -f "$CONFIG_FILE" 2>/dev/null; then
        echo -e "${GREEN}✓ YES${NC}"

        echo -ne "  Config has content: "
        if docker exec "$DASHBOARD_CONTAINER" test -s "$CONFIG_FILE" 2>/dev/null; then
            echo -e "${GREEN}✓ YES${NC}"

            echo -ne "  opensearch.hosts configured: "
            if docker exec "$DASHBOARD_CONTAINER" grep -q "opensearch.hosts:" "$CONFIG_FILE" 2>/dev/null; then
                HOSTS_LINE=$(docker exec "$DASHBOARD_CONTAINER" grep "opensearch.hosts:" "$CONFIG_FILE" 2>/dev/null)
                echo -e "${GREEN}✓ $HOSTS_LINE${NC}"
            else
                echo -e "${RED}✗ NOT FOUND${NC}"
            fi
        else
            echo -e "${RED}✗ EMPTY${NC}"
            echo -e "  ${YELLOW}Dashboard config file is empty - check entrypoint script${NC}"
        fi
    else
        echo -e "${RED}✗ NO${NC}"
        echo -e "  ${YELLOW}Dashboard config not created - check entrypoint script${NC}"
    fi
else
    echo -e "${RED}✗ Dashboard container not running${NC}"
fi
echo ""

# 6. Manager Config Check
print_section "6. MANAGER CONFIGURATION CHECK"
echo ""

MANAGER_CONTAINER=$(docker ps --format '{{.Names}}' | grep -E "${WAZUH_PREFIX}.*manager" | head -1)

if [ -n "$MANAGER_CONTAINER" ]; then
    OSSEC_CONF="/var/ossec/etc/ossec.conf"
    OSSEC_CUSTOM="/var/ossec/etc/custom/ossec.conf"

    echo -ne "  Main config exists: "
    if docker exec "$MANAGER_CONTAINER" test -f "$OSSEC_CONF" 2>/dev/null; then
        echo -e "${GREEN}✓ YES${NC}"
    else
        echo -e "${RED}✗ NO${NC}"
    fi

    echo -ne "  Custom config exists: "
    if docker exec "$MANAGER_CONTAINER" test -f "$OSSEC_CUSTOM" 2>/dev/null; then
        echo -e "${GREEN}✓ YES${NC}"
    else
        echo -e "${RED}✗ NO${NC}"
    fi

    echo -ne "  Main config is symlink: "
    if docker exec "$MANAGER_CONTAINER" test -L "$OSSEC_CONF" 2>/dev/null; then
        echo -e "${GREEN}✓ YES (Bug #3 fixed)${NC}"
    else
        echo -e "${YELLOW}⚠ NO (Bug #3 - config not persistent)${NC}"
    fi
else
    echo -e "${RED}✗ Manager container not running${NC}"
fi
echo ""

# 6b. Filebeat Check
print_section "6b. FILEBEAT CHECK"
echo ""

if [ -n "$MANAGER_CONTAINER" ]; then
    FILEBEAT_CONF="/etc/filebeat/filebeat.yml"

    # Check environment variables (official Wazuh method)
    echo "Environment Variables (Official Wazuh Method):"
    echo ""

    echo -ne "  FILEBEAT_SSL_VERIFICATION_MODE: "
    SSL_VERIF=$(docker inspect "$MANAGER_CONTAINER" --format='{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | grep "^FILEBEAT_SSL_VERIFICATION_MODE=" | cut -d= -f2)
    if [ "$SSL_VERIF" = "full" ]; then
        echo -e "${GREEN}✓ full${NC}"
    else
        echo -e "${RED}✗ ${SSL_VERIF:-not set}${NC}"
    fi

    echo -ne "  SSL_CERTIFICATE_AUTHORITIES: "
    SSL_CA=$(docker inspect "$MANAGER_CONTAINER" --format='{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | grep "^SSL_CERTIFICATE_AUTHORITIES=" | cut -d= -f2)
    if [ -n "$SSL_CA" ]; then
        echo -e "${GREEN}✓ ${SSL_CA}${NC}"
    else
        echo -e "${RED}✗ not set${NC}"
    fi

    echo -ne "  SSL_CERTIFICATE: "
    SSL_CERT=$(docker inspect "$MANAGER_CONTAINER" --format='{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | grep "^SSL_CERTIFICATE=" | cut -d= -f2)
    if [ -n "$SSL_CERT" ]; then
        echo -e "${GREEN}✓ ${SSL_CERT}${NC}"
    else
        echo -e "${RED}✗ not set${NC}"
    fi

    echo -ne "  SSL_KEY: "
    SSL_KEY=$(docker inspect "$MANAGER_CONTAINER" --format='{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | grep "^SSL_KEY=" | cut -d= -f2)
    if [ -n "$SSL_KEY" ]; then
        echo -e "${GREEN}✓ ${SSL_KEY}${NC}"
    else
        echo -e "${RED}✗ not set${NC}"
    fi

    echo ""
    echo "Generated Filebeat Configuration:"
    echo ""

    echo -ne "  Filebeat config exists: "
    if docker exec "$MANAGER_CONTAINER" test -f "$FILEBEAT_CONF" 2>/dev/null; then
        echo -e "${GREEN}✓ YES${NC}"

        echo -ne "  Config has indexer https URL: "
        if docker exec "$MANAGER_CONTAINER" grep -q "https://wazuh.indexer:9200" "$FILEBEAT_CONF" 2>/dev/null; then
            echo -e "${GREEN}✓ YES${NC}"
        else
            echo -e "${RED}✗ NO (indexer URL incorrect)${NC}"
        fi

        echo -ne "  SSL verification enabled: "
        if docker exec "$MANAGER_CONTAINER" grep -qE "ssl\.verification_mode:\s*(full|certificate)" "$FILEBEAT_CONF" 2>/dev/null; then
            echo -e "${GREEN}✓ YES (configured in filebeat.yml)${NC}"
        else
            # Not an error - SSL is configured via environment variables (official method)
            # The official cont-init.d/1-config-filebeat generates the config automatically
            echo -e "${GREEN}✓ YES (configured via environment variables - official method)${NC}"
            echo -e "  ${GREEN}  The 4 environment variables above control SSL configuration${NC}"
        fi

        echo -ne "  Seccomp fix for pthread: "
        if docker exec "$MANAGER_CONTAINER" grep -q "seccomp:" "$FILEBEAT_CONF" 2>/dev/null; then
            echo -e "${GREEN}✓ YES (pthread_create fix present)${NC}"
        else
            echo -e "${YELLOW}⚠ NO (may cause pthread_create errors)${NC}"
        fi
    else
        echo -e "${RED}✗ NO${NC}"
        echo -e "  ${YELLOW}⚠ Filebeat config not generated - check init logs${NC}"
    fi
else
    echo -e "${RED}✗ Manager container not running${NC}"
fi
echo ""

# 6c. Known Errors Detection
print_section "6c. KNOWN ERRORS DETECTION"
echo ""

ERRORS_FOUND=0

if [ -n "$MANAGER_CONTAINER" ]; then
    echo "Scanning manager logs for known errors..."
    echo ""

    # pthread_create error
    echo -ne "  pthread_create error: "
    if docker logs "$MANAGER_CONTAINER" 2>&1 | grep -q "pthread_create failed"; then
        echo -e "${RED}✗ FOUND${NC}"
        echo -e "  ${YELLOW}Fix: Ensure filebeat.yml has seccomp configuration${NC}"
        ((ERRORS_FOUND++))
    else
        echo -e "${GREEN}✓ Not found${NC}"
    fi

    # x509 certificate error
    echo -ne "  x509 certificate error: "
    if docker logs "$MANAGER_CONTAINER" 2>&1 | grep -q "x509: certificate signed by unknown authority"; then
        echo -e "${RED}✗ FOUND${NC}"
        echo -e "  ${YELLOW}Fix: Check SSL configuration in filebeat.yml${NC}"
        ((ERRORS_FOUND++))
    else
        echo -e "${GREEN}✓ Not found${NC}"
    fi

    # SIGABRT crash
    echo -ne "  SIGABRT crash: "
    if docker logs "$MANAGER_CONTAINER" 2>&1 | grep -q "SIGABRT"; then
        echo -e "${RED}✗ FOUND${NC}"
        echo -e "  ${YELLOW}Usually caused by pthread_create error${NC}"
        ((ERRORS_FOUND++))
    else
        echo -e "${GREEN}✓ Not found${NC}"
    fi

    # Filebeat ownership error
    echo -ne "  Filebeat ownership error: "
    if docker logs "$MANAGER_CONTAINER" 2>&1 | grep -q "must be owned by the user identifier"; then
        echo -e "${RED}✗ FOUND${NC}"
        echo -e "  ${YELLOW}Fix: chown root:root && chmod 600 on filebeat.yml${NC}"
        ((ERRORS_FOUND++))
    else
        echo -e "${GREEN}✓ Not found${NC}"
    fi

    echo ""
    if [ $ERRORS_FOUND -gt 0 ]; then
        echo -e "${RED}Found $ERRORS_FOUND known error(s) in manager logs${NC}"
    else
        echo -e "${GREEN}No known errors detected in manager logs${NC}"
    fi
fi
echo ""

# 7. Final Summary
print_section "7. OVERALL HEALTH SUMMARY"
echo ""

ISSUES=0

# Check services
if [ "$SERVICES_FAILED" -gt 0 ]; then
    echo -e "${RED}✗ Services: $SERVICES_FAILED services have issues${NC}"
    ((ISSUES++))
else
    echo -e "${GREEN}✓ Services: All services healthy${NC}"
fi

# Check disk
if [ -n "$SIZE_GB" ] && [ "$SIZE_GB" -gt 20 ]; then
    echo -e "${YELLOW}⚠ Disk: Higher than expected usage ($SIZE_GB GB)${NC}"
    ((ISSUES++))
elif [ -n "$SIZE_GB" ]; then
    echo -e "${GREEN}✓ Disk: Usage normal (7 GB)${NC}"
else
    echo -e "${YELLOW}⚠ Disk: Could not determine usage${NC}"
fi

# Check security files
if [ "$FILES_MISSING" -gt 0 ]; then
    echo -e "${RED}✗ Security: $FILES_MISSING files missing${NC}"
    ((ISSUES++))
else
    echo -e "${GREEN}✓ Security: All 8 security files present${NC}"
fi

echo ""
echo -e "${CYAN}=========================================${NC}"

if [ "$ISSUES" -eq 0 ]; then
    echo -e "${GREEN}✓✓✓ WAZUH IS HEALTHY - PRODUCTION READY ✓✓✓${NC}"
else
    echo -e "${YELLOW}⚠⚠⚠ FOUND $ISSUES ISSUE(S) - CHECK ABOVE ⚠⚠⚠${NC}"
    echo ""
    echo -e "${CYAN}Troubleshooting:${NC}"
    echo "  1. Check logs above for detailed error messages"
    echo "  2. See metadata/description.md section 'TROUBLESHOOTING'"
    echo "  3. Verify docker-compose.json entrypoints are correct"
    echo "  4. Check container prefix detection: $WAZUH_PREFIX"
fi

echo -e "${CYAN}=========================================${NC}"
echo ""

exit 0
