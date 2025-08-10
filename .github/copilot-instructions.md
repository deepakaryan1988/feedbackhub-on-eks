# GitHub Copilot Instructions – FeedbackHub-on-EKS

## Priority Guidelines

When generating code for this repository:

1. **Version Compatibility**: Always detect and respect the exact versions of languages, frameworks, and libraries used in this project. Examine `package.json`, `requirements.txt`, and other config files. Never use features not available in the detected versions.
2. **Context Files**: Prioritize patterns and standards defined in the `.github/instructions/` and `.github/copilot/` directories.
3. **Codebase Patterns**: When context files don't provide specific guidance, scan the codebase for established naming, organization, error handling, and testing patterns. Always match the most consistent and recent patterns found in the codebase.
4. **Architectural Consistency**: Maintain the modular, microservices-inspired architecture. Respect boundaries between Terraform modules, app components, and infrastructure layers. Do not introduce monolithic or tightly coupled patterns.
5. **Code Quality**: Prioritize maintainability, security, performance, and testability in all generated code. Follow the same documentation and commenting style as found in the codebase.



## How to Use
This project uses a modular Copilot setup for maximum productivity and clarity. Always:
- Scan the codebase for technology versions and patterns before generating code
- Match code organization, naming, and error handling to existing files
- Never introduce patterns not found in the codebase

### 📁 Organization
- `.github/instructions/`: Project- and stack-specific Copilot instructions (e.g., Next.js, Terraform, DevOps, Security, Docker, etc.)
- `.github/prompts/`: Reusable prompt templates for architecture, testing, automation, and documentation
- `.github/chatmodes/`: Custom chat mode instructions for specialized workflows (e.g., Beast Mode, Debug Mode, Planning, etc.)

### 🚀 How to Use
- Reference or copy any file from these folders into Copilot Chat or ChatGPT for context-aware code generation, reviews, and onboarding.
- In VS Code Copilot Chat, you can:
  - Paste the contents of an instruction, prompt, or chat mode file to activate it for your session
  - Use the "Chat: Run Prompt" command or `/prompt-name` to run a reusable prompt
  - Switch chat modes for role-specific workflows (see `.github/chatmodes/`)

For more, see the [awesome-copilot repo](https://github.com/github/awesome-copilot) for updates and new templates.

## 1️⃣ Project Summary
FeedbackHub-on-EKS is a production-grade feedback platform built with **Next.js** and deployed on **AWS EKS (Kubernetes)**. Infrastructure is fully managed via **modular Terraform** and **Helm**. MongoDB Atlas is the primary database. AWS Secrets Manager handles credentials. Deployments use **Blue/Green** via ALB and Kubernetes strategies. Auto Scaling is managed via Kubernetes and CloudWatch alarms. Monitoring and logging are provided by **Prometheus**, **Grafana**, and **Loki**.

---

## 2️⃣ Architecture Overview
- **Frontend & Backend:** Next.js (API routes)
- **Database:** MongoDB Atlas (local & prod URIs)
- **Infrastructure:** EKS (Kubernetes), ALB, Auto Scaling, CloudWatch, SNS
- **IaC:** Modular Terraform (`terraform/`), Helm charts (`helm/`)
- **parent infra to control modular terraform:** infra Terraform (`infra/`)
- **Secrets:** AWS Secrets Manager (integrated with Kubernetes via CSI driver)
- **CI/CD:** GitHub Actions (`.github/workflows/deploy.yml`)
- **Monitoring & Logging:** Prometheus, Grafana, Loki
- **AI Integration:** AWS Bedrock (Claude for log summarization)

---

## 3️⃣ Repository Structure
```
/ app/                # Next.js app directory (pages, API routes, components, hooks, lib, types)
/ docker/             # Dockerfiles and compose files for local/dev/prod
/ docs/               # Architecture, setup, and onboarding documentation
/ infra/              # Parent Terraform for controlling modular infra
/ scripts/            # Shell scripts for build, test, and setup
/ terraform/          # Modular Terraform (alb, eks, cloudwatch, secrets, etc.)
/ helm/               # Helm charts for Kubernetes deployments
/ k8s/                # Raw Kubernetes manifests (if any)
/ monitoring/         # Prometheus, Grafana, Loki configs
/ lambda/             # AWS Lambda functions (e.g., Bedrock log summarizer)
public/              # Static assets (images, favicon, etc.)
package.json         # Project dependencies and scripts
README.md            # Project overview and quickstart
.env.example         # Example environment variables
```
---

## 4️⃣ Development & Deployment Rules
- All Terraform changes must be modular (no monolithic `main.tf`).
- All Kubernetes changes must be modular (no monolithic `main.yaml`).
- Use Helm charts for application deployment and configuration.
- Integrate Prometheus, Grafana, and Loki for monitoring and logging.
- Secrets (DB URIs, API keys) are fetched via **AWS Secrets Manager** and injected into Kubernetes via CSI driver or Kubernetes Secrets.
- Auto Scaling is managed via Kubernetes (HPA/VPA) and CloudWatch alarms (triggered by CPU).
- **No hardcoding** of Account IDs, Subnet IDs, Regions, cluster names, or namespaces.
- **Integrate with existing ALB, EKS, and Secrets Manager infrastructure—do not re-provision these core resources.**
- Validate Helm charts and Kubernetes manifests before deployment.
- Validate monitoring stack setup (Prometheus, Grafana, Loki) after deployment.

---

## 5️⃣ Naming Conventions
- **Branches:**
  - `feature/...` → new features
  - `fix/...` → bug fixes
- ✅ Use AWS best practices, modular Terraform
- ✅ Maintain `README.md` with roadmap updates
**Don’t:**


To maximize productivity and clarity, this project supports dedicated Copilot/AI subagents for each major engineering role. Each subagent is optimized for the workflows, best practices, and context of its domain. To invoke a subagent, use the role-specific prompt snippets in [docs/copilot-snippets.md](../docs/copilot-snippets.md) or specify the role in your Copilot/AI prompt.
- **DevOps Subagent:** Infrastructure as Code, CI/CD, AWS, Terraform, Docker, deployment automation, monitoring, and incident response.
- **Security Subagent:** IAM, secrets management, encryption, compliance, vulnerability scanning, and secure coding practices.
- **MLOps/AI Subagent:** AI/ML integration, AWS Bedrock, Lambda, model deployment, data pipelines, and log summarization.
- **Fullstack Subagent:** Next.js, API routes, frontend/backend integration, UI/UX, and end-to-end testing.
- **Cloud Architect Subagent:** Solution design, AWS architecture, scalability, cost optimization, and cross-service integration.
- **SRE Subagent:** Reliability, observability, auto scaling, CloudWatch, alerting, and performance tuning.
- **General/Meta Subagent:** Documentation, onboarding, code review, and meta tasks.

**How to Use:**
- Reference the [Copilot Prompt Snippets](../docs/copilot-snippets.md) for ready-to-use prompts for each subagent.
- When starting a new task, specify the subagent/role in your prompt for best results (e.g., “DevOps subagent: create a new ECS service module in Terraform”).

This approach ensures that Copilot/AI responses are tailored, actionable, and aligned with best practices for each domain.