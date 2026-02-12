# 🚀 God-Level System Monitoring Stack

A **production-grade, enterprise-level** system monitoring solution with comprehensive metrics collection, professional dashboards, exhaustive alerting, and full log aggregation.

## 📊 Stack Overview

| Component | Purpose | Port |
|-----------|---------|------|
| **Prometheus** | Metrics collection & storage | 9090 |
| **Alertmanager** | Alert routing & notifications | 9093 |
| **Grafana** | Visualization & dashboards | 3000 |
| **Loki** | Log aggregation | 3100 |
| **Promtail** | Log collection agent | - |
| **cAdvisor** | Container metrics | 8080 |
| **Node Exporter** | Host system metrics | 9100 (host) |

## ✨ Features

### 📈 Metrics Collection
- **Host System Metrics**: CPU, memory, disk, network via Node Exporter
- **Container Metrics**: Resource usage via cAdvisor
- **Stack Self-Monitoring**: Prometheus, Loki, Grafana, Alertmanager metrics
- **15-day retention** with configurable storage

### 🚨 Comprehensive Alerting (50+ Rules)
- **CPU Alerts** (8): Usage, I/O wait, steal time, context switching, throttling, core imbalance
- **Memory Alerts** (9): Usage, swap, thrashing, OOM kills, pressure, leak detection
- **Disk Alerts** (11): Space, inodes, I/O saturation, latency, errors, read-only filesystems
- **Network Alerts** (9): Bandwidth, errors, drops, interface status, TCP connections
- **System Alerts** (11): Load, uptime, time sync, processes, file descriptors, temperature
- **Service Alerts** (11): Availability and health of all monitoring components

### 📊 Professional Dashboards (8)
1. **Node Exporter Full** - Comprehensive host metrics
2. **Node Exporter for Prometheus** - Detailed system monitoring
3. **Loki Dashboard** - Log aggregation and metrics
4. **cAdvisor** - Container resource monitoring
5. **Prometheus Stats** - Prometheus self-monitoring
6. **Alertmanager** - Alert management
7. **System Overview** - High-level system view
8. **Logs Dashboard** - Log analysis and search

### 📝 Log Collection
- **System Logs**: syslog, kernel, auth, cron, daemon, boot
- **Docker Container Logs**: All container stdout/stderr
- **Structured Parsing**: Automatic field extraction
- **30-day retention** with automatic cleanup

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose installed
- Node Exporter running on host (port 9100)
- `jq` installed (for dashboard download)

### Installation

```bash
# Clone or navigate to the monitoring directory
cd system-monitoring

# Run the setup script
./setup.sh
```

The setup script will:
1. ✅ Validate all configurations
2. 📥 Download professional Grafana dashboards
3. 🔐 Create .env file for credentials
4. 🚀 Start all services with health checks
5. ⏳ Wait for services to be healthy
6. 🎯 Verify Prometheus targets
7. 📊 Display access information

### Manual Setup

```bash
# Validate configurations
docker run --rm -v $(pwd)/prometheus:/prometheus prom/prometheus:latest \
  promtool check config /prometheus/prometheus.yml

docker run --rm -v $(pwd)/prometheus:/prometheus prom/prometheus:latest \
  promtool check rules /prometheus/rules/system/*.yml

docker run --rm -v $(pwd)/alertmanager:/alertmanager prom/alertmanager:latest \
  amtool check-config /alertmanager/alertmanager.yml

# Download dashboards
./download-dashboards.sh

# Start services
docker compose up -d

# Check logs
docker compose logs -f
```

## 🔐 Configuration

### Environment Variables

Create a `.env` file:

```env
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=your_secure_password_here
HOSTNAME=$(hostname)
```

### Alert Notifications

Edit `alertmanager/alertmanager.yml` to configure notification channels:

**Webhook:**
```yaml
receivers:
  - name: "critical-alerts"
    webhook_configs:
      - url: 'https://your-webhook-url'
```

**Email:**
```yaml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@example.com'
  smtp_auth_username: 'alerts@example.com'
  smtp_auth_password: 'your-app-password'

receivers:
  - name: "critical-alerts"
    email_configs:
      - to: 'team@example.com'
```

**Slack:**
```yaml
receivers:
  - name: "critical-alerts"
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
        channel: '#alerts'
```

## 📊 Accessing the Stack

| Service | URL | Credentials |
|---------|-----|-------------|
| Grafana | http://localhost:3000 | admin / (from .env) |
| Prometheus | http://localhost:9090 | - |
| Alertmanager | http://localhost:9093 | - |
| Loki | http://localhost:3100 | - |
| cAdvisor | http://localhost:8080 | - |

