# 📊 How to View Logs and Fix Dashboard Issues

## 🔍 Viewing Logs in Grafana

### Method 1: Using Explore (Recommended)

1. **Open Grafana:** http://localhost:3000
2. **Click the Explore icon** (🧭 compass) in the left sidebar
3. **Select "Loki" from the datasource dropdown** at the top
4. **Click "Log browser"** button
5. **Select a job** from the list:
   - `syslog` - System logs
   - `docker` - Container logs  
   - `auth` - Authentication logs
   - `kernel` - Kernel messages
   - `boot` - Boot logs
6. **Click "Show logs"**
7. **Adjust time range** if needed (top right corner)

### Method 2: Using Log Queries

In the Explore view, you can write LogQL queries:

```logql
# View all syslog entries
{job="syslog"}

# View Docker container logs
{job="docker"}

# Filter by specific text
{job="syslog"} |= "error"

# View logs from last 5 minutes
{job="syslog"} [5m]
```

### Method 3: Using Logs/App Dashboard

1. Go to **Dashboards** → **Logs / App**
2. This dashboard shows log analysis and patterns
3. Select job and time range from dropdowns

## 🎯 Why Only 1 Dashboard is Working

You have **8 dashboards total:**

1. ✅ **Node Exporter Full** - WORKING (you confirmed this!)
2. ❓ **Node Exporter Server Metrics** - Should work (uses same metrics)
3. ❓ **Node Exporter Dashboard EN** - Should work (uses same metrics)
4. ❓ **Prometheus 2.0 Overview** - Should work
5. ❓ **Alertmanager** - Should work
6. ❓ **cAdvisor exporter** - Should work
7. ❓ **Loki Dashboard** - Should work
8. ❓ **Logs / App** - Should work

### Common Reasons Dashboards Show "No Data"

#### 1. **Time Range Too Long**
- **Problem:** Dashboard defaults to "Last 7 days" but you just started monitoring
- **Solution:** Change time range to "Last 1 hour" or "Last 5 minutes"
- **How:** Click time picker (top right) → Select "Last 1 hour"

#### 2. **Dashboard Variables Not Selected**
- **Problem:** Dropdowns at top of dashboard are empty or set to "All"
- **Solution:** Select specific values from dropdowns
- **Common variables:**
  - `datasource` → Select "Prometheus"
  - `job` → Select "system-node" or "system-containers"
  - `instance` → Select your instance (e.g., "localhost:9100")
  - `node` → Select your hostname

#### 3. **Rate Calculations Need Time**
- **Problem:** Panels using `rate()` or `irate()` need historical data
- **Solution:** Wait 5-10 minutes, then refresh
- **Affected panels:** CPU usage %, network rates, disk I/O rates

#### 4. **Panel-Specific Queries**
- **Problem:** Some panels query metrics that don't exist in your setup
- **Solution:** This is normal, ignore empty panels

## 🔧 How to Test Each Dashboard

### Node Exporter Dashboards (Should ALL Work)

**Test:** All three Node Exporter dashboards use the same metrics

1. **Node Exporter Full** ✅ (Already working!)
2. **Node Exporter Server Metrics**
   - Open dashboard
   - Set time range: "Last 1 hour"
   - Select variables if prompted
3. **Node Exporter Dashboard EN**
   - Open dashboard
   - Set time range: "Last 1 hour"
   - Select `job="system-node"`

### Prometheus 2.0 Overview

1. Open dashboard
2. Set time range: "Last 1 hour"
3. Should show:
   - Prometheus uptime
   - Number of samples
   - Scrape duration
   - Storage metrics

### cAdvisor exporter (Docker Containers)

1. Open dashboard
2. Set time range: "Last 1 hour"
3. **Important:** Select instance from dropdown at top
4. Should show all your Docker containers

### Alertmanager

1. Open dashboard
2. Set time range: "Last 1 hour"
3. Shows alert statistics (may be empty if no alerts firing)

### Loki Dashboard

1. Open dashboard
2. Set time range: "Last 1 hour"
3. Shows Loki ingestion rate and query performance

### Logs / App

1. Open dashboard
2. Select job from dropdown (e.g., "syslog")
3. Set time range: "Last 1 hour"
4. Shows log analysis

## 🧪 Quick Test Commands

### Test if metrics are available:

```bash
# Node Exporter metrics
curl -s 'http://localhost:9090/api/v1/query' --data-urlencode 'query=node_uname_info' | jq '.data.result | length'
# Should return: 1

# Container metrics
curl -s 'http://localhost:9090/api/v1/query' --data-urlencode 'query=container_memory_usage_bytes' | jq '.data.result | length'
# Should return: >0

# Prometheus metrics
curl -s 'http://localhost:9090/api/v1/query' --data-urlencode 'query=prometheus_build_info' | jq '.data.result | length'
# Should return: 1
```

### Test if logs are available:

```bash
# Check Loki has logs
curl -s 'http://localhost:3100/loki/api/v1/label/job/values' | jq '.data'
# Should return: ["auth", "boot", "containers", "kernel", "syslog"]
```

## 📝 Step-by-Step: View Logs Right Now

1. Open http://localhost:3000
2. Login (admin/admin)
3. Click **Explore** (🧭) in left sidebar
4. Dropdown at top should say "Loki" (if not, select it)
5. Click **"Log browser"** button (blue button)
6. You'll see a list of jobs - click **"syslog"**
7. Click **"Show logs"** button
8. You should see logs streaming!

**If you see "No data":**
- Change time range to "Last 1 hour" (top right)
- Try different job (e.g., "docker" or "kernel")
- Refresh the page

## 🎯 Summary

**Logs:** Use Explore → Loki → Log browser → Select job → Show logs

**Dashboards:** 
- All should work if you set correct time range (Last 1 hour)
- Select variables from dropdowns at top
- Wait 5 minutes for rate-based panels
- Node Exporter Full already works, others use same approach

**Your screenshot shows Explore with Loki selected but "No data"** - this is likely because:
1. Time range is too long
2. No job selected in the query
3. Need to use Log browser instead of manual query
