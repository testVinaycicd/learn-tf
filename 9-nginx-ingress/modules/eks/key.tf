# ensure we can reference the current account id
data "aws_caller_identity" "current" {}

# CMK for EKS node EBS volumes (with policy allowing node role + EC2 to create grants)
resource "aws_kms_key" "eks_nodes" {
  description             = " node EBS CMK"
  deletion_window_in_days = 7

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-policy"
    Statement = [
      {
        Sid    = "AllowAccountRootFullAccess"
        Effect = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowNodeRoleUse"
        Effect = "Allow"
        Principal = { AWS = aws_iam_role.node-role.arn }
        Action = [
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowCreateGrantsForAWSResources"
        Effect = "Allow"
        Principal = { AWS = aws_iam_role.node-role.arn }
        Action = [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ]
        Resource = "*"
        Condition = { Bool = { "kms:GrantIsForAWSResource" = "true" } }
      },
      {
        Sid    = "AllowEC2ServiceToUseForAWS"
        Effect = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action = [
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = { Bool = { "kms:GrantIsForAWSResource" = "true" } }
      }
    ]
  })

  tags = {
    Name = "${var.env}-eks-nodes-key"
  }
}

# friendly alias for the CMK
resource "aws_kms_alias" "eks_nodes_alias" {
  name          = "alias/${var.env}-eks-nodes"
  target_key_id = aws_kms_key.eks_nodes.key_id
}
