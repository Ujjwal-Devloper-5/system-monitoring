# 🚀 SIMPLE FIX - Get Your Dashboards Working!

## The Problem
Your Grafana dashboards show "No data" because Node Exporter is listening only on `127.0.0.1` (localhost), and Docker containers can't access it.

## The Solution (2 minutes)

### Run this ONE command:

```bash
sudo /home/ujjwal_root/system-monitoring/install-node-exporter.sh
```

This script will:
1. Reconfigure Node Exporter to listen on all interfaces
2. Restart the service  
3. Verify everything is working

### What it does:
- ✅ Stops Node Exporter
- ✅ Creates configuration to listen on `0.0.0.0:9100` (all interfaces)
- ✅ Restarts Node Exporter
- ✅ Verifies it's accessible from Docker

### After running the script:

1. **Wait 30 seconds** for Prometheus to scrape metrics
2. **Go to Grafana:** http://localhost:3000
3. **Open any dashboard** (e.g., "Node Exporter Full")
4. **See the data!** 🎉

---

## Manual Fix (if you prefer)

If you want to do it manually:

```bash
# 1. Stop Node Exporter
sudo systemctl stop prometheus-node-exporter

# 2. Create override configuration
sudo mkdir -p /etc/systemd/system/prometheus-node-exporter.service.d/
sudo tee /etc/systemd/system/prometheus-node-exporter.service.d/override.conf <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/prometheus-node-exporter --web.listen-address=":9100"
EOF

# 3. Reload and restart
sudo systemctl daemon-reload
sudo systemctl restart prometheus-node-exporter

# 4. Verify
ss -tlnp | grep 9100
# Should show: 0.0.0.0:9100 (not 127.0.0.1:9100)

# 5. Test from Docker
curl http://172.17.0.1:9100/metrics | head
```

---

## Verification

After the fix, check these:

```bash
# 1. Node Exporter is accessible
curl http://172.17.0.1:9100/metrics | head
# Should show metrics

# 2. Prometheus can scrape it
curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | select(.labels.job=="system-node") | .health'
# Should show: up

# 3. Check Grafana
# Open: http://localhost:3000
# Dashboard: Node Exporter Full
# Should show: CPU, Memory, Disk graphs with data!
```

---

## Why This Happened

Node Exporter was installed and running, but configured to listen only on `127.0.0.1:9100`. Docker containers run in a separate network namespace and cannot access `127.0.0.1` on the host. By changing it to listen on `0.0.0.0:9100` (all interfaces), Docker containers can access it via the Docker bridge IP (`172.17.0.1`).

---

## TL;DR

**Run this:**
```bash
sudo /home/ujjwal_root/system-monitoring/install-node-exporter.sh
```

**Wait 30 seconds, then refresh Grafana. Done!** ✅
