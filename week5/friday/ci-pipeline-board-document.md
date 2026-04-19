# KijaniKiosk Automated Quality Pipeline

**Prepared for:** Nia Kamau, Chief Executive Officer
**Prepared by:** Amina (Engineering)

---

## What This Is

Every time a developer on the KijaniKiosk team saves their work to the shared codebase, an automated process runs within seconds. That process checks whether the change meets our quality standards, builds a tested and approved version of the software, and stores it in a secure registry ready for deployment. No human reviews the change before this process runs, and no change reaches the registry without passing every check.

This document explains what that process does, what it confirms at each step, and what happens when something does not meet the standard.

---

## From Code to Registry: What Happens

| Stage | What it does | What it confirms |
|---|---|---|
| Style Check | Reads every line of new code before anything is built | The code follows the team's agreed formatting rules. A failure here stops everything immediately, saving time that would otherwise be spent building code we already know is malformed. |
| Build | Compiles the code into the form the server will run | The change does not break the assembly process. The output is a complete, runnable package. |
| Testing | Runs the full suite of automated checks in parallel with a security scan | The software behaves as expected. No known security weaknesses have been introduced. Both checks run at the same time to save time. |
| Storage | Saves the approved build to Jenkins for internal reference | A fingerprinted record of exactly what was built is retained, traceable to the specific code change that produced it. |
| Registry | Publishes the approved version to our secure artifact registry | A uniquely numbered, downloadable package is available for deployment. The version number includes both the software version and the exact code change it came from, so we always know what we are deploying and where it came from. |

Each stage must pass before the next one starts. A failure at any point stops the process and records what went wrong.

---

## What Happens When Something Goes Wrong

When a developer pushes a change that does not meet our standards, the process stops at the point of failure. Nothing beyond that point runs. The failed version is never stored in the registry and can never be deployed.

The developer receives an immediate notification identifying which check failed. If the style check fails, the code never gets built. If the tests fail, nothing gets published. The registry contains only versions that passed every check in sequence.

When a pipeline that was previously failing begins passing again — or vice versa — the team receives a specific notification about that transition. This means the team is not flooded with repeated alerts for a known problem, but is always informed when the situation changes.

This design reflects a deliberate contract: a version in the registry is a version the team has verified. Anything that did not make it to the registry did not meet the standard, and the record of why is retained for review.

---

## What This Pipeline Does Not Yet Do

This pipeline confirms that the software is built correctly and passes its own tests. It does not yet deploy the software to a running environment — that step is planned for the next phase of work. It does not test how the software performs under realistic load, nor does it verify behaviour when external services such as payment processors are unavailable. The security scan checks for known vulnerabilities in the software's dependencies but does not perform a broader assessment of the running system. These are known gaps. Each will be addressed as the platform moves from staging toward production.
