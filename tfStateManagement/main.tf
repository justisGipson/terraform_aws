provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "jgipsonterraformstatebackup" {
  bucket = "jgipsonterraformstatebackup"

  # enable versioning, full revision history of state files
  versioning {
    enabled = true
  }

  # enable server side encrytion as default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name                = "terraform-up-and-running-locks"
  billing_mode        = "PAY_PER_REQUEST"
  hash_key            = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

terraform {
  backend "s3" {
    bucket = "jgipsonterraformstatebackup"
    key    = "global/s3/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "terraform-up-and-running-locks"
    encrypt = true
  }
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.jgipsonterraformstatebackup.arn
  description = "ARN of S3 bucket" 
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "DynamoDB table name"
}
