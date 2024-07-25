terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.61.0"
    }
  }
}

# configured aws provider with proper credentials
provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

# Generates a secure private key and encodes it as PEM
resource "tls_private_key" "lamp_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
# Create the Key Pair
resource "aws_lightsail_key_pair" "lamp_key" {
  name   = "lampkey"
  public_key = tls_private_key.lamp_key.public_key_openssh
}
# Save file
resource "local_file" "ssh_key" {
  filename = "lampkey.pem"
  content  = tls_private_key.lamp_key.private_key_pem
  file_permission = "400"
}

# Create a new GitLab Lightsail Instance
resource "aws_lightsail_instance" "gitlab_test" {
  name              = "lamp-server"
  availability_zone = "us-east-1a"
  blueprint_id      = "amazon_linux_2"
  bundle_id         = "nano_3_0"
  key_pair_name     = "lampkey"
  tags = {
    foo = "bar"
  }
}

# output data
output "instance_ip" {
    value = "aws_lightsail_instance.gitlab_test.public_ip_address"
}

output "ssh_command" {
    value = "ssh -i lampkey.pem  ec2-user@${aws_lightsail_instance.gitlab_test.public_ip_address}"
}