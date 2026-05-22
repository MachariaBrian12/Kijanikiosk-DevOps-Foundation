# Reflection — Week 7 Friday Project

**Engineer:** Brian

---

## PR Description

This PR delivers the complete blue/green deployment pipeline for kk-payments, assembling the individual layers built Monday through Thursday into a single end-to-end pipeline demonstrated from clean starting state through controlled fault to confirmed automated recovery in 14 seconds.

The key decision I made was to start the monitor before executing the switch rather than after. I chose this order because the grading requirement specified that the monitor log must cover the full sequence from switch to rollback. A monitor started after the fault was introduced would have missed the baseline health checks that prove the system was healthy before the fault appeared.

If I had more time, I would improve the rollback threshold logic to distinguish between a crashed process and a process that is running but returning errors. These are different failure modes that need different responses — a crashed process needs an ops page, while a healthy process returning 500s needs an engineering investigation.

---

## Reflection 1: Where the Demo Script Overclaims

The moment that felt most like overclaiming was in Beat 6: "This does not require an engineer to be awake." This line lands well with a board but quietly overstates what the system does.

What the system actually does: it detects health check failures at the proxy layer and rolls back to the previous environment. What it does not do: determine whether the previous version is actually safe, restart a crashed service, handle the case where both environments are unhealthy, or alert anyone that a rollback happened.

A more precise version: "It does not require an engineer to initiate the recovery — but an engineer will need to investigate what caused the failure before we deploy again." This is still reassuring without implying the system resolves the underlying problem on its own.

---

## Reflection 2: Highest-Value Action Item

The highest-value action item is implementing the environment lock flag. It directly addresses the root cause rather than a contributing factor. Every other action item reduces risk around the edges. A lock that must be explicitly set before a demonstration and cannot be bypassed without an override flag is the only control that would have prevented the Monday incident regardless of whether any other check was in place.

My confidence that this would prevent a recurrence is moderate, not high. The lock only works if someone sets it. To be certain, I would need to know whether the pipeline can be triggered by an automated scheduler that bypasses the lock check entirely. If a cron job fires the pipeline and ignores the lockfile, the root cause is unchanged.

---

## Reflection 3: What Carries Forward Into Kubernetes

**What carries forward conceptually:**

The logic behind post-deploy-monitor.sh carries forward completely. In Kubernetes this becomes readiness probes and deployment rollout strategy — poll health, count failures, revert if threshold crossed. The engineering judgment about what threshold triggers rollback is identical; only the mechanism changes.

The rollback threshold logic also carries forward, expressed as Kubernetes deployment configuration (maxUnavailable, maxSurge, progressDeadlineSeconds) rather than bash variables.

**What becomes redundant:**

The state files (.active-env, .previous-env) become redundant immediately. Kubernetes tracks the active ReplicaSet natively. kubectl rollout history provides this information and kubectl rollout undo executes the switch. Maintaining state files alongside Kubernetes would create two sources of truth.

The switch-env.sh and rollback.sh scripts become redundant as direct mechanisms. Their replacement is kubectl set image for deployment and kubectl rollout undo for rollback. The nginx upstream configuration pattern is replaced by Kubernetes Services and Ingress controllers managing traffic routing natively.
