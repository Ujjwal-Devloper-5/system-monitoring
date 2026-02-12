# Node Exporter Connectivity Fix

## Issue
Node Exporter is running on the host but Prometheus cannot scrape it because Node Exporter is bound to `127.0.0.1:9100` (localhost only), which is not accessible from Docker containers.

## Solution Options

### Option 1: Restart Node Exporter to Bind to All Interfaces (Recommended)

If you're running Node Exporter as a systemd service:

```bash
# Edit the service file
sudo systemctl edit --full node_exporter

# Find the ExecStart line and ensure it includes:
# ExecStart=/usr/local/bin/node_exporter --web.listen-address=":9100"
# OR
# ExecStart=/usr/local/bin/node_exporter --web.listen-address="0.0.0.0:9100"

# Save and restart
sudo systemctl daemon-reload
sudo systemctl restart node_exporter
sudo systemctl status node_exporter
```

If you're running Node Exporter manually:

```bash
# Stop the current instance
pkill node_exporter

# Start with binding to all interfaces
node_exporter --web.listen-address=":9100" &
```

### Option 2: Use Host Network Mode for Prometheus (Alternative)

Modify `docker-compose.yml`:

```yaml
  prometheus:
    # ... existing config ...
    network_mode: "host"  # Add this line
    # Remove the 'networks' and 'ports' sections when using host mode
```

**Note:** This makes Prometheus use the host's network directly, so it can access localhost:9100.

### Option 3: Run Node Exporter in Docker (Not Recommended)

While possible, running Node Exporter in a container limits its ability to monitor the host system accurately.

## Verification

After applying Option 1 or 2, verify connectivity:

```bash
# From host
curl http://localhost:9100/metrics | head

# Check Prometheus targets
curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | select(.labels.job=="system-node") | {job: .labels.job, health: .health}'
```

You should see `"health": "up"` for the system-node target.

## Current Status

- ✅ All monitoring stack services are healthy
- ✅ 68 alert rules loaded successfully
- ✅ 8 Grafana dashboards provisioned
- ✅ Log collection operational
- ⚠️  Node Exporter connectivity needs to be fixed (choose one of the options above)

Once Node Exporter connectivity is fixed, all 6 Prometheus targets will be UP and the monitoring stack will be fully operational!
