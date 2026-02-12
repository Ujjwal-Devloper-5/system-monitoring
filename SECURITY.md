# 🔐 Security Guide - System Monitoring Stack

This document provides security best practices and hardening recommendations for the monitoring stack.

## 🎯 Quick Security Checklist

Before deploying to production, ensure you have:

- [ ] Changed default Grafana password
- [ ] Configured at least one alert notification channel
- [ ] Enabled HTTPS/TLS for all web interfaces
- [ ] Implemented authentication on Prometheus and Alertmanager
- [ ] Restricted network access (firewall rules)
- [ ] Set up secrets management
- [ ] Configured backup automation
- [ ] Reviewed and restricted file permissions
- [ ] Enabled audit logging
- [ ] Implemented monitoring of the monitoring stack

---

## 🔑 Credentials Management

### Current Setup

The stack uses `.env` file for credentials:
```bash
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=<generated-strong-password>
```

### Production Recommendations

#### 1. Use Docker Secrets

```yaml
# docker-compose.yml
services:
  grafana:
    secrets:
      - grafana_admin_password
    environment:
      - GF_SECURITY_ADMIN_PASSWORD__FILE=/run/secrets/grafana_admin_password

secrets:
  grafana_admin_password:
    file: ./secrets/grafana_password.txt
```

#### 2. Use External Secrets Manager

**HashiCorp Vault:**
```bash
# Store secret in Vault
vault kv put secret/monitoring/grafana password="your-strong-password"

# Retrieve in startup script
export GRAFANA_ADMIN_PASSWORD=$(vault kv get -field=password secret/monitoring/grafana)
```

**AWS Secrets Manager:**
```bash
# Store secret
aws secretsmanager create-secret \
  --name monitoring/grafana/password \
  --secret-string "your-strong-password"

# Retrieve
export GRAFANA_ADMIN_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id monitoring/grafana/password \
  --query SecretString --output text)
```

#### 3. Password Rotation

```bash
#!/bin/bash
# rotate-grafana-password.sh

# Generate new password
NEW_PASSWORD=$(openssl rand -base64 32)

# Update Grafana
curl -X PUT http://admin:${OLD_PASSWORD}@localhost:3000/api/user/password \
  -H "Content-Type: application/json" \
  -d "{\"oldPassword\":\"${OLD_PASSWORD}\",\"newPassword\":\"${NEW_PASSWORD}\"}"

# Update .env
sed -i "s/GRAFANA_ADMIN_PASSWORD=.*/GRAFANA_ADMIN_PASSWORD=${NEW_PASSWORD}/" .env

# Restart Grafana
docker compose restart grafana
```

---

## 🔒 TLS/HTTPS Configuration

### Option 1: Reverse Proxy with Nginx

**1. Create SSL certificates:**
```bash
# Self-signed (development only)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/key.pem \
  -out nginx/ssl/cert.pem

# Let's Encrypt (production)
certbot certonly --standalone -d monitoring.yourdomain.com
```

**2. Add Nginx to docker-compose.yml:**
```yaml
services:
  nginx:
    image: nginx:alpine
    container_name: monitoring-nginx
    ports:
      - "443:443"
      - "80:80"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
    networks:
      - observability
    depends_on:
      - grafana
      - prometheus
      - alertmanager
```

**3. Create nginx.conf:**
```nginx
server {
    listen 443 ssl http2;
    server_name monitoring.yourdomain.com;
    
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    # Grafana
    location / {
        proxy_pass http://grafana:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Prometheus
    location /prometheus/ {
        auth_basic "Prometheus";
        auth_basic_user_file /etc/nginx/.htpasswd;
        proxy_pass http://prometheus:9090/;
    }
    
    # Alertmanager
    location /alertmanager/ {
        auth_basic "Alertmanager";
        auth_basic_user_file /etc/nginx/.htpasswd;
        proxy_pass http://alertmanager:9093/;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name monitoring.yourdomain.com;
    return 301 https://$server_name$request_uri;
}
```

**4. Create basic auth file:**
```bash
# Install htpasswd
sudo apt-get install apache2-utils

# Create password file
htpasswd -c nginx/.htpasswd admin
```

### Option 2: Traefik Reverse Proxy

```yaml
services:
  traefik:
    image: traefik:v2.10
    command:
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencrypt.acme.email=admin@yourdomain.com"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./letsencrypt:/letsencrypt
    networks:
      - observability

  grafana:
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.grafana.rule=Host(`monitoring.yourdomain.com`)"
      - "traefik.http.routers.grafana.entrypoints=websecure"
      - "traefik.http.routers.grafana.tls.certresolver=letsencrypt"
```

---

## 🛡️ Authentication & Authorization

### Grafana Authentication

#### OAuth/SSO Integration

