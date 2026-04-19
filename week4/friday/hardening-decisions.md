# KijaniKiosk Staging Environment: Hardening Decisions

**Prepared for:** Nia Kamau, Chief Executive Officer
**Prepared by:** Amina (Engineering)
**Environment:** Staging — three servers (api, payments, logs)

---

## What This Document Covers

This document explains every security decision made in building KijaniKiosk's staging environment. Each decision is written in plain terms alongside the specific risk it addresses. The final section is an honest account of what this setup does not yet protect against.

---

## Security Controls at a Glance

| Control | What it does | Risk mitigated |
|---|---|---|
| SSH restricted to operator IP | Only the engineer's specific network address can open a remote connection to the servers. Everyone else is blocked at the network boundary. | Prevents automated scanning tools and opportunistic attackers from attempting to break in over the internet. |
| Encrypted remote state storage | The record of what infrastructure exists is stored in a locked, encrypted location that requires authentication to read or modify. | Prevents a second engineer from accidentally overwriting infrastructure changes made by the first, and protects sensitive configuration values from being read by unauthorised parties. |
| State locking | Only one infrastructure change can run at a time. A second attempt is rejected until the first completes. | Eliminates the risk of two simultaneous changes corrupting the environment into an unknown state. |
| Dedicated service account | The payments service runs as its own user with no ability to log in interactively or access other parts of the system. | Limits the blast radius if the payments service is compromised — an attacker gains access only to that account, not the whole server. |
| Payments service filesystem restriction | The payments service can read and write only the specific folder it needs. The rest of the server's storage is invisible to it. | Prevents a compromised payments process from reading configuration files, credentials, or logs belonging to other services. |
| No new privilege escalation | The payments service cannot grant itself or any process it starts additional permissions beyond what it was given at launch. | Closes a common attack path where malicious code attempts to elevate its own access level after it is already running. |
| Firewall default-deny policy | All network traffic to the servers is blocked unless it has been explicitly permitted. Permitted traffic covers only remote administration and web requests. | Reduces the number of ways an attacker can reach the servers. Anything not on the approved list is invisible from the network. |
| Persistent audit logs | Server activity logs are written to permanent storage and rotated on a schedule so old logs are compressed and retained for two weeks. | Ensures that if something goes wrong, there is a record to investigate. Logs that disappear on restart cannot support an incident review. |
| Environment file permissions | The file containing the payments service configuration values is readable only by the payments service account and no other user. | Prevents other processes or logged-in users from reading connection strings, internal addresses, or other values that could assist an attacker. |

---

## How the Pieces Work Together

The controls above are not independent. They are designed to slow an attacker at each stage of a potential intrusion. The network boundary makes it difficult to reach the servers at all. If that boundary were crossed, the service account and filesystem restrictions limit what could be accessed. If a service were compromised, the privilege controls prevent the damage from spreading. The logs ensure that any of these events leaves a trace.

This layered approach means that no single failure opens the entire environment. Each layer assumes the previous one may eventually be overcome.

## The kk-payments Security Score

The payments service achieved a score of 1.8 on the independent security assessment tool, against a target of below 2.5. This score reflects the combination of filesystem isolation, privilege restrictions, and system call filtering applied to that service. The service starts correctly and passes all health checks with these controls active.

---

## What This Posture Does Not Protect Against

This staging environment was built to prove reproducibility and establish a security baseline. It does not yet address several risks that a production environment would require. There is no encryption of data while it is stored on the servers — only the state file and the environment configuration are protected at rest. There is no monitoring or alerting system, meaning that unusual activity would not be detected until someone manually reviewed the logs. The servers run a placeholder process rather than real application code, so application-layer vulnerabilities have not been assessed. Finally, the SSH restriction relies on the operator's network address remaining constant — if that address changes, access is lost until the infrastructure is updated. These gaps are known and accepted for a staging environment. Each would need to be closed before handling real customer data.
