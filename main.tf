# Cloud Provider
provider "aws" {
  region = "us-east-1"
}

# Virtual Private Cloud (VPC)
resource "aws_vpc" "main_network" {
  cidr_block           = "10.0.0.0/16" 
  
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "Enterprise-Migration-VPC"
    Environment = "Dev"
    Project     = "AI-Cloud-Migration"
  }
}

# Internet Gateway (The door to the internet)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_network.id

  tags = {
    Name = "Enterprise-Migration-IGW"
  }
}

# Public Subnet 
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_network.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "Public-Subnet-DMZ"
  }
}

# Second Public Subnet (Required for the Load Balancer)
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main_network.id
  cidr_block              = "10.0.3.0/24" 
  map_public_ip_on_launch = true 
  availability_zone       = "us-east-1b"

  tags = {
    Name = "Public-Subnet-DMZ-2"
  }
}

# Private Subnet (Where our secure workloads will live)
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main_network.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Private-Subnet-Secure"
  }
}

# Route Table for the Public Subnet (The map directing traffic to the door)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_network.id

  route {
    cidr_block = "0.0.0.0/0" # All internet traffic
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public-Route-Table"
  }
}

# Associate the Route Table with the Public Subnet
resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Associate the second subnet with the public route table
resource "aws_route_table_association" "public_rt_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Latest Amazon Linux 2023 AMI (Operating System Image)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# The Load Balancer Security Group (Internet Facing)
resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  description = "Allow HTTP traffic from the internet to the Load Balancer"
  vpc_id      = aws_vpc.main_network.id

  ingress {
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
}

# The EC2 Web Server Security Group (Zero Trust - Isolated)
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Allow HTTP strictly from the ALB only"
  vpc_id      = aws_vpc.main_network.id

  ingress {
    description     = "Only accept traffic from the Load Balancer"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance with a Python/Flask App
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y python3 python3-pip
              pip3 install Flask
              
              # Create a simple Python Flask application
              cat << 'EOF_APP' > /home/ec2-user/app.py
              from flask import Flask
              app = Flask(__name__)
              
              @app.route('/')
              def hello():
                  return "<h1>Migration Phase 1: Lift & Shift Successful!</h1><p>Our Python Flask app is live on AWS.</p>"
              
              if __name__ == '__main__':
                  app.run(host='0.0.0.0', port=80)
              EOF_APP
              
              # Run the application in the background
              nohup python3 /home/ec2-user/app.py > /home/ec2-user/flask.log 2>&1 &
              EOF

  tags = {
    Name = "Migration-Web-Server"
  }
}

# Output the Public IP address to the terminal
output "flask_app_url" {
  description = "Click this link to view your migrated application"
  value       = "http://${aws_instance.web_server.public_ip}"
}

# Application Load Balancer
resource "aws_lb" "app_alb" {
  name               = "migration-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet.id, aws_subnet.public_subnet_2.id]
}

# Target Group (The destination for the ALB traffic)
resource "aws_lb_target_group" "app_tg" {
  name     = "migration-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_network.id
}

# Listener (Tells the ALB to listen on Port 80 and forward to Target Group)
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# Attach the EC2 instance to the Target Group
resource "aws_lb_target_group_attachment" "ec2_attach" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.web_server.id
  port             = 80
}

# Output the secure Load Balancer URL
output "secure_alb_url" {
  description = "Access the application securely through the Load Balancer"
  value       = "http://${aws_lb.app_alb.dns_name}"
}

# Current AWS Account ID
data "aws_caller_identity" "current" {}

# S3 Bucket to store CloudTrail logs
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket        = "migration-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name = "CloudTrail-Log-Bucket"
  }
}

# S3 Bucket Policy (Allowing CloudTrail to write to S3)
resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# AWS CloudTrail (The Surveillance Camera)
resource "aws_cloudtrail" "main_trail" {
  name                          = "migration-security-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = false
  enable_log_file_validation    = true

  depends_on = [aws_s3_bucket_policy.cloudtrail_policy]
}