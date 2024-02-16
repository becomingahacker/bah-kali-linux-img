#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

locals {
  cfg = yamldecode(var.cfg)
  vmimport_assume_role_policy = {
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "vmie.amazonaws.com"
        },
        Action = "sts:AssumeRole",
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "vmimport"
          }
        }
      }
    ]
  }
  vmimport_bucket_policy = {
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowBucketAccess",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/vmimport_role"
        },
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::${local.cfg.aws.bucket}",
          "arn:aws:s3:::${local.cfg.aws.bucket}/*"
        ]
      }
    ]
  }
}

# Data source to get the current AWS account ID
data "aws_caller_identity" "current" {}

# Create the vmimport role
resource "aws_iam_role" "vmimport_role" {
  name               = "vmimport_role"
  assume_role_policy = jsonencode(local.vmimport_assume_role_policy)
}

# Attach the necessary policies to the vmimport role
resource "aws_iam_role_policy_attachment" "vmimport_policy_attachment" {
  role       = aws_iam_role.vmimport_role.name
  policy_arn = "arn:aws:iam::aws:policy/VMImportExportRoleForAWSConnector"
}

# Grant S3 bucket access to the vmimport role
resource "aws_s3_bucket_policy" "vmimport_bucket_policy" {
  bucket = local.cfg.aws.bucket
  policy = jsonencode(local.vmimport_bucket_policy)
}

