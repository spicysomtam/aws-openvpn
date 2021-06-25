variable "key_pair" {
  description = "ec2 key pair name."
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "ec2 instance type."
  type        = string
  default     = "t2.micro"
}
