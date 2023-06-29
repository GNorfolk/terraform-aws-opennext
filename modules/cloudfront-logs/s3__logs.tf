data "aws_canonical_user_id" "current" {}

# TODO: CKV_AWS_18: "Ensure the S3 bucket has access logging enabled"
# TODO: CKV_AWS_144: "Ensure that S3 bucket has cross-region replication enabled"
# TODO: CKV_AWS_145: "Ensure that S3 buckets are encrypted with KMS by default"
resource "aws_s3_bucket" "logs" {
  bucket = var.log_bucket_name
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.bucket

  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "logs" {
  depends_on = [aws_s3_bucket_ownership_controls.logs]
  bucket     = aws_s3_bucket.logs.bucket

  access_control_policy {
    owner {
      id = data.aws_canonical_user_id.current.id
    }

    grant {
      permission = "FULL_CONTROL"

      grantee {
        id   = data.aws_canonical_user_id.current.id
        type = "CanonicalUser"
      }
    }

    # Grant CloudFront access to the S3 bucket
    # See: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/AccessLogs.html#AccessLogsBucketAndFileOwnership
    grant {
      permission = "FULL_CONTROL"

      grantee {
        id   = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"
        type = "CanonicalUser"
      }
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.bucket

  rule {
    id = "abort-failed-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }

  rule {
    id     = "log-expiration"
    status = "Enabled"

    expiration {
      days = var.retention
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.bucket
  
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.log_bucket_kms_key_arn
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_logging" "logs" {
  count = var.log_bucket_logging_config != null ? 1 : 0
  
  bucket = aws_s3_bucket.logs.bucket
  
  target_bucket = var.log_bucket_logging_config.target_bucket
  target_prefix = var.log_bucket_logging_config.target_prefix  
}


resource "aws_s3_bucket_replication_configuration" "logs" {
  count = var.log_bucket_replication_configuration == null ? 0 : 1

  depends_on = [aws_s3_bucket_versioning.logs]
  bucket = aws_s3_bucket.logs.bucket

  dynamic "rule" {
    for_each = var.log_bucket_replication_configuration.rules

    content {
      id = rule.id
      status = rule.status

      dynamic "filter" {
        for_each = rule.filters
        
        content {
          prefix = filter.prefix
        }
      }

      destination {
        bucket = rule.destination.bucket
        storage_class = rule.destination.storage_class
      }
    }
  }
}

data "aws_iam_policy_document" "logs_readonly_policy" {
  statement {
    actions = [
      "s3:Get*",
      "s3:List*",
    ]

    resources = [
      aws_s3_bucket.logs.arn,
      "${aws_s3_bucket.logs.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_notification" "logs_notification" {
  bucket = aws_s3_bucket.logs.bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.cloudfront_logs_function.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.s3_bucket_invoke_function]
}