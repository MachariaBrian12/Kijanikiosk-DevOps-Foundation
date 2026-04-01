#!/bin/bash
# KijaniKiosk Production Server Provisioning Script
# Expected dirty conditions found in pre-provisioning audit:
# - No service accounts exist (kk-api, kk-payments, kk-logs): handled in Phase 2
# - No kijanikiosk group exists: handled in Phase 2
# - /opt/kijanikiosk/ does not exist: handled in Phase 3
# - No ACLs set: handled in Phase 3
# - UFW is inactive with no rules: handled in Phase 5
# - No package holds set: handled in Phase 1
# - No systemd units exist: handled in Phase 6

set -euo pipefail

# ─── Logging helpers ───────────────────────────────────────────
log()     { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
success() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ $*"; }
error()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✗ $*" >&2; exit 1; }

log "========================================"
log "KijaniKiosk Provisioning Script Starting"
log "========================================"

# ─── Phase 1: Package Installation & Pinning ───────────────────
log "--- Phase 1: Package Installation & Pinning ---"

PACKAGES=(nginx curl ufw acl)

for pkg in "${PACKAGES[@]}"; do
  if dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
    log "Already installed: $pkg"
  else
    log "Installing: $pkg"
    apt-get install -y "$pkg"
  fi
done

# Pin packages to current installed versions
for pkg in nginx curl; do
  if apt-mark showhold | grep -q "^${pkg}$"; then
    log "Already held: $pkg"
  else
    apt-mark hold "$pkg"
    success "Held: $pkg"
  fi
done

success "Phase 1 complete"

# ─── Phase 2: Service Accounts & Group ────────────────────────
log "--- Phase 2: Service Accounts & Group ---"

# Create group if it doesn't exist
if getent group kijanikiosk > /dev/null 2>&1; then
  log "Already exists: group kijanikiosk"
else
  groupadd --system kijanikiosk
  success "Created group: kijanikiosk"
fi

# Create service accounts if they don't exist
for user in kk-api kk-payments kk-logs; do
  if id "$user" > /dev/null 2>&1; then
    log "Already exists: user $user"
  else
    useradd \
      --system \
      --no-create-home \
      --shell /usr/sbin/nologin \
      --gid kijanikiosk \
      "$user"
    success "Created user: $user"
  fi
done

# Ensure all users are in the kijanikiosk group
for user in kk-api kk-payments kk-logs; do
  usermod -aG kijanikiosk "$user"
  success "Confirmed $user in kijanikiosk group"
done

success "Phase 2 complete"

# ─── Phase 3: Directory Structure & ACLs ──────────────────────
log "--- Phase 3: Directory Structure & ACLs ---"

# Create directory structure
for dir in \
  /opt/kijanikiosk \
  /opt/kijanikiosk/shared \
  /opt/kijanikiosk/shared/logs \
  /opt/kijanikiosk/config \
  /opt/kijanikiosk/health; do
  if [ -d "$dir" ]; then
    log "Already exists: $dir"
  else
    mkdir -p "$dir"
    success "Created: $dir"
  fi
done

# Set base ownership — root owns it, kijanikiosk group can access
chown -R root:kijanikiosk /opt/kijanikiosk
chmod -R 750 /opt/kijanikiosk

# shared/logs — kk-api writes, kk-payments and kk-logs read
chown root:kijanikiosk /opt/kijanikiosk/shared/logs
chmod 770 /opt/kijanikiosk/shared/logs

# Set ACLs on shared/logs
setfacl -m u:kk-api:rwx /opt/kijanikiosk/shared/logs
setfacl -m u:kk-payments:rx /opt/kijanikiosk/shared/logs
setfacl -m u:kk-logs:rx /opt/kijanikiosk/shared/logs

# Set DEFAULT ACLs so new files inherit these permissions
setfacl -d -m u:kk-api:rwx /opt/kijanikiosk/shared/logs
setfacl -d -m u:kk-payments:rx /opt/kijanikiosk/shared/logs
setfacl -d -m u:kk-logs:rx /opt/kijanikiosk/shared/logs

# config — only service accounts can read their own config
chown root:kijanikiosk /opt/kijanikiosk/config
chmod 750 /opt/kijanikiosk/config
setfacl -m u:kk-api:rx /opt/kijanikiosk/config
setfacl -m u:kk-payments:rx /opt/kijanikiosk/config
setfacl -m u:kk-logs:rx /opt/kijanikiosk/config

# health — kk-logs writes, kijanikiosk group reads
chown kk-logs:kijanikiosk /opt/kijanikiosk/health
chmod 750 /opt/kijanikiosk/health
setfacl -m u:kk-logs:rwx /opt/kijanikiosk/health
setfacl -m g:kijanikiosk:rx /opt/kijanikiosk/health

# Create environment config files if they don't exist
for envfile in api.env payments-api.env logs.env; do
  if [ -f "/opt/kijanikiosk/config/${envfile}" ]; then
    log "Already exists: /opt/kijanikiosk/config/${envfile}"
  else
    touch "/opt/kijanikiosk/config/${envfile}"
    chown root:kijanikiosk "/opt/kijanikiosk/config/${envfile}"
    chmod 640 "/opt/kijanikiosk/config/${envfile}"
    success "Created: /opt/kijanikiosk/config/${envfile}"
  fi
done

success "Phase 3 complete"

# ─── Phase 4: Nginx Configuration ─────────────────────────────
log "--- Phase 4: Nginx Configuration ---"

# Write nginx config for kijanikiosk
cat > /etc/nginx/sites-available/kijanikiosk << 'NGINX'
server {
    listen 80;
    server_name _;

    # Proxy API service
    location /api/ {
        proxy_pass http://localhost:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # Payments proxied only from loopback
    location /payments/ {
        proxy_pass http://localhost:3001/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        allow 127.0.0.1;
        deny all;
    }
}
NGINX

# Enable the site
if [ -L /etc/nginx/sites-enabled/kijanikiosk ]; then
  log "Already enabled: nginx kijanikiosk site"
else
  ln -s /etc/nginx/sites-available/kijanikiosk \
        /etc/nginx/sites-enabled/kijanikiosk
  success "Enabled: nginx kijanikiosk site"
fi

# Remove default site if present
if [ -L /etc/nginx/sites-enabled/default ]; then
  rm /etc/nginx/sites-enabled/default
  success "Removed: nginx default site"
else
  log "Already removed: nginx default site"
fi

# Test nginx config
nginx -t && success "Nginx config valid" || error "Nginx config invalid"

# Enable and start nginx
systemctl enable nginx
systemctl restart nginx
success "Nginx running"

success "Phase 4 complete"

# ─── Phase 5: Firewall Configuration ──────────────────────────
log "--- Phase 5: Firewall Configuration ---"

# Reset UFW to clean baseline — removes all history
ufw --force reset
success "UFW reset to clean baseline"

# Set default policies
ufw default deny incoming
ufw default allow outgoing
success "Default policies set"

# Allow SSH — must be first to avoid lockout
ufw allow 22/tcp comment 'SSH access for administration'
success "Rule added: SSH (22)"

# Allow HTTP for public web traffic via nginx
ufw allow 80/tcp comment 'HTTP public web traffic via nginx'
success "Rule added: HTTP (80)"

# Allow monitoring subnet to reach kk-api health check
ufw allow from 10.0.1.0/24 to any port 3000 comment 'Monitoring subnet access to kk-api'
success "Rule added: kk-api monitoring (3000 from 10.0.1.0/24)"

# Allow loopback access to kk-payments (nginx proxy)
# IMPORTANT: allow rule must come BEFORE deny rule
ufw allow from 127.0.0.1 to any port 3001 comment 'Loopback access to kk-payments for nginx proxy'
success "Rule added: kk-payments loopback (3001 from 127.0.0.1)"

# Allow monitoring subnet to reach kk-payments health check
ufw allow from 10.0.1.0/24 to any port 3001 comment 'Monitoring subnet health check for kk-payments'
success "Rule added: kk-payments monitoring (3001 from 10.0.1.0/24)"

# Deny port 3001 from all external sources
ufw deny 3001 comment 'Block external access to kk-payments internal port'
success "Rule added: deny external kk-payments (3001)"

# Enable UFW
ufw --force enable
success "UFW enabled"

success "Phase 5 complete"

# ─── Phase 6: Systemd Unit Files ──────────────────────────────
log "--- Phase 6: Systemd Unit Files ---"

# ── kk-api.service ────────────────────────────────────────────
cat > /etc/systemd/system/kk-api.service << 'UNIT'
[Unit]
Description=KijaniKiosk API Service
After=network.target

[Service]
Type=simple
User=kk-api
Group=kijanikiosk
EnvironmentFile=/opt/kijanikiosk/config/api.env
ExecStart=/usr/bin/node /opt/kijanikiosk/api/index.js
Restart=on-failure
RestartSec=5

# Hardening directives (target: below 3.5)
NoNewPrivileges=yes
PrivateTmp=yes
PrivateDevices=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/opt/kijanikiosk/shared/logs
CapabilityBoundingSet=
AmbientCapabilities=
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
RestrictNamespaces=yes
RestrictRealtime=yes
RestrictSUIDSGID=yes
LockPersonality=yes
SystemCallFilter=@system-service
SystemCallErrorNumber=EPERM

[Install]
WantedBy=multi-user.target
UNIT
success "Written: kk-api.service"

# ── kk-payments.service ───────────────────────────────────────
cat > /etc/systemd/system/kk-payments.service << 'UNIT'
[Unit]
Description=KijaniKiosk Payments Service
After=network.target kk-api.service
Wants=kk-api.service

[Service]
Type=simple
User=kk-payments
Group=kijanikiosk
EnvironmentFile=/opt/kijanikiosk/config/payments-api.env
ExecStart=/usr/bin/node /opt/kijanikiosk/payments/index.js
Restart=on-failure
RestartSec=5

# Hardening directives (target: below 2.5)
NoNewPrivileges=yes
PrivateTmp=yes
PrivateDevices=yes
PrivateNetwork=no
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/opt/kijanikiosk/shared/logs
CapabilityBoundingSet=
AmbientCapabilities=
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
ProtectHostname=yes
ProtectClock=yes
ProtectKernelLogs=yes
RestrictNamespaces=yes
RestrictRealtime=yes
RestrictSUIDSGID=yes
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
LockPersonality=yes
MemoryDenyWriteExecute=yes
SystemCallFilter=@system-service @network-io
SystemCallErrorNumber=EPERM
UMask=0077
IPAddressAllow=localhost 10.0.1.0/24
IPAddressDeny=any

[Install]
WantedBy=multi-user.target
UNIT
success "Written: kk-payments.service"

# ── kk-logs.service ───────────────────────────────────────────
cat > /etc/systemd/system/kk-logs.service << 'UNIT'
[Unit]
Description=KijaniKiosk Log Aggregation Service
After=network.target

[Service]
Type=simple
User=kk-logs
Group=kijanikiosk
EnvironmentFile=/opt/kijanikiosk/config/logs.env
ExecStart=/usr/bin/node /opt/kijanikiosk/logs/index.js
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=5

# Hardening directives (target: below 3.5)
NoNewPrivileges=yes
PrivateTmp=yes
PrivateDevices=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/opt/kijanikiosk/shared/logs /opt/kijanikiosk/health
CapabilityBoundingSet=
AmbientCapabilities=
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
RestrictNamespaces=yes
RestrictRealtime=yes
RestrictSUIDSGID=yes
LockPersonality=yes
SystemCallFilter=@system-service
SystemCallErrorNumber=EPERM

[Install]
WantedBy=multi-user.target
UNIT
success "Written: kk-logs.service"

# Reload systemd to pick up new units
systemctl daemon-reload
success "Systemd daemon reloaded"

# Enable all services (don't start — no app code deployed yet)
for svc in kk-api kk-payments kk-logs; do
  systemctl enable "$svc"
  success "Enabled: $svc"
done

success "Phase 6 complete"

# ─── Phase 7: Journal Persistence & Log Rotation ──────────────
log "--- Phase 7: Journal Persistence & Log Rotation ---"

# Configure persistent journal storage capped at 500MB
mkdir -p /var/log/journal
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/kijanikiosk.conf << 'JOURNAL'
[Journal]
Storage=persistent
SystemMaxUse=500M
SystemKeepFree=100M
SystemMaxFileSize=50M
JOURNAL
success "Journal persistence configured (500MB cap)"

# Restart journald to apply changes
systemctl restart systemd-journald
success "journald restarted"

# Write logrotate config for all three services
cat > /etc/logrotate.d/kijanikiosk << 'LOGROTATE'
/opt/kijanikiosk/shared/logs/*.log {
    su root kijanikiosk
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0660 kk-api kijanikiosk
    sharedscripts
    postrotate
        systemctl reload kk-logs.service 2>/dev/null || true
    endscript
}
LOGROTATE
success "Logrotate config written"

# Verify logrotate config is valid
if logrotate --debug /etc/logrotate.d/kijanikiosk 2>&1 | grep -q "error"; then
  error "Logrotate config has errors"
else
  success "Logrotate config valid (--debug passed)"
fi

success "Phase 7 complete"

# ─── Phase 8: Monitoring Health Checks ────────────────────────
log "--- Phase 8: Monitoring Health Checks ---"

mkdir -p /opt/kijanikiosk/health

# Check each service port
api_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/3000" 2>/dev/null && echo '"ok"' || echo '"down"')
payments_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/3001" 2>/dev/null && echo '"ok"' || echo '"down"')
logs_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/3002" 2>/dev/null && echo '"ok"' || echo '"down"')

# Write structured JSON health check file
printf '{"timestamp":"%s","kk-api":%s,"kk-payments":%s,"kk-logs":%s}\n' \
  "$(date -Is)" "$api_status" "$payments_status" "$logs_status" \
  > /opt/kijanikiosk/health/last-provision.json

chown kk-logs:kijanikiosk /opt/kijanikiosk/health/last-provision.json
chmod 640 /opt/kijanikiosk/health/last-provision.json

success "Health check written:"
cat /opt/kijanikiosk/health/last-provision.json

success "Phase 8 complete"

# ─── Final Verification Phase ─────────────────────────────────
log "--- Final Verification ---"

FAILED=0

check() {
  local desc=$1
  local cmd=$2
  if eval "$cmd" > /dev/null 2>&1; then
    success "PASS: $desc"
  else
    log "FAIL: $desc"
    ((FAILED++)) || true
  fi
}

# Phase 1 checks
check "nginx is installed"        "which nginx"
check "curl is installed"         "which curl"
check "nginx is held"             "apt-mark showhold | grep -q nginx"
check "curl is held"              "apt-mark showhold | grep -q curl"

# Phase 2 checks
check "group kijanikiosk exists"  "getent group kijanikiosk"
check "user kk-api exists"        "id kk-api"
check "user kk-payments exists"   "id kk-payments"
check "user kk-logs exists"       "id kk-logs"

# Phase 3 checks
check "/opt/kijanikiosk exists"           "[ -d /opt/kijanikiosk ]"
check "/opt/kijanikiosk/shared/logs exists" "[ -d /opt/kijanikiosk/shared/logs ]"
check "/opt/kijanikiosk/config exists"    "[ -d /opt/kijanikiosk/config ]"
check "/opt/kijanikiosk/health exists"    "[ -d /opt/kijanikiosk/health ]"
check "api.env exists"            "[ -f /opt/kijanikiosk/config/api.env ]"
check "payments-api.env exists"   "[ -f /opt/kijanikiosk/config/payments-api.env ]"

# Phase 4 checks
check "nginx config valid"        "nginx -t"
check "nginx is running"          "systemctl is-active nginx"

# Phase 5 checks
check "UFW is active"             "ufw status | grep -q 'Status: active'"
check "SSH rule exists"           "ufw status | grep -q '22/tcp'"
check "HTTP rule exists"          "ufw status | grep -q '80/tcp'"
check "port 3001 deny exists"     "ufw status | grep -q '3001.*DENY'"

# Phase 6 checks
check "kk-api.service exists"     "[ -f /etc/systemd/system/kk-api.service ]"
check "kk-payments.service exists" "[ -f /etc/systemd/system/kk-payments.service ]"
check "kk-logs.service exists"    "[ -f /etc/systemd/system/kk-logs.service ]"

# Phase 7 checks
check "journal config exists"     "[ -f /etc/systemd/journald.conf.d/kijanikiosk.conf ]"
check "logrotate config exists"   "[ -f /etc/logrotate.d/kijanikiosk ]"
check "logrotate config valid"    "logrotate --debug /etc/logrotate.d/kijanikiosk"

# Phase 8 checks
check "health JSON exists"        "[ -f /opt/kijanikiosk/health/last-provision.json ]"
check "health JSON readable"      "cat /opt/kijanikiosk/health/last-provision.json"

log "========================================"
if [ "$FAILED" -eq 0 ]; then
  success "All verification checks passed!"
else
  error "$FAILED check(s) failed — review output above"
fi
