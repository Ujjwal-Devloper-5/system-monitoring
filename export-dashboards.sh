#!/bin/bash
set -e

# ═══════════════════════════════════════════════════════════
# Grafana Dashboard Export Script
# ═══════════════════════════════════════════════════════════
# This script exports all Grafana dashboards to JSON files
# Useful for version control and backup of dashboard changes
# ═══════════════════════════════════════════════════════════

GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000}"
GRAFANA_USER="${GRAFANA_USER:-admin}"
GRAFANA_PASSWORD="${GRAFANA_PASSWORD:-}"
EXPORT_DIR="grafana/provisioning/dashboards/json/exported"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load password from .env if not provided
if [ -z "$GRAFANA_PASSWORD" ] && [ -f "$PROJECT_DIR/.env" ]; then
  GRAFANA_PASSWORD=$(grep GRAFANA_ADMIN_PASSWORD "$PROJECT_DIR/.env" | cut -d'=' -f2)
fi

if [ -z "$GRAFANA_PASSWORD" ]; then
  echo "❌ Error: GRAFANA_PASSWORD not set"
  echo "Usage: GRAFANA_PASSWORD=your_password $0"
  echo "   or: Set GRAFANA_ADMIN_PASSWORD in .env file"
  exit 1
fi

echo "📊 Exporting Grafana dashboards..."
echo "🔗 Grafana URL: $GRAFANA_URL"
echo ""

# Create export directory
mkdir -p "$PROJECT_DIR/$EXPORT_DIR"

# Check if Grafana is accessible
if ! curl -sf "$GRAFANA_URL/api/health" > /dev/null; then
  echo "❌ Error: Cannot connect to Grafana at $GRAFANA_URL"
  echo "   Make sure Grafana is running: docker compose ps grafana"
  exit 1
fi

# Get all dashboards
echo "🔍 Discovering dashboards..."
DASHBOARDS=$(curl -sf -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
  "$GRAFANA_URL/api/search?type=dash-db" | jq -r '.[] | "\(.uid)|\(.title)"')

if [ -z "$DASHBOARDS" ]; then
  echo "⚠️  No dashboards found"
  exit 0
fi

DASHBOARD_COUNT=$(echo "$DASHBOARDS" | wc -l)
echo "📈 Found $DASHBOARD_COUNT dashboard(s)"
echo ""

# Export each dashboard
EXPORTED=0
FAILED=0

while IFS='|' read -r uid title; do
  # Sanitize filename
  filename=$(echo "$title" | tr '/' '-' | tr ' ' '_' | tr -cd '[:alnum:]_-').json
  
  echo "  → Exporting: $title"
  echo "    UID: $uid"
  echo "    File: $filename"
  
  # Export dashboard
  if curl -sf -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
    "$GRAFANA_URL/api/dashboards/uid/$uid" | \
    jq '.dashboard' > "$PROJECT_DIR/$EXPORT_DIR/$filename"; then
    
    # Add metadata comment
    SIZE=$(du -h "$PROJECT_DIR/$EXPORT_DIR/$filename" | cut -f1)
    echo "    ✓ Exported ($SIZE)"
    ((EXPORTED++))
  else
    echo "    ✗ Failed to export"
    ((FAILED++))
  fi
  echo ""
done <<< "$DASHBOARDS"

# Summary
echo "═══════════════════════════════════════════════════════════"
echo "Export Summary"
echo "═══════════════════════════════════════════════════════════"
echo "Total Dashboards: $DASHBOARD_COUNT"
echo "Successfully Exported: $EXPORTED"
echo "Failed: $FAILED"
echo "Export Directory: $PROJECT_DIR/$EXPORT_DIR"
echo ""

if [ $EXPORTED -gt 0 ]; then
  echo "📁 Exported files:"
  ls -lh "$PROJECT_DIR/$EXPORT_DIR"
  echo ""
  echo "💡 Tip: Commit these files to version control to track dashboard changes"
fi

echo "═══════════════════════════════════════════════════════════"

# ═══════════════════════════════════════════════════════════
# USAGE EXAMPLES
# ═══════════════════════════════════════════════════════════
# Export with custom credentials:
#   GRAFANA_PASSWORD=mypassword ./export-dashboards.sh
#
# Export from remote Grafana:
#   GRAFANA_URL=https://grafana.example.com GRAFANA_PASSWORD=mypassword ./export-dashboards.sh
#
# Schedule regular exports (crontab):
#   0 3 * * * cd /path/to/monitoring && ./export-dashboards.sh >> /var/log/dashboard-export.log 2>&1
# ═══════════════════════════════════════════════════════════
