resource "aws_key_pair" "bastion_key_pair" {
  key_name   = var.sshkey
  public_key = file("gh-key.pub")
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



# EC2 instance resource
resource "aws_instance" "bastion_host" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = var.sshkey

  tags = {
    Name = "BastionHost"
  }

  # Security group for SSH access from trusted IP addresses
  vpc_security_group_ids = [
    aws_security_group.bastion_sg.id,
  ]

  # IAM role for EC2 instance
  iam_instance_profile = aws_iam_instance_profile.bastion_profile.name
}

# IAM instance profile for EC2 instance
resource "aws_iam_instance_profile" "bastion_profile" {
  name = "BastionProfile"

  # IAM role for EC2 instance
  role = aws_iam_role.bastion_role.name
}

# IAM role for EC2 instance
resource "aws_iam_role" "bastion_role" {
  name = "BastionRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# IAM policy for S3 bucket access
resource "aws_iam_policy" "s3_access_policy" {
  name   = "S3AccessPolicy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::${ var.gh_bucket_name }/*"
    }
  ]
}
EOF
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "s3_access_attachment" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# Security group for the bastion host
resource "aws_security_group" "bastion_sg" {
  name        = "BastionHostSG"
  description = "Security group for the bastion host"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["93.96.117.61/32"]
  }

  # Allow outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Output the public IP address of the bastion host
output "bastion_host_public_ip" {
  value = aws_instance.bastion_host.public_ip
}
