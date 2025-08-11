# Phase 0.5 — Local Ingress (Minikube + Lens)

## Why this step
Route multiple services via one hostname, mirroring how AWS ALB will work later on EKS (us-east-1).

## What we deployed
- `web` (nginx:1.25) → `Service web:80`
- `api` (hashicorp/http-echo:1.0.0) → `Service api:80`
- `Ingress dev-ingress` with host `dev.local`:
  - `/` → `web:80`
  - `/api` → `api:80`

## Commands (clean, manual — no Makefile)
```bash
# 1) Start cluster + ingress controller
minikube start
minikube addons enable ingress
kubectl get pods -n ingress-nginx
kubectl get svc  -n ingress-nginx

# If controller service is NodePort, switch it:
kubectl patch svc ingress-nginx-controller -n ingress-nginx -p '{"spec":{"type":"LoadBalancer"}}'

# 2) Start tunnel (separate terminal, keep running)
minikube tunnel

# 3) Apply manifests
kubectl apply -f k8s/local-ingress/web.yaml
kubectl apply -f k8s/local-ingress/api.yaml
kubectl apply -f k8s/local-ingress/ingress.yaml

# 4) Map host to LB IP
LB_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
sudo sh -c "sed -i '' '/dev\\.local/d' /etc/hosts"
echo "$LB_IP dev.local" | sudo tee -a /etc/hosts

# 5) Validate
curl -I http://dev.local/
curl    http://dev.local/api
```

## What went wrong (and fixes)
**Controller Service was NodePort** → No EXTERNAL-IP, Ingress unreachable.
Fix: `kubectl patch svc ... type=LoadBalancer + minikube tunnel`.

**Ingress object missing** → Controller had nothing to route.
Fix: `kubectl apply -f k8s/local-ingress/ingress.yaml`.

## Ingress 5‑point health check (use every time)
```bash
kubectl get pods -n ingress-nginx
kubectl get svc  -n ingress-nginx ingress-nginx-controller
kubectl get ingress
kubectl get svc web api && kubectl get endpoints web api
curl -I http://dev.local/ && curl http://dev.local/api
```

## Optional hardening (for HPA later)
Add readiness/liveness probes and small CPU/memory requests:

**web.yaml**: HTTP probes on `/`, requests 50m/64Mi, limits 200m/128Mi

**api.yaml**: HTTP probes on `/`, requests 25m/32Mi, limits 100m/64Mi

## Lens checklist
- Pods: web, api Running/Ready
- Services: web:80, api:80 with 1 endpoint each
- Ingress: dev.local with `/` and `/api` rules
- ingress-nginx-controller: Service LoadBalancer with EXTERNAL-IP

## Mapping to AWS ALB on EKS (us-east-1)
When we move to EKS:

Use `ingressClassName: alb`

Common annotations:
```yaml
alb.ingress.kubernetes.io/scheme: internet-facing
alb.ingress.kubernetes.io/target-type: ip
alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80},{"HTTPS":443}]'
alb.ingress.kubernetes.io/healthcheck-path: / (or /api)
alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:<account>:certificate/<id>
```

Same host/path rules → ALB listeners + rules.
