#################################
# IAM policies
#################################

locals {
  policy_s3 = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        "Resource" : [
          "arn:aws:s3:::${var.installation_location.s3_bucket}",
          "arn:aws:s3:::${var.installation_location.s3_bucket}/*",
        ]
      }
    ]
    }
  )
}

resource "aws_iam_policy" "s3_policy" {
  description = "DSF installation tarball s3 policy"
  policy      = local.policy_s3
}

resource "aws_iam_role_policy_attachment" "policy_attach1" {
  role       = local.role_name
  policy_arn = aws_iam_policy.s3_policy.arn
}
