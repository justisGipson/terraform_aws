terraform {
  required_version = ">= 0.12"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.jgipsonterraformstatebackup.arn
  description = "ARN of S3 bucket" 
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "DynamoDB table name"
}

output "public_ip" {
	value       = aws_instance.example.public_ip
	sensitive   = false
	description = "Public IP for server"
}

output "clb_dns_name" {
	value				= aws_elb.example.dns_name
	description	= "Domain name of load balancer"
}
