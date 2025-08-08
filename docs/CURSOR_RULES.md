# Cursor Rules (DevOps – FeedbackHub on EKS)

**Golden rules**
- Never run `terraform apply` unless explicitly asked.
- Always use `--no-cli-pager` for AWS CLI.
- Default region: `us-east-1`.
- Prefer small, reversible commits; no giant refactors in one shot.
- Cost guardrails: `enable_nat_gateway=false` by default; enable ALB/Ingress only when requested.
- No secrets or AWS IDs in code. Use variables, data sources, or Secrets Manager references.
- If unsure, open a TODO and stop rather than guessing.

**Repo specifics**
- Single EKS cluster with namespaces: `dev`, `prod`, `monitoring`.
- Daytime dev: ALB/Ingress may be ON; run `make dev-down` before EOD.
- Observability: Prometheus/Grafana via Helm; keep them internal (port-forward) unless requested otherwise.
- Validate with: `terraform fmt -recursive && terraform validate && terraform plan -var-file=infra/dev.tfvars -detailed-exitcode`.
