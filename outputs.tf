output "public_ip" {
  value       = aws_instance.ovpn.public_ip
  description = "The public IP address of the vpn server."
}

output "ovpn_ssm_parameter_name" {
  value       = local.ssm_param
  description = "Name of ovpn ssm parameter."
}

output "ovpn_ssm_parameter_value" {
  value       = aws_ssm_parameter.ovpn.value
  description = "Value of ovpn ssm parameter (ovpn client config)."
  sensitive   = true
}

