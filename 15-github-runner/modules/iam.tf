resource "aws_iam_role" "main" {
  name = "${var.name}-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_instance_profile" "main" {
  name = "${ var.name }-role"
  role = aws_iam_role.main.name
}

resource "aws_iam_policy" "policy" {
  name = "${ var.name }-role-policy"
  path = "/"
  description = "${ var.name }-role-policy"

  # policy = jsonencode({
  #   Version = "2012-10-17"
  #   Statement = [
  #     {
  #       Action   = ["account:ListRegions", "*"]
  #       Effect   = "Allow"
  #       Resource = ["*"]
  #     },
  #   ]
  # })
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = local.policy_action
        Effect   = "Allow"
        Resource = length(var.iam_policy["Resource"]) == 0 ? ["*"] : var.iam_policy["Resource"]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "main" {
  role      = aws_iam_role.main.name
  policy_arn = aws_iam_policy.policy.arn
}