#
# This file is part of Cisco Modeling Labs
# Copyright (c) 2019-2023, Cisco Systems, Inc.
# All rights reserved.
#

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.56.0"
    }
  }

  required_version = ">= 1.1.0"

  backend "s3" {
    bucket = "bah-cml-terraform-state"
    key    = "bah-kali-linux-img"
    region = "us-east-2"
  }
}
