resource "aws_iam_role_policy_attachment" "s3_access_attachment" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# This is needed so that the s3 buckets can depend on it. This is to show the use of depends_on as an example
resource "aws_iam_group_policy_attachment" "devops_s3_access_attachment" {
  group      = var.s3_access_group
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role" "bucket_dashboard_role" {
  count              = length(var.users)
  name               = "${var.users[count.index].full_name}_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "bucket_dashboard_policy_attachment" {
  count = length(var.users)

  role       = aws_iam_role.bucket_dashboard_role[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_user" "bucket_dashboard_users" {
  count = length(var.users)

  name = replace(var.users[count.index].full_name, " ", "-")
}
resource "aws_iam_group" "bucket_dashboard_group" {
  name = var.bucket_dashboard_group_name
}
resource "aws_iam_group_membership" "bucket_dashboard_group_membership" {
  count = length(var.users)

  name  = aws_iam_group.bucket_dashboard_group.name
  users = [aws_iam_user.bucket_dashboard_users[count.index].name]
  group = var.bucket_dashboard_group_name
}
