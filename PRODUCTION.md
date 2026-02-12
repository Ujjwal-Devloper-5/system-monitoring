# 🚀 Production Deployment Guide

This guide provides best practices and procedures for deploying the monitoring stack to production environments.

## 📋 Pre-Deployment Checklist

### Infrastructure Requirements

- [ ] **CPU**: Minimum 4 cores (8+ recommended)
- [ ] **RAM**: Minimum 8GB (16GB+ recommended)
- [ ] **Disk**: Minimum 100GB SSD (500GB+ recommended)
- [ ] **Network**: Stable connectivity, low latency
- [ ] **OS**: Ubuntu 20.04+, Debian 11+, or RHEL 8+
- [ ] **Docker**: Version 20.10+
- [ ] **Docker Compose**: Version 2.0+

### Security Requirements

- [ ] Strong passwords configured (`.env`)
- [ ] TLS/HTTPS enabled (see [SECURITY.md](SECURITY.md))
- [ ] Firewall rules configured
- [ ] Secrets management implemented
- [ ] Backup strategy defined
- [ ] Monitoring access restricted

### Operational Requirements

- [ ] Alert notification channels configured
- [ ] On-call rotation defined
- [ ] Runbook documentation created
- [ ] Backup/restore procedures tested
- [ ] Disaster recovery plan documented

---

## 🎯 Resource Sizing

### Small Environment (< 10 hosts, < 50 containers)

```yaml
prometheus:
  deploy:
    resources:
      limits:
        cpus: '2'
        memory: 4G
      reservations:
        cpus: '1'
        memory: 2G

grafana:
  deploy:
    resources:
      limits:
        cpus: '1'
        memory: 2G
      reservations:
        cpus: '0.5'
        memory: 1G

loki:
  deploy:
    resources:
      limits:
        cpus: '1'
        memory: 2G
      reservations:
        cpus: '0.5'
        memory: 1G
```

### Medium Environment (10-50 hosts, 50-200 containers)

```yaml
prometheus:
  deploy:
    resources:
      limits:
        cpus: '4'
        memory: 8G
      reservations:
        cpus: '2'
        memory: 4G

grafana:
  deploy:
    resources:
      limits:
        cpus: '2'
        memory: 4G
      reservations:
        cpus: '1'
        memory: 2G

loki:
  deploy:
    resources:
      limits:
        cpus: '2'
        memory: 4G
      reservations:
        cpus: '1'
        memory: 2G
```

### Large Environment (50+ hosts, 200+ containers)

Consider distributed deployment with:
- Prometheus federation or Thanos
- Loki distributed mode
- Load-balanced Grafana instances
- Dedicated storage backend (S3, GCS)

---

## 📦 Deployment Steps

### 1. Prepare Environment

```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install dependencies
sudo apt-get install -y docker.io docker-compose-v2 jq curl

# Create monitoring user
sudo useradd -r -s /bin/bash -d /opt/monitoring monitoring

# Clone repository
sudo git clone <repo-url> /opt/monitoring
sudo chown -R monitoring:monitoring /opt/monitoring
```

### 2. Configure Environment

```bash
cd /opt/monitoring

# Generate strong password
GRAFANA_PASSWORD=$(openssl rand -base64 32)

# Create .env file
cat > .env <<EOF
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
HOSTNAME=$(hostname)

# Configure alert notifications
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
ALERT_EMAIL_TO=oncall@yourdomain.com
EOF

# Secure .env file
chmod 600 .env

# Save password securely
echo "Grafana Password: ${GRAFANA_PASSWORD}" | gpg --encrypt --recipient admin@yourdomain.com > grafana-password.gpg
```

### 3. Configure Alert Notifications

Edit `alertmanager/alertmanager.yml` and configure your notification channels:

```yaml
receivers:
  - name: "critical-alerts"
    slack_configs:
      - api_url: '${SLACK_WEBHOOK_URL}'
        channel: '#alerts-critical'
    email_configs:
      - to: '${ALERT_EMAIL_TO}'
    pagerduty_configs:
      - service_key: '${PAGERDUTY_SERVICE_KEY}'
```

