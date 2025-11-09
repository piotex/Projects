

output "a0_instance_id" {
  value       = aws_instance.web_ec2.id
}
output "a1_instance_public_ip" {
  value       = aws_instance.web_ec2.public_ip
}