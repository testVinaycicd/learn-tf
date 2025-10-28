# ---------- IAM for EC2 (KMS + SSM) ----------
resource "aws_iam_role" "vault" {
  name               = "${var.name}-vault-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}


data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "minimal_role" {
  name = "${var.name}-minimal_roal"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:*",
          "elasticloadbalancing:*",
          "iam:*",
          "kms:*",
          "route53:*",
          "ssm:*",
          "cloudwatch:*",
          "logs:*"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "minimal_role" {
  role       = aws_iam_role.vault.name
  policy_arn = aws_iam_policy.minimal_role.arn
}


resource "aws_iam_instance_profile" "vault" {
  name = "${var.name}-vault-instance-profile"
  role = aws_iam_role.vault.name
}