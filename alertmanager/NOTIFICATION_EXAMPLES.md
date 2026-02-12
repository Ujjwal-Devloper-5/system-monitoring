# ═══════════════════════════════════════════════════════════
# ALERTMANAGER NOTIFICATION CONFIGURATION GUIDE
# ═══════════════════════════════════════════════════════════
# This file contains examples for configuring different notification
# channels in Alertmanager. Copy the relevant sections to your
# alertmanager.yml file and configure the environment variables in .env
# ═══════════════════════════════════════════════════════════

# ─────────────────────────
# SLACK CONFIGURATION
# ─────────────────────────
# 1. Create a Slack Incoming Webhook: https://api.slack.com/messaging/webhooks
# 2. Add to .env:
#    SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
#    SLACK_CHANNEL=#alerts
# 3. Add to alertmanager.yml receiver:

slack_configs:
  - api_url: '${SLACK_WEBHOOK_URL}'
    channel: '${SLACK_CHANNEL}'
    username: 'Alertmanager'
    icon_emoji: ':fire:'
    title: '[{{ .Status | toUpper }}] {{ .GroupLabels.alertname }}'
    text: |
      *Summary:* {{ range .Alerts }}{{ .Annotations.summary }}{{ end }}
      *Description:* {{ range .Alerts }}{{ .Annotations.description }}{{ end }}
      *Impact:* {{ range .Alerts }}{{ .Annotations.impact }}{{ end }}
      *Action:* {{ range .Alerts }}{{ .Annotations.action }}{{ end }}
    send_resolved: true
    color: '{{ if eq .Status "firing" }}danger{{ else }}good{{ end }}'

# ─────────────────────────
# EMAIL CONFIGURATION
# ─────────────────────────
# 1. Add to .env:
#    SMTP_HOST=smtp.gmail.com:587
#    SMTP_FROM=monitoring@yourdomain.com
#    SMTP_USERNAME=monitoring@yourdomain.com
#    SMTP_PASSWORD=your-app-specific-password
#    ALERT_EMAIL_TO=oncall@yourdomain.com
# 2. Add to alertmanager.yml global section:

global:
  smtp_smarthost: '${SMTP_HOST}'
  smtp_from: '${SMTP_FROM}'
  smtp_auth_username: '${SMTP_USERNAME}'
  smtp_auth_password: '${SMTP_PASSWORD}'
  smtp_require_tls: true

# 3. Add to alertmanager.yml receiver:

email_configs:
  - to: '${ALERT_EMAIL_TO}'
    headers:
      Subject: '[{{ .Status | toUpper }}] {{ .GroupLabels.alertname }}'
    html: |
      <h2>Alert: {{ .GroupLabels.alertname }}</h2>
      <p><strong>Status:</strong> {{ .Status }}</p>
      {{ range .Alerts }}
      <hr>
      <p><strong>Summary:</strong> {{ .Annotations.summary }}</p>
      <p><strong>Description:</strong> {{ .Annotations.description }}</p>
      <p><strong>Impact:</strong> {{ .Annotations.impact }}</p>
      <p><strong>Action:</strong> {{ .Annotations.action }}</p>
      <p><strong>Instance:</strong> {{ .Labels.instance }}</p>
      {{ end }}
    send_resolved: true

# ─────────────────────────
# PAGERDUTY CONFIGURATION
# ─────────────────────────
# 1. Get your PagerDuty Integration Key
# 2. Add to .env:
#    PAGERDUTY_SERVICE_KEY=your-integration-key
# 3. Add to alertmanager.yml receiver:

pagerduty_configs:
  - service_key: '${PAGERDUTY_SERVICE_KEY}'
    description: '{{ .GroupLabels.alertname }}: {{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
    severity: '{{ if eq .GroupLabels.severity "critical" }}critical{{ else }}warning{{ end }}'
    details:
      summary: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
      description: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
      impact: '{{ range .Alerts }}{{ .Annotations.impact }}{{ end }}'
      action: '{{ range .Alerts }}{{ .Annotations.action }}{{ end }}'
      instance: '{{ .GroupLabels.instance }}'
    send_resolved: true

# ─────────────────────────
# MICROSOFT TEAMS
# ─────────────────────────
# 1. Create an Incoming Webhook in Teams
# 2. Add to .env:
#    TEAMS_WEBHOOK_URL=https://outlook.office.com/webhook/...
# 3. Add to alertmanager.yml receiver:

webhook_configs:
  - url: '${TEAMS_WEBHOOK_URL}'
    send_resolved: true

# ─────────────────────────
# DISCORD CONFIGURATION
# ─────────────────────────
# 1. Create a Discord Webhook
# 2. Add to .env:
#    DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...
# 3. Add to alertmanager.yml receiver:

webhook_configs:
  - url: '${DISCORD_WEBHOOK_URL}'
    send_resolved: true

# ─────────────────────────
# TELEGRAM CONFIGURATION
# ─────────────────────────
# Requires telegram bot setup
# See: https://prometheus.io/docs/alerting/latest/configuration/#telegram_config

# ═══════════════════════════════════════════════════════════
# TESTING NOTIFICATIONS
# ═══════════════════════════════════════════════════════════
# After configuration, test with:
# docker compose restart alertmanager
# 
# Send a test alert:
# curl -X POST http://localhost:9093/api/v1/alerts -d '[{
#   "labels": {"alertname": "TestAlert", "severity": "warning"},
#   "annotations": {
#     "summary": "Test alert",
#     "description": "This is a test alert"
#   }
# }]'
# ═══════════════════════════════════════════════════════════