### 4. Validate Configuration

```bash
# Run setup script
./setup.sh

# This will:
# - Validate all YAML configurations
# - Download Grafana dashboards
# - Start all services
# - Verify health checks
# - Display access information
```

### 5. Verify Deployment

```bash
# Check all services are running
docker compose ps

# Check health status
curl http://localhost:9090/-/healthy  # Prometheus
curl http://localhost:9093/-/healthy  # Alertmanager
curl http://localhost:3100/ready      # Loki
curl http://localhost:3000/api/health # Grafana

# Check Prometheus targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'

# Check alert rules loaded
curl -s http://localhost:9090/api/v1/rules | jq '.data.groups | length'
```

### 6. Configure Backups

```bash
# Set up automated backups
sudo crontab -e -u monitoring

# Add backup job (daily at 2 AM)
0 2 * * * cd /opt/monitoring && ./backup-monitoring.sh >> /var/log/monitoring-backup.log 2>&1

# Test backup
sudo -u monitoring ./backup-monitoring.sh

# Verify backup
ls -lh /backups/monitoring/
```

### 7. Configure Monitoring

```bash
# Set up Node Exporter on host (see NODE_EXPORTER_FIX.md)
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
tar xvfz node_exporter-1.7.0.linux-amd64.tar.gz
sudo cp node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/

# Create systemd service
sudo tee /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=monitoring
ExecStart=/usr/local/bin/node_exporter --web.listen-address=":9100"
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start Node Exporter
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# Verify
curl http://localhost:9100/metrics | head
```

---

## 🔄 High Availability Setup

### Prometheus HA with Thanos

```yaml
services:
  prometheus-1:
    # Primary Prometheus instance
    
  prometheus-2:
    # Secondary Prometheus instance
    
  thanos-sidecar:
    image: thanosio/thanos:latest
    command:
      - sidecar
      - --prometheus.url=http://prometheus-1:9090
      - --objstore.config-file=/etc/thanos/bucket.yml
    
  thanos-query:
    image: thanosio/thanos:latest
    command:
      - query
      - --store=thanos-sidecar:10901
```

### Grafana Load Balancing

```yaml
services:
  grafana-1:
    # Primary Grafana
    
  grafana-2:
    # Secondary Grafana
    
  nginx:
    # Load balancer
    upstream grafana {
      server grafana-1:3000;
      server grafana-2:3000;
    }
```

### Loki Distributed Mode

```yaml
services:
  loki-distributor:
    # Handles incoming log streams
    
  loki-ingester:
    # Writes to storage
    
  loki-querier:
    # Handles queries
```

---

## 📊 Monitoring the Monitoring Stack

### Key Metrics to Watch

**Prometheus:**
- `prometheus_tsdb_storage_blocks_bytes` - Storage usage
- `prometheus_tsdb_head_samples` - Active samples
- `prometheus_rule_evaluation_failures_total` - Rule failures
- `prometheus_target_scrapes_exceeded_sample_limit_total` - Scrape issues

**Grafana:**
- `grafana_api_response_status_total` - API health
- `grafana_alerting_active_alerts` - Active alerts

**Loki:**
- `loki_ingester_memory_chunks` - Memory usage
- `loki_request_duration_seconds` - Query performance

### Self-Monitoring Alerts

Already included in `prometheus/rules/system/service-alerts.yml`:
- PrometheusDown
- AlertmanagerDown
- GrafanaDown
- LokiDown
- PrometheusScrapeErrors
- PrometheusNotConnectedToAlertmanager

---

## 🔧 Maintenance Procedures

### Regular Updates

```bash
# Monthly: Update Docker images
cd /opt/monitoring
docker compose pull
docker compose up -d

# Verify after update
./setup.sh
```

### Configuration Changes

```bash
# Edit configuration
vim prometheus/prometheus.yml

# Validate
docker run --rm -v $(pwd)/prometheus:/prometheus prom/prometheus:latest \
  promtool check config /prometheus/prometheus.yml

# Apply changes (hot reload)
curl -X POST http://localhost:9090/-/reload

# Or restart service
docker compose restart prometheus
```

