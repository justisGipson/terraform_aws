terraform {
  required_version = ">= 0.12"
}

variable "server_port" {
	type        = number
	description = "Port used by server for http requests"
	default			= 8080
}

variable "elb_port" {
  type        = number
  description = "Port used by ELB"
  default     = 80
}