**Google OAuth:**
```yaml
# docker-compose.yml
grafana:
  environment:
    - GF_AUTH_GOOGLE_ENABLED=true
    - GF_AUTH_GOOGLE_CLIENT_ID=your-client-id
    - GF_AUTH_GOOGLE_CLIENT_SECRET=your-client-secret
    - GF_AUTH_GOOGLE_ALLOWED_DOMAINS=yourdomain.com
```

**LDAP:**
```yaml
grafana:
  volumes:
    - ./grafana/ldap.toml:/etc/grafana/ldap.toml:ro
  environment:
    - GF_AUTH_LDAP_ENABLED=true
    - GF_AUTH_LDAP_CONFIG_FILE=/etc/grafana/ldap.toml
```

#### Role-Based Access Control (RBAC)

Create teams and assign permissions in Grafana UI or via API:
```bash
# Create team
curl -X POST http://admin:password@localhost:3000/api/teams \
  -H "Content-Type: application/json" \
  -d '{"name":"Viewers"}'

# Add user to team
curl -X POST http://admin:password@localhost:3000/api/teams/1/members \
  -H "Content-Type: application/json" \
  -d '{"userId":2}'
```

### Prometheus Authentication

**Basic Auth (Prometheus 2.24+):**

1. Create `prometheus/web.yml`:
```yaml
basic_auth_users:
  admin: $2y$10$... # bcrypt hash
```

2. Generate bcrypt hash:
```bash
htpasswd -nBC 10 "" | tr -d ':\n'
```

3. Update docker-compose.yml:
```yaml
prometheus:
  command:
    - --web.config.file=/prometheus/web.yml
  volumes:
    - ./prometheus/web.yml:/prometheus/web.yml:ro
```

### Alertmanager Authentication

Similar to Prometheus, use `--web.config.file` flag.

---

## 🌐 Network Security

### Firewall Rules

```bash
# Allow only specific IPs to access monitoring
sudo ufw allow from 10.0.0.0/8 to any port 3000 proto tcp  # Grafana
sudo ufw allow from 10.0.0.0/8 to any port 9090 proto tcp  # Prometheus
sudo ufw allow from 10.0.0.0/8 to any port 9093 proto tcp  # Alertmanager

# Or use localhost only (current setup)
# Ports are bound to 127.0.0.1 in docker-compose.yml
```

### Docker Network Isolation

```yaml
# docker-compose.yml
networks:
  observability:
    driver: bridge
    internal: true  # No external access
  
  frontend:
    driver: bridge  # External access

services:
  grafana:
    networks:
      - observability
      - frontend  # Only Grafana exposed
```

### VPN Access

Use WireGuard or OpenVPN to access monitoring:
```bash
# Install WireGuard
sudo apt-get install wireguard

# Configure VPN access to monitoring network
# Only allow VPN users to access ports 3000, 9090, 9093
```

---

## 📊 Audit Logging

### Enable Grafana Audit Logs

```yaml
grafana:
  environment:
    - GF_LOG_MODE=console file
    - GF_LOG_LEVEL=info
  volumes:
    - grafana-logs:/var/log/grafana
```

### Prometheus Audit Logs

Monitor Prometheus query logs:
```yaml
prometheus:
  command:
    - --query.log-file=/prometheus/query.log
```

### Alertmanager Audit

Track alert notifications:
```yaml
alertmanager:
  command:
    - --log.level=info
```

---

## 🔍 Security Monitoring

### Monitor for Security Events

Create alerts for:
- Failed login attempts
- Configuration changes
- Unusual query patterns
- High resource usage (potential DoS)

**Example alert:**
```yaml
- alert: GrafanaFailedLogins
  expr: increase(grafana_api_response_status_total{status="401"}[5m]) > 5
  annotations:
    summary: "Multiple failed login attempts to Grafana"
```

---

## 📋 Security Checklist

### Pre-Production

- [ ] Change all default passwords
- [ ] Enable TLS/HTTPS
- [ ] Configure authentication
- [ ] Set up firewall rules
- [ ] Implement secrets management
- [ ] Enable audit logging
- [ ] Configure backup encryption
- [ ] Review file permissions (chmod 600 .env)
- [ ] Scan Docker images for vulnerabilities
- [ ] Document security procedures

### Regular Maintenance

- [ ] Rotate credentials quarterly
- [ ] Update Docker images monthly
- [ ] Review access logs weekly
- [ ] Test backup restoration monthly
- [ ] Update TLS certificates before expiry
- [ ] Review and update firewall rules
- [ ] Audit user access quarterly

---

## 🚨 Incident Response

### Compromised Credentials

1. Immediately rotate all passwords
2. Review audit logs for unauthorized access
3. Check for configuration changes
4. Verify alert rules haven't been modified
5. Restore from known-good backup if needed

### Unauthorized Access

1. Block source IP in firewall
2. Review and strengthen authentication
3. Enable MFA if not already enabled
4. Audit all user accounts
5. Review recent dashboard and query changes

---

## 📚 Additional Resources

- [Grafana Security](https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/)
- [Prometheus Security Model](https://prometheus.io/docs/operating/security/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [OWASP Docker Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
