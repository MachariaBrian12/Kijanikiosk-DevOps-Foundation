# Reflection — Week 8 Friday Project

**Engineer:** Brian
**Date:** 2026-05-08

---

## PR Description

This PR delivers the complete container delivery pipeline for kk-payments: a production-grade image built from a two-stage Dockerfile, pushed to Docker Hub with a semver-SHA tag, deployed to Kubernetes with two replicas, and verified through a NodePort Service. Self-healing was measured at 77 seconds from pod deletion to replacement running.

The key decision was to use Docker Hub as the registry rather than a local registry. Minikube runs in a separate network namespace on Mac, which means a localhost registry is unreachable from inside the cluster. Using Docker Hub meant Minikube could pull the image over the public internet without any additional network configuration. The tradeoff is that the image is public — acceptable for this lab but not for production.

With more time I would add a readiness probe separate from the liveness probe. The current setup uses a liveness probe to detect crashes, but a readiness probe would tell Kubernetes when the pod is actually ready to serve traffic — which may be several seconds after the process starts. This prevents the window where a pod is Running but not yet healthy from receiving requests.

---

## Reflection 1: Hardest Step to Automate

The hardest step to make reliable in a CI/CD pipeline would be the registry push. Every other step — build, tag, deploy — either succeeds or fails cleanly with a clear error. The push can fail silently or partially: individual layers may time out, the connection may drop mid-push, and the resulting error message (EOF) gives no indication of which layers succeeded. In an automated run, a partial push could leave the registry in an inconsistent state where the tag exists but the manifest is incomplete, causing every subsequent pull to fail with a cryptic image-not-found error. The mitigation is a post-push verification step that pulls the image immediately after pushing and confirms the digest matches — exactly what the delete-and-pull cycle in registry-push.txt demonstrates.

---

## Reflection 2: Technical vs Plain Language

Plain language version from the document: "The payments service now has a built-in redundancy that was absent last week."

Technical version for Tendo: "The Deployment spec sets replicas: 2, so the ReplicaSet controller maintains two Pod instances at all times. If a Pod is deleted or its liveness probe fails, the controller schedules a replacement on available nodes. This is active redundancy — both replicas serve traffic simultaneously through the Service — rather than standby redundancy where a backup waits idle."

What is lost in the translation: the distinction between active and standby redundancy, the role of the ReplicaSet controller, and the fact that both replicas serve live traffic. What is gained: a board member can connect the statement to a business outcome (no single point of failure) without needing to understand how Kubernetes schedules workloads.

---

## Reflection 3: What Should Come From ConfigMaps and Secrets

Looking at the current Deployment manifest, these values are hardcoded and should be externalised:

**containerPort: 3001** — belongs in a ConfigMap. If the application ever changes its listening port, every manifest that references it must be updated manually. A ConfigMap makes the port a named configuration value that can be changed in one place.

**image: machariabrian12/kk-payments:1.0.0-982aef3** — the registry username is hardcoded. In a team environment, the registry address should come fr
