provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS Region"
  default     = "ap-northeast-1"
}