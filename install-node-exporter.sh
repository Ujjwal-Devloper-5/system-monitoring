#!/bin/bash
set -e

# ═══════════════════════════════════════════════════════════
# Node Exporter Installation and Configuration Script
# ═══════════════════════════════════════════════════════════
# This script installs Node Exporter and configures it to be
# accessible from Docker containers
# ═══════════════════════════════════════════════════════════

echo "🔧 Installing and Configuring Node Exporter..."
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
  echo "❌ Please run as root or with sudo"
  echo "Usage: sudo ./install-node-exporter.sh"
  exit 1
fi

# Install Node Exporter via apt (easiest method)
echo "📦 Installing prometheus-node-exporter package..."
apt-get update -qq
apt-get install -y prometheus-node-exporter

# Stop the service to reconfigure
echo "⏸️  Stopping node exporter..."
systemctl stop prometheus-node-exporter

# Create override directory
mkdir -p /etc/systemd/system/prometheus-node-exporter.service.d/

# Create override configuration to listen on all interfaces
echo "⚙️  Configuring to listen on all interfaces..."
cat > /etc/systemd/system/prometheus-node-exporter.service.d/override.conf <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/prometheus-node-exporter --web.listen-address=":9100"
EOF

# Reload systemd and restart
echo "🔄 Reloading systemd and starting service..."
systemctl daemon-reload
systemctl enable prometheus-node-exporter
systemctl restart prometheus-node-exporter

# Wait for service to start
sleep 2

# Verify
echo ""
echo "✅ Verification:"
echo "─────────────────────────────────────────────────────────"

# Check service status
if systemctl is-active --quiet prometheus-node-exporter; then
  echo "✅ Service is running"
else
  echo "❌ Service is not running"
  systemctl status prometheus-node-exporter
  exit 1
fi

# Check listening address
LISTEN_ADDR=$(ss -tlnp | grep 9100 | head -1)
if echo "$LISTEN_ADDR" | grep -q "0.0.0.0:9100"; then
  echo "✅ Listening on all interfaces (0.0.0.0:9100)"
elif echo "$LISTEN_ADDR" | grep -q ":::9100"; then
  echo "✅ Listening on all interfaces (:::9100)"
else
  echo "⚠️  Listening address: $LISTEN_ADDR"
fi

# Test metrics endpoint
if curl -s http://localhost:9100/metrics | head -1 | grep -q "HELP"; then
  echo "✅ Metrics endpoint responding"
else
  echo "❌ Metrics endpoint not responding"
  exit 1
fi

# Test from Docker bridge IP
if curl -s http://172.17.0.1:9100/metrics | head -1 | grep -q "HELP"; then
  echo "✅ Accessible from Docker bridge (172.17.0.1)"
else
  echo "⚠️  Not accessible from Docker bridge - may need firewall rules"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅ Node Exporter Installation Complete!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "1. Wait 30 seconds for Prometheus to scrape metrics"
echo "2. Check Prometheus targets: http://localhost:9090/targets"
echo "3. Refresh Grafana dashboards - they should show data!"
echo ""
echo "Useful commands:"
echo "  sudo systemctl status prometheus-node-exporter"
echo "  sudo systemctl restart prometheus-node-exporter"
echo "  curl http://localhost:9100/metrics | head"
echo "═══════════════════════════════════════════════════════════"