## 📁 Directory Structure

```
system-monitoring/
├── prometheus/
│   ├── prometheus.yml              # Main Prometheus config
│   └── rules/system/               # Alert rules
│       ├── cpu-alerts.yml          # CPU monitoring
│       ├── memory-alerts.yml       # Memory monitoring
│       ├── disk-alerts.yml         # Disk monitoring
│       ├── network-alerts.yml      # Network monitoring
│       ├── system-alerts.yml       # System monitoring
│       ├── service-alerts.yml      # Service availability
│       └── system-health.yml       # Legacy alerts
├── alertmanager/
│   └── alertmanager.yml            # Alert routing config
├── grafana/
│   └── provisioning/
│       ├── datasources/            # Auto-provisioned datasources
│       │   └── datasources.yml
│       └── dashboards/             # Auto-provisioned dashboards
│           ├── dashboards.yml
│           └── json/               # Dashboard JSON files
├── loki/
│   └── loki.yml                    # Loki config with retention
├── promtail/
│   └── promtail.yml                # Log collection config
├── docker-compose.yml              # Service definitions
├── setup.sh                        # Setup & validation script
├── download-dashboards.sh          # Dashboard download script
└── .env                            # Environment variables
```

## 🔧 Maintenance

### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f prometheus
docker compose logs -f grafana
```

### Restart Services
```bash
# All services
docker compose restart

# Specific service
docker compose restart prometheus
```

### Update Configurations
```bash
# After editing configs, reload without downtime
docker compose up -d

# Reload Prometheus configuration
curl -X POST http://localhost:9090/-/reload

# Reload Alertmanager configuration
curl -X POST http://localhost:9093/-/reload
```

### Backup Data
```bash
# Backup volumes
docker run --rm -v system-monitoring_prometheus-data:/data -v $(pwd)/backups:/backup alpine tar czf /backup/prometheus-$(date +%Y%m%d).tar.gz /data

docker run --rm -v system-monitoring_grafana-data:/data -v $(pwd)/backups:/backup alpine tar czf /backup/grafana-$(date +%Y%m%d).tar.gz /data

docker run --rm -v system-monitoring_loki-data:/data -v $(pwd)/backups:/backup alpine tar czf /backup/loki-$(date +%Y%m%d).tar.gz /data
```

## 🎯 Monitoring Best Practices

### 1. Alert Tuning
- Review alert thresholds after 1 week of baseline data
- Adjust based on your system's normal behavior
- Use inhibition rules to prevent alert storms

### 2. Dashboard Customization
- Clone and customize dashboards for your needs
- Add panels for application-specific metrics
- Use variables for multi-instance monitoring

### 3. Log Management
- Adjust retention based on disk space
- Use log-based metrics for important patterns
- Set up log-based alerts for critical errors

### 4. Resource Management
- Monitor the monitoring stack itself
- Adjust resource limits based on usage
- Scale Prometheus storage as needed

## 🐛 Troubleshooting

### Prometheus Not Scraping Node Exporter
```bash
# Check if Node Exporter is accessible
curl http://localhost:9100/metrics

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.labels.job=="system-node")'
```

### Grafana Dashboards Not Appearing
```bash
# Check provisioning logs
docker compose logs grafana | grep -i provision

# Verify dashboard files exist
ls -la grafana/provisioning/dashboards/json/
```

### Alerts Not Firing
```bash
# Check if rules are loaded
curl http://localhost:9090/api/v1/rules | jq '.data.groups[].rules[] | {alert: .name, state: .state}'

# Check Alertmanager connection
curl http://localhost:9090/api/v1/alertmanagers
```

### Loki Not Receiving Logs
```bash
# Check Promtail logs
docker compose logs promtail

# Query Loki directly
curl -G -s "http://localhost:3100/loki/api/v1/query" --data-urlencode 'query={job="syslog"}' | jq '.'
```

## 📚 Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/)
- [Alertmanager Documentation](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [Node Exporter Guide](https://prometheus.io/docs/guides/node-exporter/)

## 🔮 Future Enhancements

### Security Monitoring Stack
- Fail2ban metrics exporter
- SSH login monitoring
- File integrity monitoring
- Security audit log analysis
- Vulnerability scanning metrics

### Network Monitoring Stack
- Blackbox exporter for endpoint monitoring
- SNMP exporter for network devices
- Smokeping for latency monitoring
- Network flow analysis
- DNS query monitoring

## 📝 License

This monitoring stack configuration is provided as-is for system monitoring purposes.

## 🤝 Contributing

Feel free to customize and extend this monitoring stack for your needs!

---

**Built with ❤️ for professional system monitoring**
