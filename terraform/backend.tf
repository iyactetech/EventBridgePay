# root/backend.tf (or global/backend.tf)
# This file defines the *shared* bucket and table for state.
# The 'key' will still need to be unique per environment, usually set in a `main.tf`
# or via CLI, or through a `partial configuration` during `terraform init`.

terraform {
  backend "s3" {
    bucket         = "your-company-name-terraform-state-bucket" # MUST BE GLOBALLY UNIQUE!
    region         = "ap-northeast-1"                            # Your AWS region
    encrypt        = true
    dynamodb_table = "your-company-name-terraform-locks"
    # The 'key' will be provided when you run `terraform init` within each environment directory
    # or you can use a partial configuration.
  }
}