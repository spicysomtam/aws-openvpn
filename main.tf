terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
 }
}

provider "aws" {
}

data "aws_region" "current" {}

locals {
  location = lower(replace(element(split("(",data.aws_region.current.description),1),")",""))
  ssm_param = "/openvpn/client-ovpn/${local.location}.ovpn"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# This is just a placeholder; the param gets setup correctly in the userdata for the instance.
# Defining it in tf means it will be managed by tf and correctly deleted when the stack is destroyed.
resource "aws_ssm_parameter" "ovpn" {
  name  = local.ssm_param
  type  = "String"
  value = "Not populated yet."

  lifecycle {
    ignore_changes = [ value, ]
  }
}

resource "aws_instance" "ovpn" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.ovpn.id]
  iam_instance_profile   = aws_iam_instance_profile.ovpn.name

  user_data = templatefile("${path.module}/userdata.tmpl", { 
    script = "openvpn-install.sh",
    region = local.location,
    ssm_param = local.ssm_param
  })

  key_name = var.key_pair

  # We need this to be created before the instance.
  depends_on = [ aws_ssm_parameter.ovpn, ]

  tags = {
    Name = "openvpn"
  }
}

resource "aws_iam_instance_profile" "ovpn" {
  name = "openvpn"
  role = aws_iam_role.ovpn.name
}

resource "aws_iam_role" "ovpn" {
  name = "openvpn"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "ovpn" {
  name = "openvpn"
  policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
{
    "Effect": "Allow",
    "Action": [
     "ssm:PutParameter"
    ],
    "Resource": [
      "*"
    ]
  }
]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ovpn" {
  role        = aws_iam_role.ovpn.name
  policy_arn  = aws_iam_policy.ovpn.arn
}

resource "aws_security_group" "ovpn" {
  name        = "openvpn"
  description = "OpenVPN security group"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
