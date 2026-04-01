nano week3/friday/hardening-decisions.md
```

Go to the end of the file and add this before the last section "What This Posture Does Not Protect Against":
```
## How These Decisions Work Together

Security is most effective when controls reinforce each other. On this server, the decisions above are designed as layers. If an attacker bypasses one layer, the next layer limits what they can do.

For example, if an attacker finds a vulnerability in the API service, they would find themselves running as the kk-api user with no administrator powers, unable to write to system files, unable to see other services' temporary data, and unable to reach the payments service directly. Each restriction is independent, so removing one does not collapse the others.

This layered approach is sometimes called defence in depth. It is the same principle used in physical security — a building with a lock on the front door, a security desk, and locked offices is safer than a building with only a front door lock, even if each individual lock is no stronger.

## How We Verified These Decisions

Every control described in this document was tested, not just configured. The firewall rules were verified programmatically, with each rule checked individually and reported as passing or failing. The access controls were verified by simulating log rotation and confirming that the API service could still write new log entries. The service restrictions were measured using a standard scoring tool and the results are documented separately.

A security posture that has not been tested is a security posture that cannot be trusted. The verification step is not optional — it is how we know the decisions above are actually in effect and not just intended.
# KijaniKiosk Production Server Security Decisions

## Summary

This document explains the security decisions made for the KijaniKiosk production server. Each decision was made to reduce a specific risk to the business. The goal is a server that is difficult to attack, limits damage if attacked, and protects customer payment data.

## What We Protected Against

The payments service handles real money. A security failure here is not a technical inconvenience — it is a regulatory event, a customer trust failure, and a potential legal liability. The decisions below were made with that in mind.

## Security Decisions

| Control | What it does | Risk mitigated |
|---------|-------------|----------------|
| Dedicated service accounts | Each service runs as its own limited user, not as the administrator | If one service is compromised, the attacker cannot access other services or system files |
| Read-only system files | Services cannot modify the operating system files they run on | Prevents attackers from hiding malicious code in system directories |
| Private temporary storage | Each service gets its own isolated scratch space | Prevents services from reading each other's temporary data |
| No new privileges | Services cannot gain more permissions than they started with | Blocks a common attack where software tricks the system into granting it administrator access |
| Strict network rules | The payments service only accepts connections from known internal addresses | Prevents the payments service from being directly reached by anyone on the internet |
| Firewall with documented rules | Every network rule has a written explanation of its purpose | Ensures the security posture reflects deliberate decisions, not accumulated history |
| Log rotation with access controls | Logs are rotated daily and only accessible to authorised services | Prevents log files from filling the disk and limits who can read sensitive operational data |
| Package version pinning | Software versions are locked and cannot be automatically updated | Prevents unexpected behaviour from automatic updates in a production environment |
| Capability removal | Services have no administrator-level operating system powers | Limits the damage an attacker can do even if they fully compromise a service |
| Memory protection on payments | The payments service cannot execute code written into its memory at runtime | Blocks a class of attacks where malicious code is injected into a running process |

## The Payments Service Receives Extra Protection

The payments service handles financial transactions and receives a higher level of restriction than the other services. In addition to the controls above, it is restricted to communicating only with known addresses, cannot change system time (which would affect transaction timestamps), and creates all files in private mode by default.

These additional controls exist because a compromise of the payments service carries greater consequences than a compromise of the logging or API services.

## What This Posture Does Not Protect Against

This configuration protects the server at the operating system level. It does not protect against vulnerabilities in the application code itself. If the payments application has a bug that allows an attacker to manipulate transactions, the server-level controls described here will not prevent that. Application-level security, including input validation, authentication, and secure coding practices, is outside the scope of this document and must be addressed separately before the payments service handles real transactions.
