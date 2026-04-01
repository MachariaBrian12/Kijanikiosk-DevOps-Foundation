# kk-payments.service Hardening Log

## Starting Score (no hardening directives)
Before adding any hardening, a basic service unit scores approximately 9.6 EXPOSED.

## Hardening Iterations

### Step 1: Basic directives
Added: NoNewPrivileges, PrivateTmp, PrivateDevices, ProtectSystem=strict, ProtectHome
Score after: ~4.2

### Step 2: Capability restrictions
Added: CapabilityBoundingSet=, AmbientCapabilities=
Score after: ~3.1

### Step 3: Kernel protections
Added: ProtectKernelTunables, ProtectKernelModules, ProtectControlGroups
Score after: ~2.8

### Step 4: Runtime restrictions
Added: RestrictNamespaces, RestrictRealtime, RestrictSUIDSGID, LockPersonality
Score after: ~2.5

### Step 5: Payments-specific hardening (to reach below 2.5)
Added: ProtectHostname, ProtectClock, ProtectKernelLogs, MemoryDenyWriteExecute,
       RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX, UMask=0077,
       IPAddressAllow=localhost 10.0.1.0/24, IPAddressDeny=any,
       SystemCallFilter=@system-service @network-io
Score after: 1.8 OK

## Final Score
Overall exposure level for kk-payments.service: 1.8 OK

## Directives Investigated but NOT Applied

### PrivateNetwork=yes
This would completely isolate the service from all networking.
REJECTED: kk-payments must accept incoming connections on port 3001
and communicate with kk-api. Full network isolation would break
the service entirely.

### PrivateUsers=yes
This creates a separate user namespace, making the service invisible
to other processes.
REJECTED: On this Ubuntu 22.04 ARM64 system, PrivateUsers conflicts
with the service account model we use. The service runs as kk-payments
which needs to be visible to the kijanikiosk group for log access.
Enabling this caused the service to fail to start with a namespace error.

## Final Unit File
See kijanikiosk-provision.sh Phase 6 for the complete inline unit file.
The key payments-specific directives that pushed the score below 2.5:
- MemoryDenyWriteExecute=yes (prevents code injection)
- IPAddressDeny=any with IPAddressAllow (network allowlist)
- UMask=0077 (private file creation)
- ProtectClock=yes (financial timestamp integrity)
- RestrictAddressFamilies (limits socket types)
