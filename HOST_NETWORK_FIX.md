# 🔧 Final Fix: Use Host Network Mode for Prometheus

## The Problem

Node Exporter is running and listening on all interfaces (`*:9100`), but Docker containers cannot connect to it due to network isolation/firewall rules.

## The Solution

Use Docker's **host network mode** for Prometheus. This makes Prometheus use the host's network directly, bypassing Docker's network isolation.

## Apply the Fix

### Step 1: Edit docker-compose.yml

```bash
cd /home/ujjwal_root/system-monitoring
```

Add `network_mode: "host"` to the Prometheus service and comment out the ports section:

```yaml
prometheus:
  image: prom/prometheus:latest
  container_name: prometheus
  network_mode: "host"  # ADD THIS LINE
  command:
    - --config.file=/prometheus/prometheus.yml
    - --storage.tsdb.path=/prometheus
    - --storage.tsdb.retention.time=15d
    - --web.enable-lifecycle
    - --web.enable-admin-api
  volumes:
    - type: bind
      source: ./prometheus/prometheus.yml
      target: /prometheus/prometheus.yml
      read_only: true
    - type: bind
      source: ./prometheus/rules
      target: /prometheus/rules
      read_only: true
    - prometheus-data:/prometheus
  # Comment out or remove the ports section since host mode uses host network
  # ports:
  #   - "127.0.0.1:9090:9090"
  restart: unless-stopped
  # Remove or comment out the networks section
  # networks:
  #   - observability
```

### Step 2: Update prometheus.yml

Change Node Exporter target to use `localhost`:

```yaml
- job_name: "system-node"
  static_configs:
    - targets: ["localhost:9100"]  # Change from 172.17.0.1:9100
      labels:
        domain: system
        layer: host
        component: node-exporter
```

### Step 3: Restart Prometheus

```bash
docker compose up -d prometheus
```

### Step 4: Verify

```bash
# Wait 10 seconds
sleep 10

# Check targets
curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | "\(.labels.job): \(.health)"'

# Should show:
# system-node: up  ✅
```

## Why This Works

- **Host network mode** makes Prometheus run in the host's network namespace
- Prometheus can now access `localhost:9100` directly (same as if it was running on the host)
- No firewall/routing issues between Docker and host

## Trade-offs

- ✅ **Pro:** Simple, works immediately, no firewall configuration needed
- ✅ **Pro:** Better performance (no network translation overhead)
- ⚠️ **Con:** Prometheus uses host's network directly (less isolation)
- ⚠️ **Con:** Port 9090 must be available on host

## Alternative: Fix Firewall (More Complex)

If you prefer to keep Docker network isolation:

```bash
# Allow Docker containers to access host port 9100
sudo iptables -I INPUT -p tcp --dport 9100 -j ACCEPT
sudo iptables -I INPUT -i docker0 -p tcp --dport 9100 -j ACCEPT

# Make it persistent
sudo apt-get install iptables-persistent
sudo netfilter-persistent save
```

But **host network mode is simpler and recommended** for this use case.
