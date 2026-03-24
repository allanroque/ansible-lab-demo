# ============================================================================
# S3 Backend for Terraform Remote State
# Bucket and DynamoDB table are created by setup-s3-backend.yml
# ============================================================================
terraform {
  backend "s3" {
    # Values injected via -backend-config at terraform init time
    # bucket         = "terraform-state-<name>-<account_id>"
    # key            = "provisioning/<name>/terraform.tfstate"
    # region         = "us-east-2"
    # dynamodb_table = "terraform-lock-<name>-<account_id>"
    encrypt = true
  }
}
