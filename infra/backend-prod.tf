# terraform {
#   backend "s3" {
#     bucket         = "feedbackhub-prod-tfstate"
#     key            = "prod/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "feedbackhub-prod-tf-locks"
#     encrypt        = true
#   }
# }
