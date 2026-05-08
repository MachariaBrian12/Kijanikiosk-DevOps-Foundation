# KijaniKiosk Deployment: Week 7 vs Week 8

**Prepared for:** Nia — Board Presentation Monday
**Date:** 2026-05-08
**Word count:** 712

---

## What Changed and Why It Matters

Last week, the engineering team demonstrated that the payments service could deploy a new version, detect a failure automatically, and recover without human intervention — all within 14 seconds. That was a significant step forward. However, the approach had a fundamental limitation: the system ran as a single copy of the application on a single server. If that server went down, or if the application crashed and the recovery mechanism itself failed, there was no backup. The business was one hardware failure away from a complete outage.

This week, the team moved the payments service into a container — a self-contained, portable package that includes everything the application needs to run. That container is now managed by an orchestration platform that runs two identical copies of the service simultaneously. If one copy fails, the other continues serving requests while the platform automatically starts a replacement. The board does not need to understand how this works at a technical level. What matters is the outcome: the payments service now has a built-in redundancy that was absent last week.

The container packaging also produced a measurable reduction in the software's footprint. The original application image, built without optimisation, weighed approximately 1.1 gigabytes. The production image built this week, using a two-stage process that strips out everything not needed at runtime, is 44.9 megabytes — a reduction of over 95%. Smaller images pull faster, start faster, and present a smaller surface for security vulnerabilities.

The self-healing capability was measured during today's verification. When one of the two running copies was forcibly removed to simulate a crash, the platform detected the missing copy and had a replacement running and serving requests within 77 seconds, with no human involvement.

---

## Comparison Table

| Concern              | Week 7 Approach                                                                                                              | Week 8 Approach                                                                                                                                                       |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Deployment mechanism | Bash scripts switched traffic between two manually configured application instances on a single server                       | A container image built from a versioned Dockerfile is deployed to an orchestration platform, which manages scheduling, placement, and lifecycle automatically        |
| Rollback mechanism   | Automated monitor detected health check failures and switched traffic back to the previous version within 14 seconds         | The orchestration platform maintains the previous replica set during updates; a rollback is a single declarative command that re-activates the previous version       |
| Failure recovery     | A monitoring script polled the health endpoint and triggered a rollback script when three consecutive failures were detected | The platform continuously monitors all running copies and replaces any that stop responding, without any external script required. Measured recovery time: 77 seconds |
| Scaling              | Fixed at two environments (blue and green); adding capacity required manual server provisioning                              | Replica count is a single number in a configuration file; the platform distributes additional copies across available capacity automatically                          |

---

## What Week 8 Does Not Yet Solve

The deployment is not production-complete. The application's configuration — the port it listens on, any environment-specific settings — is currently hardcoded into the deployment definition. This means changing any configuration value requires rebuilding and redeploying the manifest, which is the same class of problem as hardcoding values in source code. The service also has no persistent storage, no database connection, and no external secrets management: credentials cannot yet be injected securely at runtime. Week 9 introduces the tooling to separate configuration from deployment definitions, store sensitive values in an encrypted store, and inject both into the running application without rebuilding the image. Until that work is complete, the current deployment is suitable for demonstrating the architecture but is not ready to handle real payment data.

---

_This document was prepared from lab evidence collected on 2026-05-08. The 44.9MB image size and 77-second recovery time are measured values, not estimates._
