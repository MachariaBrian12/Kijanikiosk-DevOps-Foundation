# Integration Notes - Four Challenges

## Challenge A: ProtectSystem and EnvironmentFile
Conflict: ProtectSystem=strict makes /etc read-only. Config files stored under /etc would be unreadable by the service.
Options: (1) Store under /etc with ReadWritePaths, (2) Store under /opt/kijanikiosk/config/
Decision: Chose option 2. The /opt path is application territory. Punching holes in ProtectSystem defeats its purpose.

## Challenge B: Monitoring User and ACL Defaults
Conflict: Phase 8 writes health JSON as root. Monitoring needs to read it without sudo.
Options: (1) chmod 644 world-readable, (2) chown kk-logs:kijanikiosk chmod 640
Decision: Chose option 2 - least privilege. Any kijanikiosk group member can read it.

## Challenge C: logrotate postrotate and PrivateTmp
Conflict: kk-logs has PrivateTmp=yes. Without ExecReload= in the unit, systemctl reload fails silently.
Options: (1) systemctl kill --signal=HUP, (2) Add ExecReload=/bin/kill -HUP to unit, (3) systemctl restart
Decision: Chose option 2. Added ExecReload=/bin/kill -HUP to kk-logs.service. PrivateTmp does not affect signal delivery.

## Challenge D: Dirty VM and Package Holds
Conflict: Packages may already be installed or accidentally upgraded on a dirty VM.
Options: (1) Check version first and fail loudly if wrong, (2) Run apt-get install then set hold immediately
Decision: Chose option 2 for simplicity. apt-get install is idempotent. Hold is set immediately after install.
