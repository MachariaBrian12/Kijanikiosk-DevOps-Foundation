output "public_ip" {
  description = "Public IP address of the instance"
  value       = aws_instance.this.public_ip
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.this.id
}

output "ssh_command" {
  description = "Ready-to-use SSH command for this server"
  value       = "ssh -i ~/.ssh/kijanikiosk ubuntu@${aws_instance.this.public_ip}"
}
