# KijaniKiosk CI Pipeline — Fault Injection Log

## Purpose
Each pipeline stage was faulted independently to verify that failures are caught at the correct point and that downstream stages behave as expected.

---

## Fault Injection Table

| Stage Faulted | How Fault Was Introduced | Stages That Ran | Stages That Skipped | Observed Build Status | Design Rationale |
|---|---|---|---|---|---|
| Lint | Changed `npm run lint` to `npm run lint-fail` (non-existent script) | Lint (red) | Build, Verify, Archive, Publish | FAILURE | Lint runs first by design. A style failure stops the pipeline before spending time on a build that would be rejected anyway. |
| Build | Changed `npm run build` to `exit 1` in the build step | Lint (green), Build (red) | Verify, Archive, Publish | FAILURE | A build failure means there is no output to test or publish. Stopping here prevents the test stage from running against a missing artifact and producing a confusing error. |
| Test | Changed `npm test` to `npm test --testPathPattern=nonexistent` causing zero results and exit 1 | Lint (green), Build (green), Verify/Test (red), Verify/Security Audit (ran to completion) | Archive, Publish | FAILURE | Test failure means the software does not behave as specified. No unverified build should reach the registry. The security audit runs in parallel and completes regardless. |
| Security Audit | Changed `--audit-level=high` to `--audit-level=none` then introduced a known vulnerable package | Lint (green), Build (green), Verify/Test (ran), Verify/Security Audit (red) | Archive, Publish | FAILURE | A high-severity vulnerability found during audit must stop the pipeline. Publishing a version with known security weaknesses to the registry would make it available for deployment. |
| Publish | Set NEXUS_URL to an unreachable address | Lint (green), Build (green), Verify (green), Archive (green), Publish (red) | None — all prior stages ran | FAILURE | The publish failure is isolated to the final stage. All prior work completes correctly. The failure is a connectivity or credential problem, not a code quality problem, and is recorded as such. |

---

## Recovery
After each fault, the introduced change was reverted and the pipeline was re-run. Each recovery run produced a green build with `changed` notification fired, confirming the status transition was detected correctly.
