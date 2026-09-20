provider "aws" {
  region = "us-east-1"
}

# 1. VPC & Networking Infrastructure
resource "aws_vpc" "devops_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "DevOps-VPC" }
}

resource "aws_internet_gateway" "devops_igw" {
  vpc_id = aws_vpc.devops_vpc.id
  tags   = { Name = "DevOps-IGW" }
}

resource "aws_subnet" "devops_subnet" {
  vpc_id                  = aws_vpc.devops_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags                    = { Name = "DevOps-Subnet" }
}

resource "aws_route_table" "devops_rt" {
  vpc_id = aws_vpc.devops_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devops_igw.id
  }
  tags = { Name = "DevOps-RouteTable" }
}

resource "aws_route_table_association" "devops_rta" {
  subnet_id      = aws_subnet.devops_subnet.id
  route_table_id = aws_route_table.devops_rt.id
}

# 2. Security Group (Firewall Rules)
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg"
  description = "Allow SSH, HTTP, and Jenkins inbound traffic"
  vpc_id      = aws_vpc.devops_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Jenkins Dashboard"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP Traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "Jenkins-SG" }
}

# 3. IAM Role & Instance Profile
resource "aws_iam_role" "jenkins_role" {
  name = "jenkins_ec2_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins_profile"
  role = aws_iam_role.jenkins_role.name
}

# 4. EC2 Instance Provisioning (Ubuntu 22.04 LTS)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_instance" "jenkins_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small" # Minimum recommended memory allocation for Jenkins
  subnet_id              = aws_subnet.devops_subnet.id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.jenkins_profile.name

  # Execute installation commands on boot
   user_data_replace_on_change = true

    user_data = replace(<<-EOF
              #!/bin/bash
              exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
              set -x
              export DEBIAN_FRONTEND=noninteractive

              apt-get update -y
              apt-get install -y fontconfig openjdk-21-jre curl ca-certificates

              install -d -m 0755 /etc/apt/keyrings
              curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key -o /etc/apt/keyrings/jenkins-keyring.asc
              echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list

              apt-get update -y
              apt-get install -y jenkins docker.io
              usermod -aG docker jenkins
              systemctl enable --now docker
              systemctl enable jenkins
              systemctl restart jenkins

              # Diagnostics: these lines show up in the EC2 system log
              for i in $(seq 1 30); do
                [ -f /var/lib/jenkins/secrets/initialAdminPassword ] && break
                sleep 10
              done
              systemctl status jenkins --no-pager
              journalctl -u jenkins --no-pager -n 60
              echo "JENKINS ADMIN PASSWORD:"
              cat /var/lib/jenkins/secrets/initialAdminPassword
              EOF
              , "\r", "")

  tags = { Name = "Jenkins-Server" }
}

# 5. Output Terminal Display
output "jenkins_url" {
  description = "URL to access the Jenkins dashboard"
  value       = "http://${aws_instance.jenkins_server.public_ip}:8080"
}