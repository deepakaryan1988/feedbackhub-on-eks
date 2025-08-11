# Ingress Debug Cheat Sheet

## Quick checks
```bash
kubectl get pods -n ingress-nginx
kubectl get svc  -n ingress-nginx ingress-nginx-controller
kubectl get ingress
kubectl get svc web api && kubectl get endpoints web api
```

## Common fixes

**Controller service stuck on NodePort:**
```bash
kubectl patch svc ingress-nginx-controller -n ingress-nginx -p '{"spec":{"type":"LoadBalancer"}}'
minikube tunnel
```

**Host not pointing to LB IP:**
```bash
LB_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
sudo sh -c "sed -i '' '/dev\\.local/d' /etc/hosts"
echo "$LB_IP dev.local" | sudo tee -a /etc/hosts
```

**Ingress class ambiguity**: ensure both are present (safe for local)
```yaml
spec:
  ingressClassName: nginx
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
```