### Log Rotation

```bash
# Configure Docker log rotation
sudo tee /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

sudo systemctl restart docker
```

---

## 🚨 Troubleshooting

### Service Won't Start

```bash
# Check logs
docker compose logs -f [service]

# Check resources
docker stats

# Check disk space
df -h

# Validate configuration
./setup.sh
```

### High Memory Usage

```bash
# Check Prometheus cardinality
curl http://localhost:9090/api/v1/status/tsdb | jq '.data.seriesCountByMetricName'

# Reduce retention if needed
# Edit docker-compose.yml:
# --storage.tsdb.retention.time=7d

# Restart
docker compose restart prometheus
```

### Missing Metrics

```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# Check scrape errors
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health!="up")'

# Check network connectivity
docker compose exec prometheus wget -O- http://node-exporter:9100/metrics
```

---

## 📚 Runbook Examples

### Alert: HighCPUUsage

**Severity:** Warning  
**Threshold:** CPU > 80% for 5 minutes

**Investigation:**
```bash
# SSH to affected host
ssh user@affected-host

# Check top processes
top -o %CPU

# Check load average
uptime

# Check for runaway processes
ps aux --sort=-%cpu | head -20
```

**Resolution:**
- Identify resource-intensive process
- Optimize or restart if necessary
- Consider scaling if sustained high usage

### Alert: DiskSpaceCritical

**Severity:** Critical  
**Threshold:** Disk < 10% free

**Investigation:**
```bash
# Check disk usage
df -h

# Find large directories
du -h / | sort -rh | head -20

# Find large files
find / -type f -size +1G -exec ls -lh {} \;
```

**Resolution:**
- Clean up logs: `journalctl --vacuum-time=7d`
- Remove old Docker images: `docker system prune -a`
- Expand disk if needed

---

## 🔐 Security Hardening

See [SECURITY.md](SECURITY.md) for comprehensive security guide.

**Quick wins:**
- Enable TLS/HTTPS
- Configure authentication
- Restrict network access
- Enable audit logging
- Use secrets management
- Regular security updates

---

## 📞 Support & Escalation

### On-Call Procedures

1. **Acknowledge alert** in PagerDuty/Slack
2. **Assess severity** using runbook
3. **Investigate** using provided commands
4. **Resolve** or escalate to senior engineer
5. **Document** in incident log

### Escalation Path

1. **Level 1:** On-call engineer
2. **Level 2:** Senior SRE
3. **Level 3:** Engineering manager
4. **Level 4:** CTO/VP Engineering

---

## 📈 Capacity Planning

### Growth Projections

Monitor these trends monthly:
- Metric cardinality growth
- Storage usage growth
- Query latency trends
- Alert volume trends

### Scaling Triggers

Scale when:
- Prometheus memory > 80% consistently
- Query latency > 5s regularly
- Storage growth > 10GB/week
- Scrape duration > 30s

---

## ✅ Production Readiness Checklist

### Before Go-Live

- [ ] All services healthy
- [ ] Alert notifications tested
- [ ] Backup/restore tested
- [ ] Documentation complete
- [ ] On-call rotation trained
- [ ] Runbooks created
- [ ] Security hardening complete
- [ ] Performance tested
- [ ] Disaster recovery plan documented
- [ ] Monitoring validated

### Post-Deployment

- [ ] Monitor for 48 hours
- [ ] Tune alert thresholds
- [ ] Optimize resource usage
- [ ] Document lessons learned
- [ ] Update runbooks
- [ ] Train additional team members

---

## 📚 Additional Resources

- [Prometheus Production Best Practices](https://prometheus.io/docs/practices/)
- [Grafana Production Deployment](https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/)
- [Loki Production Setup](https://grafana.com/docs/loki/latest/operations/)
- [SRE Book - Monitoring](https://sre.google/sre-book/monitoring-distributed-systems/)
