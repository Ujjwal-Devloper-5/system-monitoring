#!/bin/bash
set -e

# ═══════════════════════════════════════════════════════════
# Monitoring Stack Backup Script
# ═══════════════════════════════════════════════════════════
# This script backs up all monitoring data and configurations
# Run daily via cron: 0 2 * * * /path/to/backup-monitoring.sh
# ═══════════════════════════════════════════════════════════

BACKUP_BASE_DIR="${BACKUP_DIR:-/backups/monitoring}"
BACKUP_DIR="$BACKUP_BASE_DIR/$(date +%Y%m%d_%H%M%S)"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔄 Starting monitoring stack backup..."
echo "📁 Backup directory: $BACKUP_DIR"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# ─────────────────────────
# Backup Docker Volumes
# ─────────────────────────
echo ""
echo "📦 Backing up Docker volumes..."

# Prometheus data
echo "  → Prometheus TSDB..."
docker run --rm \
  -v system-monitoring_prometheus-data:/data:ro \
  -v "$BACKUP_DIR:/backup" \
  alpine tar czf /backup/prometheus-data.tar.gz -C /data . 2>/dev/null || echo "    ⚠️  Prometheus volume not found"

# Grafana data
echo "  → Grafana data..."
docker run --rm \
  -v system-monitoring_grafana-data:/data:ro \
  -v "$BACKUP_DIR:/backup" \
  alpine tar czf /backup/grafana-data.tar.gz -C /data . 2>/dev/null || echo "    ⚠️  Grafana volume not found"

# Loki data
echo "  → Loki data..."
docker run --rm \
  -v system-monitoring_loki-data:/data:ro \
  -v "$BACKUP_DIR:/backup" \
  alpine tar czf /backup/loki-data.tar.gz -C /data . 2>/dev/null || echo "    ⚠️  Loki volume not found"

# Alertmanager data
echo "  → Alertmanager data..."
docker run --rm \
  -v system-monitoring_alertmanager-data:/data:ro \
  -v "$BACKUP_DIR:/backup" \
  alpine tar czf /backup/alertmanager-data.tar.gz -C /data . 2>/dev/null || echo "    ⚠️  Alertmanager volume not found"

# ─────────────────────────
# Backup Configurations
# ─────────────────────────
echo ""
echo "⚙️  Backing up configurations..."

cd "$PROJECT_DIR"
tar czf "$BACKUP_DIR/configurations.tar.gz" \
  prometheus/ \
  alertmanager/ \
  grafana/ \
  loki/ \
  promtail/ \
  docker-compose.yml \
  setup.sh \
  download-dashboards.sh \
  .env 2>/dev/null || echo "  ⚠️  Some configuration files not found"

# ─────────────────────────
# Backup Metadata
# ─────────────────────────
echo ""
echo "📝 Creating backup metadata..."

cat > "$BACKUP_DIR/backup-info.txt" <<EOF
Backup Information
==================
Date: $(date)
Hostname: $(hostname)
Backup Directory: $BACKUP_DIR

Docker Volumes:
- Prometheus: $(docker volume inspect system-monitoring_prometheus-data --format '{{.Mountpoint}}' 2>/dev/null || echo "N/A")
- Grafana: $(docker volume inspect system-monitoring_grafana-data --format '{{.Mountpoint}}' 2>/dev/null || echo "N/A")
- Loki: $(docker volume inspect system-monitoring_loki-data --format '{{.Mountpoint}}' 2>/dev/null || echo "N/A")
- Alertmanager: $(docker volume inspect system-monitoring_alertmanager-data --format '{{.Mountpoint}}' 2>/dev/null || echo "N/A")

Services Status:
$(docker compose ps 2>/dev/null || echo "Docker Compose not running")

Backup Files:
$(ls -lh "$BACKUP_DIR")
EOF

# ─────────────────────────
# Calculate Backup Size
# ─────────────────────────
BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
echo ""
echo "✅ Backup completed successfully!"
echo "📊 Backup size: $BACKUP_SIZE"
echo "📁 Location: $BACKUP_DIR"

# ─────────────────────────
# Cleanup Old Backups
# ─────────────────────────
echo ""
echo "🧹 Cleaning up old backups (retention: $RETENTION_DAYS days)..."

DELETED_COUNT=0
if [ -d "$BACKUP_BASE_DIR" ]; then
  while IFS= read -r -d '' old_backup; do
    echo "  → Deleting: $(basename "$old_backup")"
    rm -rf "$old_backup"
    ((DELETED_COUNT++))
  done < <(find "$BACKUP_BASE_DIR" -maxdepth 1 -type d -mtime +$RETENTION_DAYS -print0 2>/dev/null)
fi

if [ $DELETED_COUNT -eq 0 ]; then
  echo "  ✓ No old backups to delete"
else
  echo "  ✓ Deleted $DELETED_COUNT old backup(s)"
fi

# ─────────────────────────
# Summary
# ─────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Backup Summary"
echo "═══════════════════════════════════════════════════════════"
echo "Status: SUCCESS"
echo "Backup Directory: $BACKUP_DIR"
echo "Backup Size: $BACKUP_SIZE"
echo "Retention: $RETENTION_DAYS days"
echo "Old Backups Deleted: $DELETED_COUNT"
echo ""
echo "To restore from this backup, run:"
echo "  ./restore-monitoring.sh $BACKUP_DIR"
echo "═══════════════════════════════════════════════════════════"

# ═══════════════════════════════════════════════════════════
# RESTORE INSTRUCTIONS
# ═══════════════════════════════════════════════════════════
# To restore from a backup:
#
# 1. Stop the monitoring stack:
#    docker compose down
#
# 2. Restore volumes:
#    docker run --rm -v system-monitoring_prometheus-data:/data -v /path/to/backup:/backup alpine tar xzf /backup/prometheus-data.tar.gz -C /data
#    docker run --rm -v system-monitoring_grafana-data:/data -v /path/to/backup:/backup alpine tar xzf /backup/grafana-data.tar.gz -C /data
#    docker run --rm -v system-monitoring_loki-data:/data -v /path/to/backup:/backup alpine tar xzf /backup/loki-data.tar.gz -C /data
#    docker run --rm -v system-monitoring_alertmanager-data:/data -v /path/to/backup:/backup alpine tar xzf /backup/alertmanager-data.tar.gz -C /data
#
# 3. Restore configurations:
#    tar xzf /path/to/backup/configurations.tar.gz
#
# 4. Start the stack:
#    docker compose up -d
# ═══════════════════════════════════════════════════════════
