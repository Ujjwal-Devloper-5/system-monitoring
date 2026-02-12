# 🔧 Node Exporter Fix - Quick Solution

## Problem
Node Exporter is running but listening only on `127.0.0.1:9100` (localhost), which Docker containers cannot access. This is why all Grafana dashboards show "No data".

## Quick Fix (Recommended)

### Option 1: Reconfigure Existing Node Exporter

If Node Exporter is running as a systemd service:

```bash
# Stop the current instance
sudo systemctl stop node_exporter
# Or if running manually:
pkill node_exporter

# Find the systemd service file
sudo find /etc/systemd /lib/systemd -name "node_exporter.service" 2>/dev/null

# Edit the service file to bind to all interfaces
sudo nano /etc/systemd/system/node_exporter.service
# Or:
sudo nano /lib/systemd/system/node_exporter.service

# Change the ExecStart line to:
ExecStart=/usr/local/bin/node_exporter --web.listen-address=":9100"
# Or:
ExecStart=/usr/local/bin/node_exporter --web.listen-address="0.0.0.0:9100"

# Reload and restart
sudo systemctl daemon-reload
sudo systemctl restart node_exporter
sudo systemctl status node_exporter
```

### Option 2: Run Node Exporter Manually (Quick Test)

```bash
# Stop any existing instance
pkill node_exporter

# Run on all interfaces
/usr/local/bin/node_exporter --web.listen-address=":9100" &

# Or if node_exporter is in your PATH:
node_exporter --web.listen-address=":9100" &

# Verify it's listening on all interfaces
ss -tlnp | grep 9100
# Should show: 0.0.0.0:9100 (not 127.0.0.1:9100)
```

### Option 3: Use Docker Host Network Mode (Alternative)

Edit `docker-compose.yml` and change Prometheus to use host network:

```yaml
prometheus:
  # ... existing config ...
  network_mode: "host"
  # Remove the ports section as host mode uses host's network directly
```

Then restart: `docker compose restart prometheus`

## Verification

After applying the fix:

```bash
# 1. Check Node Exporter is listening on all interfaces
ss -tlnp | grep 9100
# Should show: 0.0.0.0:9100 or :::9100

# 2. Test from Docker container
docker compose exec prometheus wget -O- http://172.17.0.1:9100/metrics | head

# 3. Check Prometheus targets
curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | select(.labels.job=="system-node") | .health'
# Should show: up

# 4. Wait 30 seconds, then refresh Grafana dashboard
# Dashboards should now show data!
```

## Current Status

- ✅ Node Exporter is installed and running
- ✅ Prometheus configuration is correct (172.17.0.1:9100)
- ❌ Node Exporter is listening on 127.0.0.1 only (needs fix)
- ❌ Dashboards showing "No data" (will fix after Node Exporter reconfiguration)

## Next Steps

1. Apply one of the fixes above
2. Verify Node Exporter is accessible: `curl http://172.17.0.1:9100/metrics`
3. Wait 30 seconds for Prometheus to scrape
4. Refresh Grafana dashboards - they should show data!
