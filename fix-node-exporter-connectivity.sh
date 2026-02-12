#!/bin/bash
set -e

echo "🔧 Fixing Docker-to-Host Connectivity for Node Exporter..."
echo

# Add iptables rules to allow Docker containers to access Node Exporter
echo "📝 Adding iptables rules..."
sudo iptables -C INPUT -i docker0 -p tcp --dport 9100 -j ACCEPT 2>/dev/null || \
    sudo iptables -I INPUT -i docker0 -p tcp --dport 9100 -j ACCEPT

sudo iptables -C INPUT -s 172.17.0.0/16 -p tcp --dport 9100 -j ACCEPT 2>/dev/null || \
    sudo iptables -I INPUT -s 172.17.0.0/16 -p tcp --dport 9100 -j ACCEPT

echo "✅ Firewall rules added"
echo

# Test connectivity from Docker
echo "🧪 Testing connectivity from Prometheus container..."
if docker compose exec prometheus timeout 3 wget -q -O- http://host.docker.internal:9100/metrics > /dev/null 2>&1; then
    echo "✅ Prometheus can reach Node Exporter!"
else
    echo "❌ Prometheus still cannot reach Node Exporter"
    echo "   Checking if UFW is active..."
    if sudo ufw status | grep -q "Status: active"; then
        echo "   UFW is active, adding rule..."
        sudo ufw allow from 172.17.0.0/16 to any port 9100
        sudo ufw reload
    fi
fi

echo
echo "⏳ Waiting for Prometheus to scrape metrics..."
sleep 15

echo
echo "📊 Checking Prometheus targets..."
curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | "\(.labels.job): \(.health)"'

echo
echo "✅ Done!"
