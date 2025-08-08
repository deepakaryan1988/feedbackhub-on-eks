# Cursor Prompt Templates – DevOps Fast-Path

## 1) Refactor-only (safe)
> Refactor the targeted module(s) only. No behavior changes. No `terraform apply`. Keep diffs minimal, write clear commits.

## 2) Enable EKS create path (dev only)
> In `terraform/eks/cluster`, add `create_cluster` toggle (bool). If true -> create `aws_eks_cluster`; if false -> read existing via data source. Wire the toggle from `infra/variables.tf` and `infra/dev.tfvars`. Plan only.

## 3) Add/adjust ALB Ingress (dev)
> Ensure `create_alb=true` and `create_ingress=true` in `infra/dev.tfvars`. Confirm AWS Load Balancer Controller Helm release exists. Create/update `k8s/feedbackhub/ingress-dev.yaml` (internet-facing, ip targets, healthcheck `/`). No apply.

## 4) Observability install
> Add Helm releases for kube-prometheus-stack in namespace `monitoring` behind a toggle `enable_monitoring`. Provide port-forward commands in README. No external ALB for monitoring by default.

## 5) README 5-minute smoke test
> Add a section showing:
> - `make dev-up`
> - `aws eks update-kubeconfig --region us-east-1`
> - `make ingress-on`
> - `make check-lb`
> - Grafana/Prometheus port-forward
> - `make dev-down` at EOD

## 6) Secrets sweep
> Grep for secrets and replace with variables or Secrets Manager references. Leave a short report + TODOs.

## 7) Clean bloat
> Propose a deletion list (scripts, temp json, orphan tf). Keep `docs/screenshots/**`. One commit: "chore: remove unused assets".
