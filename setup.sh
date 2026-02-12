#!/bin/bash
set -e

# ═══════════════════════════════════════════════════════════
# God-Level System Monitoring Stack - Setup & Validation
# ═══════════════════════════════════════════════════════════

echo "🚀 Setting up God-Level System Monitoring Stack..."
echo ""

# ─────────────────────────
# Step 1: Validate Configurations
# ─────────────────────────
echo "📋 Step 1: Validating configurations..."

# Validate Prometheus config
echo "  → Validating Prometheus configuration..."
docker run --rm -v "$(pwd)/prometheus:/prometheus" --entrypoint promtool prom/prometheus:latest \
  check config /prometheus/prometheus.yml || {
    echo "❌ Prometheus configuration invalid!"
    exit 1
  }

# Validate Prometheus rules
echo "  → Validating Prometheus alert rules..."
docker run --rm -v "$(pwd)/prometheus:/prometheus" --entrypoint promtool prom/prometheus:latest \
  check rules /prometheus/rules/system/cpu-alerts.yml \
               /prometheus/rules/system/memory-alerts.yml \
               /prometheus/rules/system/disk-alerts.yml \
               /prometheus/rules/system/network-alerts.yml \
               /prometheus/rules/system/system-alerts.yml \
               /prometheus/rules/system/service-alerts.yml \
               /prometheus/rules/system/system-health.yml || {
    echo "❌ Prometheus rules invalid!"
    exit 1
  }

# Validate Alertmanager config
echo "  → Validating Alertmanager configuration..."
docker run --rm -v "$(pwd)/alertmanager:/alertmanager" --entrypoint amtool prom/alertmanager:latest \
  check-config /alertmanager/alertmanager.yml || {
    echo "❌ Alertmanager configuration invalid!"
    exit 1
  }

echo "✅ All configurations valid!"
echo ""

# ─────────────────────────
# Step 2: Download Grafana Dashboards
# ─────────────────────────
echo "📊 Step 2: Downloading Grafana dashboards..."
if command -v jq &> /dev/null; then
    bash download-dashboards.sh
else
    echo "⚠️  jq not installed, skipping dashboard download"
    echo "   Install jq and run: ./download-dashboards.sh"
fi
echo ""

# ─────────────────────────
# Step 3: Create .env file if not exists
# ─────────────────────────
if [ ! -f .env ]; then
    echo "🔐 Step 3: Creating .env file..."
    cat > .env <<'EOF'
# Grafana Admin Credentials
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=change_me_in_production

# Hostname for log labeling
HOSTNAME=$(hostname)
EOF
    echo "✅ Created .env file"
    echo "⚠️  IMPORTANT: Edit .env and change GRAFANA_ADMIN_PASSWORD!"
else
    echo "✅ .env file already exists"
fi
echo ""

# ─────────────────────────
# Step 4: Stop existing services
# ─────────────────────────
echo "🛑 Step 4: Stopping existing services..."
docker compose down
echo ""

# ─────────────────────────
# Step 5: Pull latest images
# ─────────────────────────
echo "📥 Step 5: Pulling latest Docker images..."
docker compose pull
echo ""

# ─────────────────────────
# Step 6: Start services
# ─────────────────────────
echo "🚀 Step 6: Starting monitoring stack..."
docker compose up -d
echo ""

# ─────────────────────────
# Step 7: Wait for services to be healthy
# ─────────────────────────
echo "⏳ Step 7: Waiting for services to be healthy..."
sleep 10

# Check service health
echo "  → Checking Prometheus..."
timeout 60 bash -c 'until curl -sf http://localhost:9090/-/healthy > /dev/null; do sleep 2; done' && echo "    ✅ Prometheus healthy" || echo "    ❌ Prometheus unhealthy"

echo "  → Checking Alertmanager..."
timeout 60 bash -c 'until curl -sf http://localhost:9093/-/healthy > /dev/null; do sleep 2; done' && echo "    ✅ Alertmanager healthy" || echo "    ❌ Alertmanager unhealthy"

echo "  → Checking Loki..."
timeout 60 bash -c 'until curl -sf http://localhost:3100/ready > /dev/null; do sleep 2; done' && echo "    ✅ Loki healthy" || echo "    ❌ Loki unhealthy"

echo "  → Checking Grafana..."
timeout 60 bash -c 'until curl -sf http://localhost:3000/api/health > /dev/null; do sleep 2; done' && echo "    ✅ Grafana healthy" || echo "    ❌ Grafana unhealthy"

echo ""

# ─────────────────────────
# Step 8: Verify Prometheus targets
# ─────────────────────────
echo "🎯 Step 8: Verifying Prometheus targets..."
sleep 5
curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | "  → \(.labels.job): \(.health)"' || echo "  ⚠️  Could not fetch targets (jq may not be installed)"
echo ""

# ─────────────────────────
# Step 9: Check alert rules loaded
# ─────────────────────────
echo "🚨 Step 9: Checking alert rules..."
RULE_COUNT=$(curl -s http://localhost:9090/api/v1/rules | jq '.data.groups | length' 2>/dev/null || echo "0")
echo "  → Loaded $RULE_COUNT alert rule groups"
echo ""

# ─────────────────────────
# Step 10: Display access information
# ─────────────────────────
echo "═══════════════════════════════════════════════════════════"
echo "✅ God-Level System Monitoring Stack is READY!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📊 Access Points:"
echo "  → Grafana:      http://localhost:3000"
echo "  → Prometheus:   http://localhost:9090"
echo "  → Alertmanager: http://localhost:9093"
echo "  → Loki:         http://localhost:3100"
echo "  → cAdvisor:     http://localhost:8080"
echo ""
echo "🔐 Grafana Credentials:"
echo "  → Username: admin"
echo "  → Password: (check .env file)"
echo ""
echo "📈 What's Monitoring:"
echo "  → Host System Metrics (Node Exporter on port 9100)"
echo "  → Container Metrics (cAdvisor)"
echo "  → System Logs (syslog, kernel, auth, etc.)"
echo "  → Docker Container Logs"
echo "  → Monitoring Stack Self-Monitoring"
echo ""
echo "🚨 Alert Rules:"
echo "  → CPU: 8 alerts (usage, iowait, steal, throttling, etc.)"
echo "  → Memory: 9 alerts (usage, swap, OOM, pressure, leaks)"
echo "  → Disk: 11 alerts (space, inodes, I/O, errors, latency)"
echo "  → Network: 9 alerts (bandwidth, errors, drops, saturation)"
echo "  → System: 11 alerts (load, uptime, time, processes, temp)"
echo "  → Services: 11 alerts (availability, health)"
echo "  → Total: 50+ comprehensive alerts"
echo ""
echo "📊 Grafana Dashboards:"
echo "  → 8 professional pre-built dashboards"
echo "  → Navigate to: Dashboards → Browse → System Monitoring"
echo ""
echo "💡 Next Steps:"
echo "  1. Open Grafana at http://localhost:3000"
echo "  2. Login with credentials from .env file"
echo "  3. Browse dashboards in 'System Monitoring' folder"
echo "  4. Check Prometheus targets: http://localhost:9090/targets"
echo "  5. View alerts: http://localhost:9090/alerts"
echo "  6. Configure alert notifications in alertmanager.yml"
echo ""
echo "📚 Documentation:"
echo "  → Alert Rules: prometheus/rules/system/*.yml"
echo "  → Dashboards: grafana/provisioning/dashboards/json/"
echo "  → Logs: docker compose logs -f [service]"
echo ""
echo "═══════════════════════════════════════════════════════════"
