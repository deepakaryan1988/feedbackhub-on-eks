# IRSA ALB Controller Module
# Creates IAM role with trust policy for aws-load-balancer-controller service account

# Download the official ALB Controller IAM policy
data "http" "alb_controller_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}

# Create the IAM role with IRSA trust policy
resource "aws_iam_role" "alb_controller" {
  name = "${var.cluster_name}-alb-controller-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:${var.service_account_namespace}:${var.service_account_name}"
        }
      }
    }]
  })
  tags = {
    Name = "${var.cluster_name}-alb-controller-role"
    ClusterName = var.cluster_name
    Region = var.cluster_region
    Purpose = "alb-controller-irsa"
    ServiceAccount = "${var.service_account_namespace}/${var.service_account_name}"
  }
}

# Attach the ALB Controller policy to the role
resource "aws_iam_role_policy_attachment" "alb_controller" {
  role = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

# Create the ALB Controller policy from the downloaded content
resource "aws_iam_policy" "alb_controller" {
  name = "${var.cluster_name}-alb-controller-policy"
  description = "Policy for AWS Load Balancer Controller"
  policy = data.http.alb_controller_policy.response_body
  tags = {
    Name = "${var.cluster_name}-alb-controller-policy"
    ClusterName = var.cluster_name
    Region = var.cluster_region
    Purpose = "alb-controller-permissions"
  }
}
