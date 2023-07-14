resource "aws_iam_role" "bucket_dashboard_role" {
  for_each = { for u in var.users : u.full_name => u }

  name               = replace(each.value.full_name, " ", "-")
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.new.account_id}:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

#resource "aws_iam_role_policy_attachment" "bucket_dashboard_policy_attachment" {
#  count = length(var.users)
#
#  role       = aws_iam_role.bucket_dashboard_role[count.index].name
#  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
#}

resource "aws_iam_user" "bucket_dashboard_users" {
  count = length(var.users)

  name = replace(var.users[count.index].full_name, " ", "-")
}

#resource "aws_iam_user_policy_attachment" "bucket_dashboard_user_policy_attachment" {
#  count = length(var.users)
#
#  user       = aws_iam_user.bucket_dashboard_users[count.index].name
#  policy_arn = "arn:aws:iam::${data.aws_caller_identity.new.account_id}:policy/${aws_iam_role.bucket_dashboard_role[count.index].name}-access"
#}

resource "aws_iam_group" "bucket_dashboard_group" {
  name = var.bucket_dashboard_group_name
}

resource "aws_iam_group_membership" "bucket_dashboard_group_membership" {
  count = length(var.users)

  name  = aws_iam_group.bucket_dashboard_group.name
  users = [aws_iam_user.bucket_dashboard_users[count.index].name]
  group = var.bucket_dashboard_group_name
}

