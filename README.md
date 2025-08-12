# FeedbackHub on EKS (Refactored)

Minimal, cost-aware EKS setup for the FeedbackHub app with a simplified codebase and deployment flow. Focuses on:

- No NAT/EIP: public subnets only with IGW
- One managed node group (t3.small) for dev
- Next.js App Router API for feedback + health checks
- MongoDB via Atlas or local Docker

## What’s Included

- Terraform to provision VPC and EKS (public-only, dev friendly)
- Dockerfiles for prod and dev
- Docker Compose for local development (with MongoDB)
- Kubernetes manifests for the app, service, and ingress (prod + dev sample)

## Architecture (at a glance)

- App: Next.js (TypeScript) under `app/` with API routes:
  - `GET/POST /api/feedback`
  - `GET /api/health`
  - `GET /api/health/simple`
- Data: MongoDB (Atlas recommended; `MONGODB_URI` required)
- Infra: EKS with public endpoint and a single node group
- Ingress (dev sample): AWS Load Balancer Controller ALB ingress for a `hello` service

## Project Structure

```
feedbackhub-on-eks/
├── app/
│   ├── api/
│   ├── components/
│   ├── hooks/
│   ├── lib/
│   ├── types/
│   └── page.tsx
├── docker/
│   ├── Dockerfile
│   ├── Dockerfile.dev
│   ├── Dockerfile.prod
│   ├── docker-compose.yml
│   └── docker-compose.dev.yml
├── k8s/
│   ├── feedbackhub/
│   │   ├── hello.yaml               # sample app for ALB testing (ns: dev)
│   │   └── ingress-dev.yaml         # ALB ingress for dev (ns: dev)
│   └── manifests/
│       ├── namespaces.yaml          # feedbackhub-* namespaces
│       └── feedbackhub-deployment.yaml  # Secret, ConfigMap, Deployment, Service, Ingress (prod)
├── terraform/
│   ├── network/                     # VPC with two public subnets, no NAT
│   └── eks/                         # EKS cluster + node group (public subnets)
├── docs/
└── env.example
```

## Prerequisites

- AWS CLI v2 (authenticated with the right account)
- Terraform >= 1.6
- kubectl
- Docker

## Environment

Copy and edit the example file:

```bash
cp env.example .env.local
```

Required for the app:

- `MONGODB_URI` (e.g., Atlas or `mongodb://mongo:27017/feedbackhub` when using compose)

Optional:

- `NODE_ENV`, `PORT`, `NEXT_TELEMETRY_DISABLED`, `AWS_REGION`, `AWS_PROFILE`

## Local Development (Docker Compose)

Option A — Dev-friendly (no auth Mongo):

```bash
docker compose -f docker/docker-compose.dev.yml up -d --build
# App: http://localhost:3000
```

Option B — Closer to prod (auth-enabled Mongo seed):

```bash
docker compose -f docker/docker-compose.yml up -d --build
```

## Build a Production Image

```bash
docker build -f docker/Dockerfile -t feedbackhub:latest .
docker run -e MONGODB_URI="<your-uri>" -p 3000:3000 feedbackhub:latest
```

## Provision EKS (Dev, No NAT/EIP)

Defaults: region `us-east-1`, cluster `feedbackhub-dev`, 1× t3.small

**Note on Terraform Variables:**
This project uses `dev.auto.tfvars` files for environment-specific variables. These files are automatically loaded by Terraform. For new environments, copy the `tfvars.template` file to `<environment_name>.auto.tfvars` and populate the values.

```bash
# Network
cd terraform/network
terraform init
terraform apply -auto-approve

# EKS
cd ../eks
terraform init
terraform apply -auto-approve

# IAM (EKS OIDC Provider)
cd ../iam/eks_oidc
terraform init
terraform apply -auto-approve

# IAM (IRSA for ALB Controller)
cd ../irsa_alb_controller
terraform init
terraform apply -auto-approve

# EKS ALB Controller
cd ../../eks/alb_controller
terraform init
terraform apply -auto-approve

# Configure kubectl
aws eks update-kubeconfig --name feedbackhub-dev --region us-east-1
kubectl get nodes -o wide
```

Destroy (reverse order):

```bash
# EKS ALB Controller
cd terraform/eks/alb_controller && terraform destroy -auto-approve || true

# IAM (IRSA for ALB Controller)
cd ../../iam/irsa_alb_controller && terraform destroy -auto-approve || true

# IAM (EKS OIDC Provider)
cd ../eks_oidc && terraform destroy -auto-approve || true

# EKS
cd ../../eks && terraform destroy -auto-approve || true

# Network
cd ../network && terraform destroy -auto-approve || true
```

## Deploy to Kubernetes

1) Namespaces:

```bash
kubectl apply -f k8s/manifests/namespaces.yaml
```

2) Production app (update image and secrets first):

- Edit `k8s/manifests/feedbackhub-deployment.yaml`:
  - Replace image `your-account-id.dkr.ecr.us-east-1.amazonaws.com/feedbackhub:latest`
  - Replace secret data with your base64 values, or create a secret directly:

```bash
kubectl -n feedbackhub-production create secret generic feedbackhub-secrets \
  --from-literal=mongodb-uri="<your-mongodb-uri>" \
  --from-literal=mongodb-password="<optional-if-used>"
```

Apply:

```bash
kubectl apply -f k8s/manifests/feedbackhub-deployment.yaml
kubectl -n feedbackhub-production get pods,svc,ingress
```

3) Dev ALB sample (hello + ingress):

```bash
kubectl apply -f k8s/feedbackhub/hello.yaml
kubectl apply -f k8s/feedbackhub/ingress-dev.yaml
kubectl -n dev get ingress
```

## Kubernetes — Phase 0.5 Local Ingress

Local demo using Minikube + NGINX Ingress:

- `dev.local/` → nginx web
- `dev.local/api` → http-echo

**Guide**: See [docs/phase0.5-local-ingress.md](docs/phase0.5-local-ingress.md)  
**Debug**: See [docs/ingress-debug-cheatsheet.md](docs/ingress-debug-cheatsheet.md)

No Makefile required. Run commands manually as shown in the guide.

## App Endpoints

- `GET /api/health` — returns app health and Mongo status (best-effort)
- `GET /api/health/simple` — lightweight health
- `GET /api/feedback` — list recent feedbacks
- `POST /api/feedback` — create feedback `{ name, message }`

Liveness/Readiness probes use `/api/health` on port 3000 (see `k8s/manifests/feedbackhub-deployment.yaml`).

## Troubleshooting

- Mongo errors: ensure `MONGODB_URI` is set (pods log `MONGODB_URI environment variable not set.` otherwise)
- ALB pending: verify AWS Load Balancer Controller and subnet tags; check ingress events
- Pods not ready: check `/api/health` and container logs

## Notes

- Terraform network uses two public subnets with an IGW (no NAT gateways)
- EKS module: public endpoint, one managed node group (ON_DEMAND t3.small)

## License

MIT
