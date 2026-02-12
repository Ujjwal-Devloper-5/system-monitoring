#!/bin/bash
set -e

# ═══════════════════════════════════════════════════════════
# Grafana Dashboard Download Script
# Downloads professional pre-built dashboards from Grafana.com
# ═══════════════════════════════════════════════════════════

DASHBOARD_DIR="grafana/provisioning/dashboards/json"
mkdir -p "$DASHBOARD_DIR"

echo "📊 Downloading professional Grafana dashboards..."

# ─────────────────────────
# Dashboard 1: Node Exporter Full
# ID: 1860 - Most popular Node Exporter dashboard
# ─────────────────────────
echo "  → Node Exporter Full (ID: 1860)..."
curl -s https://grafana.com/api/dashboards/1860/revisions/latest/download > "$DASHBOARD_DIR/node-exporter-full.json"

# ─────────────────────────
# Dashboard 2: Node Exporter for Prometheus
# ID: 11074 - Comprehensive system metrics
# ─────────────────────────
echo "  → Node Exporter for Prometheus (ID: 11074)..."
curl -s https://grafana.com/api/dashboards/11074/revisions/latest/download > "$DASHBOARD_DIR/node-exporter-prometheus.json"

# ─────────────────────────
# Dashboard 3: Loki Dashboard
# ID: 13639 - Loki logs and metrics
# ─────────────────────────
echo "  → Loki Dashboard (ID: 13639)..."
curl -s https://grafana.com/api/dashboards/13639/revisions/latest/download > "$DASHBOARD_DIR/loki-dashboard.json"

# ─────────────────────────
# Dashboard 4: cAdvisor
# ID: 14282 - Container metrics
# ─────────────────────────
echo "  → cAdvisor Dashboard (ID: 14282)..."
curl -s https://grafana.com/api/dashboards/14282/revisions/latest/download > "$DASHBOARD_DIR/cadvisor-dashboard.json"

# ─────────────────────────
# Dashboard 5: Prometheus Stats
# ID: 3662 - Prometheus self-monitoring
# ─────────────────────────
echo "  → Prometheus Stats (ID: 3662)..."
curl -s https://grafana.com/api/dashboards/3662/revisions/latest/download > "$DASHBOARD_DIR/prometheus-stats.json"

# ─────────────────────────
# Dashboard 6: Alertmanager
# ID: 9578 - Alertmanager monitoring
# ─────────────────────────
echo "  → Alertmanager Dashboard (ID: 9578)..."
curl -s https://grafana.com/api/dashboards/9578/revisions/latest/download > "$DASHBOARD_DIR/alertmanager-dashboard.json"

# ─────────────────────────
# Dashboard 7: System Overview
# ID: 405 - System overview
# ─────────────────────────
echo "  → System Overview (ID: 405)..."
curl -s https://grafana.com/api/dashboards/405/revisions/latest/download > "$DASHBOARD_DIR/system-overview.json"

# ─────────────────────────
# Dashboard 8: Logs / App / Loki
# ID: 13186 - Log analysis
# ─────────────────────────
echo "  → Logs Dashboard (ID: 13186)..."
curl -s https://grafana.com/api/dashboards/13186/revisions/latest/download > "$DASHBOARD_DIR/logs-dashboard.json"

echo ""
echo "✅ Downloaded 8 professional dashboards to $DASHBOARD_DIR"
echo ""
echo "Dashboards:"
echo "  1. Node Exporter Full - Comprehensive host metrics"
echo "  2. Node Exporter for Prometheus - Detailed system monitoring"
echo "  3. Loki Dashboard - Log aggregation and metrics"
echo "  4. cAdvisor - Container resource monitoring"
echo "  5. Prometheus Stats - Prometheus self-monitoring"
echo "  6. Alertmanager - Alert management"
echo "  7. System Overview - High-level system view"
echo "  8. Logs Dashboard - Log analysis and search"
echo ""
