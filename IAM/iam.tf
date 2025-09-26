# 1) Create user Alice
resource "aws_iam_user" "alice" {
  name = "Alice"
}

# 2) Create the role (badge) with a trust policy that allows Alice to assume it
data "aws_iam_policy_document" "trust_for_alice" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.alice.arn]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "alice_badge" {
  name               = "alice-badge-role"
  assume_role_policy = data.aws_iam_policy_document.trust_for_alice.json
}

# 3) Attach a permission policy directly to the role (inline)
resource "aws_iam_role_policy" "role_inline_policy" {
  role = aws_iam_role.alice_badge.id
  name = "alice-badge-s3-read"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:ListBucket"]
      Resource = ["arn:aws:s3:::project-bucket", "arn:aws:s3:::project-bucket/*"]
    }]
  })
}

# 4) Give Alice permission to call sts:AssumeRole (identity policy on Alice)
resource "aws_iam_user_policy" "alice_can_assume" {
  user = aws_iam_user.alice.name
  name = "allow-assume-alice-badge"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = aws_iam_role.alice_badge.arn
    }]
  })
}


# you don’t need to give eks.amazonaws.com an explicit sts:AssumeRole permission via a user policy because the principal in the role trust is the service itself (EKS) and AWS services are allowed to assume roles they are trusted for by the trust policy. Let me break that down slowly and clearly.

# For a user (human or IAM role in same account)
#
# You need two things:
#
# Create the badge (IAM role)
#   1)Role has a trust policy → “I trust Alice (or Bob, or this account) to wear me.”
#
#
# Give the user permission to ask for the badge
#   2)On Alice’s identity (user, group, or another role) you attach a policy that allows:
#
# If you miss step 2, Alice will get AccessDenied even if the role trusts her.