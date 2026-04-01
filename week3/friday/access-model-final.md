# Access Model - Final

## Directory Structure and Ownership

| Directory | Owner | Group | Permissions |
|-----------|-------|-------|-------------|
| /opt/kijanikiosk | root | kijanikiosk | 750 |
| /opt/kijanikiosk/shared | root | kijanikiosk | 750 |
| /opt/kijanikiosk/shared/logs | root | kijanikiosk | 770 |
| /opt/kijanikiosk/config | root | kijanikiosk | 750 |
| /opt/kijanikiosk/health | kk-logs | kijanikiosk | 750 |

## ACL Model

### /opt/kijanikiosk/shared/logs
- kk-api: rwx (writes log entries)
- kk-payments: rx (reads logs for audit correlation)
- kk-logs: rx (reads logs for aggregation)
- Default ACLs set so new files inherit these permissions automatically

### /opt/kijanikiosk/config
- kk-api: rx (reads api.env)
- kk-payments: rx (reads payments-api.env)
- kk-logs: rx (reads logs.env)
- Config files: 640 (root:kijanikiosk) - group can read, others cannot

### /opt/kijanikiosk/health (added Friday)
- kk-logs: rwx (writes health check JSON)
- kijanikiosk group: rx (monitoring and admin can read)
- health JSON file: 640 (kk-logs:kijanikiosk)
- No ACLs needed - group permission covers read access

## Logrotate Interaction

Logrotate runs daily and rotates /opt/kijanikiosk/shared/logs/*.log.
The logrotate config includes:
- su root kijanikiosk: runs as root with kijanikiosk group
- create 0660 kk-api kijanikiosk: new files owned by kk-api
- Default ACLs on the directory ensure new files inherit kk-payments
  and kk-logs read access automatically

Verified: sudo -u kk-api touch test-write.tmp after forced rotation = PASS

## Environment Config Files

| File | Owner | Permissions | Read by |
|------|-------|-------------|---------|
| /opt/kijanikiosk/config/api.env | root:kijanikiosk | 640 | kk-api |
| /opt/kijanikiosk/config/payments-api.env | root:kijanikiosk | 640 | kk-payments |
| /opt/kijanikiosk/config/logs.env | root:kijanikiosk | 640 | kk-logs |
