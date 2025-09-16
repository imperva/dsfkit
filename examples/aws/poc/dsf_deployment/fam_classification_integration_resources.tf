data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "random_id" "fam_scan_results_bucket_suffix" {
  count       = var.create_fam_classification_integration_resources ? 1 : 0
  byte_length = 4 # 4 bytes → 8 hex chars
}

resource "aws_s3_bucket" "fam_scan_results_bucket" {
  count         = var.create_fam_classification_integration_resources ? 1 : 0
  bucket        = join("-", [local.deployment_name_salted, "fam", "scan", "results", "bucket", random_id.fam_scan_results_bucket_suffix[0].hex])
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "fam_scan_results_bucket_encryption" {
  count  = var.create_fam_classification_integration_resources ? 1 : 0
  bucket = aws_s3_bucket.fam_scan_results_bucket[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "fam_scan_results_bucket_pab" {
  count  = var.create_fam_classification_integration_resources ? 1 : 0
  bucket = aws_s3_bucket.fam_scan_results_bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "fam_scan_results_bucket_enforce_ssl" {
  count  = var.create_fam_classification_integration_resources ? 1 : 0
  bucket = aws_s3_bucket.fam_scan_results_bucket[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.fam_scan_results_bucket[0].id}",
          "arn:aws:s3:::${aws_s3_bucket.fam_scan_results_bucket[0].id}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

resource "aws_sqs_queue" "fam_scan_results_bucket_notifications_sqs" {
  count                   = var.create_fam_classification_integration_resources ? 1 : 0
  name                    = join("-", [local.deployment_name_salted, "fam", "scan", "results", "bucket", "notifications", "sqs"])
  sqs_managed_sse_enabled = true

  tags = local.tags
}

resource "aws_sqs_queue_policy" "fam_scan_results_bucket_notifications_sqs_policy" {
  count     = var.create_fam_classification_integration_resources ? 1 : 0
  queue_url = aws_sqs_queue.fam_scan_results_bucket_notifications_sqs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "PolicyForS3ToSendMessageToSQS"
    Statement = [
      {
        Sid    = "PolicyForS3ToSendMessageToSQS"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "SQS:SendMessage"
        Resource = aws_sqs_queue.fam_scan_results_bucket_notifications_sqs[0].arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" : "arn:aws:s3:*:*:${aws_s3_bucket.fam_scan_results_bucket[0].id}"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "fam_scan_results_bucket_notification" {
  count  = var.create_fam_classification_integration_resources ? 1 : 0
  bucket = aws_s3_bucket.fam_scan_results_bucket[0].id

  queue {
    id        = "fam_classification_scan_result_incoming"
    queue_arn = aws_sqs_queue.fam_scan_results_bucket_notifications_sqs[0].arn
    events = [
      "s3:ObjectCreated:Put",
      "s3:ObjectCreated:CompleteMultipartUpload"
    ]
    filter_prefix = "scan_result/incoming/"
  }

  depends_on = [aws_sqs_queue_policy.fam_scan_results_bucket_notifications_sqs_policy]
}

resource "aws_iam_policy" "fam_classification_integration_policy" {
  count       = var.create_fam_classification_integration_resources ? 1 : 0
  name        = join("-", [local.deployment_name_salted, "fam", "classification", "integration", "policy"])
  description = "Policy for FAM Classification service"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetBucketNotification"
        ]
        Resource = [
          aws_s3_bucket.fam_scan_results_bucket[0].arn,
          "${aws_s3_bucket.fam_scan_results_bucket[0].arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = aws_sqs_queue.fam_scan_results_bucket_notifications_sqs[0].arn
      }
    ]
  })
  tags = local.tags
}


