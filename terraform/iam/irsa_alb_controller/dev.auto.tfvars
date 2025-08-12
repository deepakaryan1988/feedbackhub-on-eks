# Development environment variables for IRSA ALB Controller module

cluster_name   = "feedbackhub-dev"
cluster_region = "us-east-1"

oidc_provider_arn  = "arn:aws:iam::345204682050:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/06EB8FE510A23A4157FF9BBD441FCF4F"
oidc_provider_url  = "https://oidc.eks.us-east-1.amazonaws.com/id/06EB8FE510A23A4157FF9BBD441FCF4F"

# Service account defaults (can be overridden if needed)
service_account_namespace = "kube-system"
service_account_name      = "aws-load-balancer-controller"
