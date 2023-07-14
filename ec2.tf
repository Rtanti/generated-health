resource "aws_key_pair" "bastion_key_pair" {
  key_name   = var.sshkey
  public_key = file("files/gh-key.pub")
}

resource "aws_default_vpc" "gh_vpc" {
  tags = {
    Name = "GH-VPC"
  }
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
#resource "aws_iam_policy" "s3_access_policy" {
#  name   = "S3AccessPolicy"
#  policy = <<EOF
#{
#  "Version": "2012-10-17",
#  "Statement": [
#    {
#      "Effect": "Allow",
#      "Action": [
#        "s3:GetObject",
#        "s3:PutObject",
#        "s3:DeleteObject",
#        "s3:ListAllMyBuckets"
#      ],
#      "Resource": "arn:aws:s3:::${ var.gh_bucket_name }/*"
#    }
#  ]
#}
#EOF
#}

# Attach the IAM policy to the IAM role
resource "aws_iam_policy_attachment" "s3_access_attachment" {
  roles       = [aws_iam_role.bastion_role.name]
  name       = "EC2S3AccessPolicyAttachment"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
#resource "aws_iam_role_policy_attachment" "s3_access_attachment" {
#  role       = aws_iam_role.bastion_role.name
#  policy_arn = aws_iam_policy.s3_access_policy.arn
#}

# Security group for the bastion host
resource "aws_security_group" "bastion_sg" {
  name        = "BastionHostSG"
  description = "Security group for the bastion host"
    vpc_id = aws_default_vpc.gh_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["52.57.90.250/32"]
  }

  # Allow outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_flow_log" "ssh_flow_log" {
  traffic_type        = "ALL"
  log_destination    = "arn:aws:logs:eu-west-2:123456789012:log-group:/aws/flow-logs/ssh-flow-log"
  #log_destination_type = "arn"
  iam_role_arn = aws_iam_role.bastion_role.arn

  vpc_id = aws_default_vpc.gh_vpc.id
}

resource "aws_cloudwatch_log_group" "ssh_cw_log_group" {
  name              = "/aws/ec2/bastion-instance"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_stream" "ssh_cw_log_stream" {
  name           = "bastion-ssh-stream"
  log_group_name = aws_cloudwatch_log_group.ssh_cw_log_group.name
}

resource "aws_cloudwatch_log_metric_filter" "ssh_cw_log_metric_filter" {
  name           = "ssh-connections"
  pattern        = "{ $.srcaddr = \"*\" && $.dstport = 22 }"
  log_group_name = aws_cloudwatch_log_group.ssh_cw_log_group.name

  metric_transformation {
    name      = "SSHConnections"
    namespace = "EC2/SSH"
    value     = "1"
  }
}

resource "aws_cloudwatch_dashboard" "ssh_connections" {
  dashboard_name = "ssh-dashboard"
  dashboard_body = <<-EOT
  {
    "widgets": [
      {
        "type": "metric",
        "x": 0,
        "y": 0,
        "width": 12,
        "height": 6,
        "properties": {
          "view": "singleValue",
          "metrics": [
            [ "EC2/SSH", "SSHConnections", "LogGroupName", "/aws/ec2/bastion-instance", "LogStreamName", "bastion-ssh-stream" ]
          ],
          "region": "eu-west-2",
          "stat": "Sum",
          "period": 300,
          "title": "SSH Connections"
        }
      }
    ]
  }
  EOT
}

# Output the public IP address of the bastion host
output "bastion_host_public_ip" {
  value = aws_instance.bastion_host.public_ip
}
