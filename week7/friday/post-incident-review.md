# Post-Incident Review — Week 5 Monday Morning Incident

**Incident reference:** KK-INC-005
**Date of incident:** Week 5, Monday
**Prepared by:** Brian
**Review completed:** 2026-05-07
**Status:** Final

---

## Section 1: Incident Summary

During Nia's live investor demonstration on Monday morning, the automated deployment pipeline was triggered against the staging environment while it was actively being used for the demonstration, causing 48 seconds during which the environment served errors instead of a working product. The pipeline targeted the wrong environment because there was no mechanism to prevent a deployment from running while a named environment was in active use by a stakeholder. The error was resolved when an engineer manually stopped the pipeline and confirmed the staging environment had returned to a healthy state.

---

## Section 2: Incident Timeline

All times are EAT. Timestamps marked (estimated) could not be reconstructed precisely and are based on the course narrative.

| Time | Event |
|------|-------|
| 09:00 (estimated) | Nia begins investor walkthrough of the KijaniKiosk staging environment. |
| 09:07 (estimated) | Automated deployment pipeline is triggered without checking whether staging was in active use. |
| 09:07 (estimated) | Pipeline identifies staging as the target environment and begins deploying. |
| 09:08 (estimated) | Deployment process interrupts the live environment. Requests from Nia's walkthrough begin returning errors. |
| 09:08 (estimated) | Error detected by engineer monitoring a dashboard. |
| 09:08:48 (estimated) | Engineer manually stops the pipeline. Normal service confirmed restored. Total visible error duration: 48 seconds. |
| 09:09 (estimated) | Nia confirms to investors that the environment is healthy and attempts to continue the demonstration. |
| 09:15 (estimated) | Post-incident channel discussion begins. Tendo flags the need for environment locking and a formal incident review. |

---

## Section 3: Root Cause

The deployment pipeline had no mechanism to verify whether the target environment was in active use before beginning execution. The pipeline read the target environment from a configuration variable and proceeded to deploy without checking the .active-env state file, without querying whether a stakeholder session was in progress, and without requiring a human confirmation step.

The specific configuration gap: the pipeline confirmed the target environment was reachable and healthy, but did not confirm it was safe to disrupt. Reachable and safe-to-modify are not the same condition. The pipeline conflated them.

This is not a human error. No individual made a mistake. The pipeline behaved exactly as it was configured to behave. The configuration did not include a concept of environment lock or deployment freeze.

---

## Section 4: Contributing Factors

**1. No deployment freeze capability existed.**
The pipeline had no flag or command that would prevent it from running against a given environment for a defined period.

**2. No shared calendar or event register was integrated with the pipeline.**
The team knew about the investor demonstration but this knowledge existed only in a calendar and in people's heads. The pipeline had no access to this information.

**3. The default deployment target was the staging environment.**
If the pipeline was triggered without an explicit environment argument, it defaulted to staging — the environment most likely to be in active use for demonstrations.

**4. Automated rollback was not yet in place.**
Recovery depended on an engineer recognising the failure and stopping the pipeline manually. This extended the disruption window beyond what an automated system would have allowed.

---

## Section 5: What Went Well

The engineer on duty identified the fault within the 48-second window and stopped the pipeline manually before it could complete a full deployment and leave the environment in a partially deployed state. A partial deployment would have required a manual rollback on top of the pipeline stop, extending the disruption significantly. The engineer being present and monitoring during a high-stakes demonstration allowed a faster manual response than the tooling at that point could have provided.

---

## Section 6: Action Items

| # | Action | Owner | Description | Target |
|---|--------|-------|-------------|--------|
| 1 | Implement environment lock flag | Platform Engineering | Add a --lock and --unlock command to the deployment pipeline that writes a lockfile to /opt/kijanikiosk/.env-lock. Any pipeline run that encounters a lockfile on its target environment must exit with a non-zero code and a human-readable error before touching the environment. | End of Week 6 |
| 2 | Remove staging as default deployment target | Platform Engineering | Replace the default with an explicit error: if no --env argument is passed, the pipeline must print an error message and exit without deploying. This eliminates accidental deployment to staging from any unattended or scripted trigger. | End of Week 6 |
| 3 | Add pre-flight active environment check | Platform Engineering | Before any deployment begins, the pipeline must read .active-env and confirm the target environment is not currently receiving live proxy traffic. If it is, the pipeline must require a --force-active flag and print a warning before proceeding. | End of Week 7 |
| 4 | Create pre-demonstration runbook | Engineering Lead | Write a one-page checklist to complete before any stakeholder demonstration: confirm which environment will be used, confirm it is locked, confirm the pipeline cannot run unattended during the demonstration window. | End of Week 5 |
