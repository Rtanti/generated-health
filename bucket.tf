provider "aws" {
  region = var.region # Replace with your desired AWS region
}

data "aws_caller_identity" "current" {}

# This is needed for the S3 Bucket access policy to come into effect, without it
# the process may fail as it won't be able to create the s3 buckets
resource "time_sleep" "wait_5_seconds" {
  create_duration = "20s"
  depends_on = [ aws_iam_group_policy_attachment.devops_s3_access_attachment ]
}

# S3 Files Bucket
resource "aws_s3_bucket" "bucket_files" {
  bucket     = var.gh_bucket_name
  depends_on = [
    aws_iam_group_policy_attachment.devops_s3_access_attachment,
    time_sleep.wait_5_seconds
    ]
}

resource "aws_s3_bucket_ownership_controls" "bucket_files_ownership_controls" {
  bucket = aws_s3_bucket.bucket_files.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
resource "aws_s3_bucket_acl" "gh_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.bucket_files_ownership_controls]

  bucket = aws_s3_bucket.bucket_files.id
  acl    = "private"
}
## S3 Logs Bucket
resource "aws_s3_bucket" "bucket_logs" {
  bucket = var.gh_bucket_log
  depends_on = [
    aws_iam_group_policy_attachment.devops_s3_access_attachment,
    time_sleep.wait_5_seconds
  ]
}

resource "aws_s3_bucket_ownership_controls" "bucket_logs_ownership_controls" {
  bucket = aws_s3_bucket.bucket_logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "bucket_logs_acl" {
  bucket = aws_s3_bucket.bucket_logs.id
  acl    = "log-delivery-write"
  depends_on = [ aws_s3_bucket_ownership_controls.bucket_logs_ownership_controls ]
}

resource "aws_s3_bucket_logging" "bucket_logging" {
  bucket = aws_s3_bucket.bucket_files.id

  target_bucket = aws_s3_bucket.bucket_logs.id
  target_prefix = "log/"
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket_files.id

  policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Principal: {
          AWS: "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action: "s3:GetBucketAcl",
        Resource: "arn:aws:s3:::${aws_s3_bucket.bucket_files.id}"
      },
      {
        Effect: "Allow",
        Principal: {
          AWS: [
            for user in aws_iam_user.bucket_dashboard_users : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${user.name}"
          ]
        },
        Action: "s3:ListBucket",
        Resource: "arn:aws:s3:::${aws_s3_bucket.bucket_files.id}"
      },
      {
        Effect: "Allow",
        Principal: {
          AWS: [
            for user in aws_iam_user.bucket_dashboard_users : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${user.name}"
          ]
        },
        Action: [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource: "arn:aws:s3:::${aws_s3_bucket.bucket_files.id}/*"
      }
    ]
  })
}



locals {
  subscriptions = {
    for user in var.users : user.email => {
      topic_arn = aws_sns_topic.notification_topic.arn
      protocol  = "email"
      endpoint  = user.email
    }
  }
}

resource "aws_sns_topic" "notification_topic" {
  name = "S3BucketFileNotificationTopic"
}

resource "aws_sns_topic_policy" "MySNSTopicPolicy" {
  arn    = aws_sns_topic.notification_topic.arn
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sns:Publish",
      "Resource": "${aws_sns_topic.notification_topic.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_s3_bucket.bucket_files.arn}"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_sns_topic_subscription" "email_subscription" {
  for_each  = toset([for user in var.users : user.email])
  topic_arn = aws_sns_topic.notification_topic.arn
  protocol  = "email"
  endpoint  = each.key
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket     = aws_s3_bucket.bucket_files.id
  depends_on = [aws_sns_topic_subscription.email_subscription]

  topic {
    topic_arn = aws_sns_topic.notification_topic.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

resource "aws_cloudwatch_dashboard" "s3_dashboard" {
  dashboard_name = "S3BucketDashboard"
  dashboard_body = <<EOF
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "view": "timeSeries",
        "stacked": false,
        "metrics": [
          [ "AWS/S3", "NumberOfObjects", "BucketName", "${var.gh_bucket_name}", "StorageType", "AllStorageTypes" ]
        ],
        "region": "${var.region}",
        "title": "Object Count"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 6,
      "width": 12,
      "height": 6,
      "properties": {
        "view": "timeSeries",
        "stacked": false,
        "metrics": [
          [ "AWS/S3", "DataSizeBytes", "BucketName", "${var.gh_bucket_name}", "StorageType", "AllStorageTypes", { "stat": "Sum", "label": "Data Size" } ],
          [ ".", "NumberOfObjects", ".", ".", ".", ".", { "stat": "SampleCount", "label": "Number of Objects" } ],
          [ ".", "DataSizeBytes", ".", ".", ".", ".", { "stat": "SampleCount", "label": "Number of Objects" } ]
        ],
        "region": "${var.region}",
        "title": "Data Size and Object Count"
      }
    }
  ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "dashboard_user_policy" {
  count      = length(var.users)
  user       = aws_iam_user.bucket_dashboard_users[count.index].name
  policy_arn = aws_iam_policy.dashboard_policy.arn
}

resource "aws_iam_group_policy_attachment" "dashboard_group_policy" {
  group      = aws_iam_group.bucket_dashboard_group.name
  policy_arn = aws_iam_policy.dashboard_policy.arn
}

resource "aws_iam_policy" "dashboard_policy" {
  name        = "CloudWatchDashboardPolicy"
  description = "Policy for accessing the CloudWatch dashboard"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:DescribeDashboard",
        "cloudwatch:GetDashboard",
        "cloudwatch:ListDashboards"
      ],
      "Resource": "arn:aws:cloudwatch:*:*:dashboard/S3BucketDashboard"
    }
  ]
}
EOF
}

output "Bucket_files_name" {
  value = "${aws_s3_bucket.bucket_files.bucket}"
}
