# kk-payments SLI and SLO Definitions

**Service:** kk-payments
**Owner:** Platform Engineering
**Date:** 2026-05-07
**Review cycle:** 30 days

---

## SLI 1 — Availability

**What we measure:** Whether the payment service is successfully responding to requests over time.

**Data source:** nginx access logs and /health endpoint responses.

**What counts as success:** HTTP 200 response from the active environment within a 2-second timeout.

**What counts as failure:** HTTP 502, 503, 504, or connection refused. During rollback testing, nginx returned 502 when the green service stopped responding.

**Measurement interval:** Every 5 seconds.

**Measurement window:** Rolling 30-day window.

**Formula:** Availability = (Successful health checks returning HTTP 200) / (Total health checks attempted) x 100

**SLO Target:** 99.9% over 30 days.

**Error budget:** 43.2 minutes of downtime permitted per 30-day window.

---

## SLI 2 — Latency

**What we measure:** Response time for payment API requests (POST /payments), not health checks.

**Data source:** nginx access log $request_time field for all POST /payments requests.

**Acceptable latency threshold:** 300ms. Users expect payments to feel instant. Anything above 500ms feels noticeably slow. 300ms leaves buffer for frontend rendering, network delays, database queries, and load spikes. The 95% threshold accepts that occasional spikes are normal during deployments.

**Measurement window:** Rolling 30-day window.

**Formula:** Latency SLI = (POST /payments requests completing under 300ms) / (Total POST /payments requests) x 100

**SLO Target:** 95% of payment requests complete under 300ms over 30 days.

---

## SLI 3 — Payment Error Rate

**What we measure:** The proportion of payment requests that result in server-side failures.

**Data source:** nginx access log HTTP status codes for POST /payments requests.

**What counts as an error:** HTTP 5xx responses (500, 502, 503, 504) — server or infrastructure failures.

**What we explicitly exclude:** HTTP 4xx responses. These are client errors (bad input, unauthorized access, invalid card) and represent correct system behaviour, not reliability failures.

**Measurement window:** Rolling 30-day window.

**Formula:** Payment Error Rate = (5xx Payment Responses) / (Total Payment Requests) x 100

**SLO Target:** Error rate below 1% over 30 days (99% success rate).

---

## SLO Targets Summary

| SLI | Signal | 30-Day Target | Error Budget |
|-----|--------|---------------|--------------|
| Availability | % health checks returning HTTP 200 | 99.9% | 43.2 minutes downtime |
| Latency | % POST /payments under 300ms | 95.0% | 5 in 100 requests may be slow |
| Payment Error Rate | % POST /payments not returning 5xx | 99.0% | 1 in 100 payment requests may fail |

---

## Rollback Threshold Table

| SLI | SLO Target | Rollback Threshold | Justification |
|-----|------------|-------------------|---------------|
| Availability | 99.9% | 3 consecutive health check failures (15 seconds) | 3 failures x 5-second polling = 15 seconds. At 50,000 req/hr this caps exposure to ~208 failed requests before rollback fires. |
| Latency | 95.0% | More than 50% of requests exceed 300ms in a 2-minute window | A jump from under 5% to over 50% indicates a deployment fault, not normal load variation. |
| Payment Error Rate | 99.0% | More than 5% server error rate sustained over a 2-minute window | Five times the SLO error tolerance. A new version producing 5%+ server errors in its first 2 minutes is almost certainly a deployment fault. |

---

## What We Do Not Commit To

**1. Upstream payment provider availability**
We do not commit to an SLO covering third-party payment gateway responses. kk-payments proxies these requests but cannot control their reliability. Including them would make our error budget dependent on variables we cannot fix.

**2. End-to-end transaction confirmation time**
We do not commit to a latency SLO covering the full time from a user clicking Pay to receiving confirmation. This includes browser rendering, network round-trips outside our infrastructure, and third-party callback delays. Our latency SLI covers only server-side processing time at the nginx proxy layer.

**3. Database query performance**
We do not commit to a direct SLO on database query latency. These are monitored as supporting signals and will surface in the latency SLI if they degrade, but a separate database SLO would create overlapping targets that complicate incident triage.

---

*Next review date: 2026-06-07*
