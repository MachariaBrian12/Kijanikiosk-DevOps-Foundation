# Board Demonstration Script — KijaniKiosk Deployment Pipeline
**Monday board meeting | Presenter: Nia | Pipeline operator: Brian**

---

**Beat 1 — Introduction**

[Nia stands. The staging environment dashboard is visible on the main screen. Brian is at the keyboard.]

Good morning. What you are about to see is our system handling a software failure on its own, without anyone having to intervene. I want to walk you through each step so you understand exactly what the business protection looks like in practice.

---

**Beat 2 — Deploy new version**

[Brian runs the deployment script. The green environment health endpoint refreshes to show v1.4.0.]

Brian has just placed our new software version onto a separate, isolated copy of the system. It is running and passing its health checks, but no customer traffic is touching it yet. The current version is still serving all requests.

---

**Beat 3 — Switch traffic**

[Brian runs switch-env.sh green. Nia points to the version shown on the proxy health check: v1.4.0.]

Now we have moved all traffic across to the new version. Every payment request is being handled by the updated software. You can see the version number has changed on screen.

---

**Beat 4 — Fault introduction**

[Brian runs: sudo systemctl stop kk-api-green.service. The monitor begins logging failures.]

We have just simulated a critical fault in the new version — the kind of problem that would cause payments to fail. Our monitoring system is now watching for failures.

---

**Beat 5 — Automated rollback**

[Monitor logs show 3 consecutive failures. Rollback fires automatically. Proxy returns v1.3.0.]

Without anyone touching a keyboard, the system detected the failure and switched all traffic back to the previous version. No one made that decision. The system made it automatically.

---

**Beat 6 — Business value summary**

[Nia turns to face the board. The proxy health check on screen shows v1.3.0. Brian points to the evidence log on a second monitor.]

From the moment the fault appeared to the moment the system restored safe service: fourteen seconds. At our current transaction volume, that means the system is protecting us from thousands of failed payments that would otherwise require customer service calls, refunds, and reputational damage. This does not require an engineer to be awake. It runs every time we deploy. That is what I told the board we had built, and that is what you just watched.

---

[End of demonstration. Brian can display rollback-evidence.txt to show the 14-second timestamp evidence if board members ask for the source.]
