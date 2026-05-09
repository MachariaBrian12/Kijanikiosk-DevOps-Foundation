# Week 9 — Production-Approaching Kubernetes Deployment

**Student:** Brian Kagai Macharia  

Two-service Minikube deployment (`kk-api`, `kk-payments`) in namespace `kijani-project`: ConfigMaps, imperative Secret (documented via example only), Deployments, ClusterIP Services, and nginx Ingress.

## Contents

| Path | Description |
|------|-------------|
| `k8s/` | Manifests applied with `kubectl apply` (Secret created via `kubectl create secret …`, see `.example` file). |
| `Week 9 Final Submission.pdf` | Instructor submission package (manifests, required screenshots, production readiness write-up). |

## Secret (do not commit real values)

Create the Secret in the cluster:

```bash
kubectl create secret generic kk-payments-secrets \
  --from-literal=DB_PASSWORD='<your-db-password>' \
  --from-literal=STRIPE_API_KEY='<your-stripe-key>' \
  --from-literal=JWT_SECRET='<your-jwt-secret>' \
  -n kijani-project
```

See `k8s/kk-payments-secrets.yaml.example` for key names only.
