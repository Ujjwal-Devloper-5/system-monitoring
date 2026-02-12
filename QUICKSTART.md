# 🚀 Quick Start Guide - System Monitoring Stack

## 📋 Table of Contents
1. [Starting the Stack](#starting-the-stack)
2. [Accessing the Dashboards](#accessing-the-dashboards)
3. [Viewing Metrics](#viewing-metrics)
4. [Viewing Logs](#viewing-logs)
5. [Understanding Alerts](#understanding-alerts)
6. [Common Tasks](#common-tasks)

---

## 🎯 Starting the Stack

### Step 1: Start All Services

```bash
cd /home/ujjwal_root/system-monitoring

# Start all services
docker compose up -d

# Wait for services to become healthy (30-60 seconds)
docker compose ps
```

**Expected Output:**
```
NAME           STATUS
prometheus     Up (healthy)
alertmanager   Up (healthy)
grafana        Up (healthy)
loki           Up (healthy)
promtail       Up
cadvisor       Up (healthy)
```

### Step 2: Verify Services are Running

```bash
# Check all services are healthy
curl http://localhost:9090/-/healthy  # Prometheus
curl http://localhost:9093/-/healthy  # Alertmanager
curl http://localhost:3100/ready      # Loki
curl http://localhost:3000/api/health # Grafana
```

All should return `OK` or `{"status":"ok"}`.

---

## 🖥️ Accessing the Dashboards

### Grafana (Main Dashboard Interface)

**URL:** http://localhost:3000

**Credentials:**
- **Username:** `admin`
- **Password:** `M8xK9pL2nQ7vR4wT6yU3zA5bC1dE0fG8hJ9kM2nP5qS7tV4wX6yZ3`

**What you'll see:**
1. Login page → Enter credentials
2. Home dashboard → Click "Dashboards" in left menu
3. "System Monitoring" folder → Contains 8 pre-configured dashboards

### Prometheus (Metrics Database)

**URL:** http://localhost:9090

**What you'll see:**
- Query interface for raw metrics
- Targets status (which services are being monitored)
- Alert rules and their current state
- Configuration and service discovery

### Alertmanager (Alert Management)

**URL:** http://localhost:9093

**What you'll see:**
- Active alerts
- Silenced alerts
- Alert grouping and routing
- Notification status

---

## 📊 Viewing Metrics

### Using Grafana Dashboards (Recommended)

#### 1. **Node Exporter Full Dashboard**
   - **Path:** Dashboards → System Monitoring → Node Exporter Full
   - **Shows:** CPU, Memory, Disk, Network for your system
   - **Refresh:** Auto-refreshes every 30s

   **Key Panels:**
   - CPU Usage (top left)
   - Memory Usage (top right)
   - Disk I/O (middle)
   - Network Traffic (bottom)

#### 2. **Docker Container Monitoring (cAdvisor)**
   - **Path:** Dashboards → System Monitoring → Docker Container Monitoring
   - **Shows:** All running containers' resource usage
   
   **Key Metrics:**
   - Container CPU usage
   - Container memory usage
   - Container network I/O
   - Container filesystem usage

#### 3. **Prometheus 2.0 Stats**
   - **Path:** Dashboards → System Monitoring → Prometheus 2.0 Stats
   - **Shows:** Prometheus internal metrics
   
   **Key Metrics:**
   - Number of time series
   - Scrape duration
   - Query performance
   - Storage usage

#### 4. **Loki Dashboard**
   - **Path:** Dashboards → System Monitoring → Loki Dashboard
   - **Shows:** Log aggregation system metrics
   
   **Key Metrics:**
   - Ingestion rate
   - Query performance
   - Storage usage

### Using Prometheus Directly

1. **Go to:** http://localhost:9090
2. **Click:** "Graph" tab
3. **Enter a query:**
   ```promql
   # CPU usage percentage
   100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
   
   # Memory usage percentage
   (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
   
   # Disk usage percentage
   (1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100
   ```
4. **Click:** "Execute"
5. **View:** Graph or Table view

---

## 📝 Viewing Logs

### Using Grafana Explore (Recommended)

#### Step-by-Step:

1. **Open Grafana:** http://localhost:3000
2. **Click:** Compass icon (🧭) in left sidebar → "Explore"
3. **Select:** "Loki" from dropdown (top)
4. **Choose log source:**

   **Option A: Use Log Browser**
   - Click "Log browser" button
   - Select a label (e.g., `job`)
   - Select a value (e.g., `syslog`, `docker`, `auth`)
   - Click "Show logs"

   **Option B: Write LogQL Query**
   ```logql
   # All system logs
   {job="syslog"}
   
   # Docker container logs
   {job="docker"}
   
   # Authentication logs
   {job="auth"}
   
   # Kernel logs
   {job="kernel"}
   
   # Filter by text
   {job="syslog"} |= "error"
   
   # Filter by specific container
   {job="docker", container_name="prometheus"}
   ```

5. **Time Range:** Adjust in top-right (Last 1 hour, Last 6 hours, etc.)
6. **Live Tail:** Click "Live" button for real-time logs

### Log Categories Available

| Job Name | Description | Example Query |
|----------|-------------|---------------|
| `syslog` | System logs | `{job="syslog"}` |
| `kernel` | Kernel messages | `{job="kernel"}` |
| `auth` | Authentication logs | `{job="auth"}` |
| `docker` | Container logs | `{job="docker"}` |
| `cron` | Cron job logs | `{job="cron"}` |
| `daemon` | System daemon logs | `{job="daemon"}` |

### Advanced Log Queries

```logql
# Errors in last hour
{job="syslog"} |= "error" or "Error" or "ERROR"

# Failed SSH attempts
{job="auth"} |= "Failed password"

# Docker container restarts
{job="docker"} |= "restart"

# High severity kernel messages
{job="kernel"} |~ "critical|alert|emergency"

# Logs from specific container
{job="docker", container_name="prometheus"} |= "error"
```

---

## 🚨 Understanding Alerts

### Viewing Active Alerts

#### In Grafana:
1. **Go to:** http://localhost:3000
2. **Click:** Bell icon (🔔) in left sidebar → "Alert rules"
3. **See:** All 68 configured alert rules grouped by category

#### In Prometheus:
1. **Go to:** http://localhost:9090
2. **Click:** "Alerts" tab
3. **See:** Current alert states (Inactive, Pending, Firing)

#### In Alertmanager:
1. **Go to:** http://localhost:9093
2. **See:** Active firing alerts
3. **Actions:** Silence alerts, view alert details

### Alert Categories

Your stack has **68 alert rules** across these categories:

1. **CPU Alerts (8 rules)**
   - High CPU usage (>80%)
   - Critical CPU usage (>95%)
   - High I/O wait
   - CPU throttling
   - Core imbalance

2. **Memory Alerts (9 rules)**
   - High memory usage (>80%)
   - Critical memory usage (>95%)
   - Swap usage
   - OOM kills
   - Memory leaks

3. **Disk Alerts (12 rules)**
   - Disk space warnings
   - Disk almost full
   - High I/O saturation
   - Disk errors
   - Read-only filesystem

4. **Network Alerts (10 rules)**
   - High bandwidth usage
   - Network errors
   - Packet drops
   - Interface down
   - TCP connection exhaustion

5. **System Alerts (13 rules)**
   - High load average
   - System reboot
   - Clock skew
   - Zombie processes
   - File descriptor exhaustion

6. **Service Alerts (12 rules)**
   - Prometheus down
   - Grafana down
   - Loki down
   - Alertmanager down
   - Scrape failures

7. **System Health (4 rules)**
   - Overall system health
   - Component health
   - Service availability

### Alert Severity Levels

- 🔵 **Info:** Informational, no action needed
- 🟡 **Warning:** Attention needed, not urgent
- 🔴 **Critical:** Immediate action required

---

## 🎨 Dashboard Setup Guide

### Pre-configured Dashboards

Your stack comes with **8 professional dashboards** already set up:

1. **Node Exporter Full** (ID: 1860)
   - Complete system metrics
   - CPU, Memory, Disk, Network
   - **Use for:** Overall system health

2. **Node Exporter Server Metrics** (ID: 405)
   - Simplified server view
   - **Use for:** Quick system overview

3. **Docker Container Monitoring** (ID: 193)
   - All container metrics
   - **Use for:** Container resource usage

4. **Loki Dashboard** (ID: 13639)
   - Log system metrics
   - **Use for:** Log ingestion monitoring

5. **Prometheus 2.0 Stats** (ID: 3662)
   - Prometheus internals
   - **Use for:** Monitoring the monitor

6. **Alertmanager Dashboard** (ID: 9578)
   - Alert statistics
   - **Use for:** Alert management

7. **System Overview** (ID: 11074)
   - High-level system view
   - **Use for:** Executive summary

8. **Logs Dashboard** (ID: 13186)
   - Log analysis
   - **Use for:** Log exploration

### Creating Custom Dashboards

1. **Go to:** Grafana → Dashboards → New Dashboard
2. **Click:** "Add visualization"
3. **Select:** Data source (Prometheus or Loki)
4. **Choose:** Metric or log query
5. **Customize:** Panel type, colors, thresholds
6. **Save:** Give it a name

---

## 🔧 Common Tasks

### Task 1: Check System CPU Usage

**Via Grafana:**
1. Open "Node Exporter Full" dashboard
2. Look at "CPU Busy" panel (top left)
3. See current usage and historical trend

**Via Prometheus:**
1. Go to http://localhost:9090
2. Query: `100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`
3. View graph

### Task 2: Find Error Logs

**Via Grafana:**
1. Go to Explore (🧭)
2. Select Loki
3. Query: `{job="syslog"} |= "error"`
4. Click "Show logs"

### Task 3: Monitor Docker Containers

**Via Grafana:**
1. Open "Docker Container Monitoring" dashboard
2. See all containers' CPU, memory, network usage
3. Filter by container name if needed

### Task 4: Check Disk Space

**Via Grafana:**
1. Open "Node Exporter Full" dashboard
2. Scroll to "Disk Space Used" panel
3. See usage per filesystem

**Via Prometheus:**
1. Query: `(1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100`

### Task 5: View Active Alerts

**Via Grafana:**
1. Click bell icon (🔔) → Alert rules
2. Filter by state: "Firing"
3. See all active alerts

**Via Alertmanager:**
1. Go to http://localhost:9093
2. See grouped alerts
3. Click for details

### Task 6: Search Logs by Time Range

**Via Grafana:**
1. Go to Explore
2. Select time range (top right)
3. Choose: Last 15 minutes, Last 1 hour, Custom range
4. Run log query

### Task 7: Export Dashboard

```bash
# Export all dashboards to JSON
./export-dashboards.sh

# Find exported files
ls -lh grafana/provisioning/dashboards/json/exported/
```

### Task 8: Backup Everything

```bash
# Run backup script
./backup-monitoring.sh

# Check backup
ls -lh /backups/monitoring/
```

---

## 📱 Recommended Workflow

### Daily Monitoring Routine

1. **Morning Check (5 minutes):**
   - Open Grafana
   - Check "System Overview" dashboard
   - Look for any red/yellow indicators
   - Check active alerts (bell icon)

2. **Weekly Review (15 minutes):**
   - Review "Node Exporter Full" dashboard
   - Check disk space trends
   - Review error logs in Explore
   - Verify all services are up

3. **Monthly Maintenance (30 minutes):**
   - Run backup: `./backup-monitoring.sh`
   - Export dashboards: `./export-dashboards.sh`
   - Review alert thresholds
   - Check for Docker image updates

### Troubleshooting Workflow

1. **Alert Fires:**
   - Check Alertmanager for details
   - Open relevant Grafana dashboard
   - Review logs in Explore
   - Take action based on runbook

2. **Service Down:**
   - Check: `docker compose ps`
   - View logs: `docker compose logs [service]`
   - Restart: `docker compose restart [service]`

3. **High Resource Usage:**
   - Identify source in dashboards
   - Check logs for errors
   - Investigate with Prometheus queries
   - Scale or optimize as needed

---

## 🎓 Learning Resources

### Prometheus Queries (PromQL)

**Basic Queries:**
```promql
# Current CPU usage
node_cpu_seconds_total

# Rate of change (per second)
rate(node_cpu_seconds_total[5m])

# Average across all CPUs
avg(rate(node_cpu_seconds_total[5m]))

# Percentage calculation
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

### Log Queries (LogQL)

**Basic Queries:**
```logql
# All logs from a job
{job="syslog"}

# Filter by text
{job="syslog"} |= "error"

# Regex filter
{job="syslog"} |~ "error|warning"

# Count logs
count_over_time({job="syslog"}[1h])
```

---

## 🆘 Quick Reference

### Service URLs
- **Grafana:** http://localhost:3000 (admin / M8xK9pL2nQ7vR4wT6yU3zA5bC1dE0fG8hJ9kM2nP5qS7tV4wX6yZ3)
- **Prometheus:** http://localhost:9090
- **Alertmanager:** http://localhost:9093
- **Loki:** http://localhost:3100

### Common Commands
```bash
# Start stack
docker compose up -d

# Stop stack
docker compose down

# View logs
docker compose logs -f [service]

# Restart service
docker compose restart [service]

# Check status
docker compose ps

# Backup
./backup-monitoring.sh

# Export dashboards
./export-dashboards.sh
```

### Where to Find Things
- **Metrics:** Grafana dashboards or Prometheus
- **Logs:** Grafana Explore (Loki)
- **Alerts:** Grafana alerts or Alertmanager
- **Configurations:** `prometheus/`, `alertmanager/`, `grafana/`
- **Backups:** `/backups/monitoring/`

---

## ✅ Next Steps

1. ✅ **Login to Grafana** and explore dashboards
2. ✅ **Open Explore** and view some logs
3. ✅ **Check Prometheus** targets are up
4. ✅ **Review alerts** to understand what's monitored
5. ✅ **Configure notifications** (see NOTIFICATION_EXAMPLES.md)
6. ✅ **Set up backups** (add to cron)
7. ✅ **Customize dashboards** for your needs

---

**Need Help?**
- See [README.md](file:///home/ujjwal_root/system-monitoring/README.md) for detailed documentation
- See [PRODUCTION.md](file:///home/ujjwal_root/system-monitoring/PRODUCTION.md) for deployment guide
- See [SECURITY.md](file:///home/ujjwal_root/system-monitoring/SECURITY.md) for security hardening
