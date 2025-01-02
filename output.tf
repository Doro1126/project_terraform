output "bastion_eip" {
  description = "Elastic IP for Bastion Host"
  value       = aws_eip.bastion_eip.public_ip
}
output "web_eip" {
  description = "Elastic IP for Web Instance"
  value       = aws_eip.web_eip.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.db.endpoint
}