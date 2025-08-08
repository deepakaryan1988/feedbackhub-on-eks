# PR Notes: Repo Audit (Day 22 Refactor)

This document inventories current files and flags potential cleanup/bloat. No deletions performed yet. Use as reference during refactor.

## Summary
- Focus: Normalize Terraform layout, cost-aware defaults (no NAT, ALB/Ingress/EIPs off by default), remove hardcoded region/IDs, and avoid secrets in repo.
- Note: Found generated artifacts (`infra/terraform.tfstate*`, `infra/apply.log`). Keep out of Git history if possible.

## Inventory

### Terraform files
- Top-level infra layer:
  - `infra/main.tf`, `infra/variables.tf`, `infra/outputs.tf`
  - Many module references (network, cluster, nodegroups, irsa, monitoring, logging, alb-controller)
- Modules under `terraform/`:
  - `terraform/network/` (vpc, security groups; includes ALB SG rules)
  - `terraform/cluster/` (EKS cluster)
  - `terraform/nodegroups/` (managed node groups)
  - `terraform/irsa/` (IAM roles for service accounts; ALB controller role)
  - `terraform/monitoring/` (Prometheus/Grafana; optional ingress)
  - `terraform/logging/` (Loki/Promtail; optional gateway ingress)
  - `terraform/alb-controller/` (AWS Load Balancer Controller)

### Kubernetes manifests
- `k8s/manifests/feedbackhub-deployment.yaml`
- `k8s/manifests/namespaces.yaml`

### Shell scripts
- VPC cleanup: `scripts/aws-vpc-nuke.sh`, `scripts/cleanup-vpc-dependencies.sh`, `scripts/vpc-cleanup-ap-south-1.sh`
- EKS helpers: `scripts/build-eks.sh`, `scripts/health-check-eks.sh`, `scripts/dev.sh`, etc.
- Bedrock tests: `scripts/bedrock/*`
- Infra scripts: `infra/deploy_infrastructure.sh`, `infra/import_existing_resources.sh`

### Logs / state artifacts
- `infra/apply.log`
- `infra/terraform.tfstate`, `infra/terraform.tfstate.backup`

### Markdown
- `README.md`, `infra/README.md`
- Module READMEs under `terraform/*/README.md`
- `docs/no-nat-architecture-summary.md`

## Cost-risk resources (to disable by default)
- NAT Gateways / EIPs:
  - Evidence: `infra/apply.log` shows `aws_nat_gateway` and `aws_eip` planned creations; `infra/terraform.tfvars.example` has `enable_nat_gateway = true`
- ALB / Ingress:
  - Evidence: `infra/main.tf` wires `module.alb_controller`; monitoring/logging modules accept ingress configs.

## Hardcoded regions / IDs
- Regions found:
  - `us-east-1` in multiple files (desired default), but also `ap-south-1` in scripts and manifests.
- Example occurrences:
  - `infra/variables.tf` default `us-east-1`
  - `k8s/manifests/feedbackhub-deployment.yaml` uses `ap-south-1` for `AWS_REGION` and ECR URL
  - Scripts under `scripts/bedrock/` and `scripts/build-eks.sh` default to `ap-south-1`
- Hardcoded account IDs present in state/logs (artifacts) and documentation examples.

## Potential secrets in repo (to remediate)
- `infra/terraform.tfvars.dev` contains `grafana_admin_password = "dev-admin-123"`
- `k8s/manifests/feedbackhub-deployment.yaml` has base64-encoded `mongodb-password` in a Secret manifest (example)
- `docker/docker-compose.yml` sets `MONGO_INITDB_ROOT_PASSWORD=password`
- Example passwords in `infra/terraform.tfvars.example`, module READMEs; ensure these remain examples only.

## Candidate deletions (later; do not delete yet)
- Generated artifacts: `infra/terraform.tfstate*`, `infra/apply.log`
- Region-specific scripts for `ap-south-1` if standardizing to `us-east-1` (or parameterize)
- Duplicate or orphaned Terraform files (to be identified after consolidation)
- Temporary backups or `.sample` files if superseded

## Next Actions in Refactor
- Introduce `infra/backend-dev.tf` (local) and `infra/backend-prod.tf` (commented S3) backends
- Add `infra/dev.tfvars` and `infra/prod.tfvars` with cost-aware defaults
- Wire modules from `infra/main.tf` using variables, no hardcoded IDs/regions
- Ensure all modules have `variables.tf`, `outputs.tf`, and README
- Run `terraform fmt`, `init -backend=false`, `validate` across modules
- Grep for secrets and replace with variables or AWS Secrets Manager references
