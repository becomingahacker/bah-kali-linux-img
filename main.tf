#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

locals {
  cfg_file = file("config.yml")
  cfg      = yamldecode(local.cfg_file)
}

provider "aws" {
  default_tags {
    tags = {
      Project = "cloud-cml"
    }
  }
}

data "aws_region" "current" {}

resource "aws_imagebuilder_component" "bah_kali_linux_base" {
  data = yamlencode({
    phases = [
      {
        name = "build"
        steps = [
          {
            action = "ExecuteBash"
            inputs = {
              commands = ["echo 'hello world3'"]
            }
            name      = "hello"
            onFailure = "Continue"
          },
        ]
      },
    ]
    schemaVersion = 1.0
  })
  name        = "bah_kali_linux_base"
  description = "Build Kali Linux in the Cloud"
  platform    = "Linux"
  version     = "1.0.0"
}

data "aws_key_pair" "bah_kali_linux_key_pair" {
  key_name = local.cfg.aws.key_name
}

data "aws_iam_instance_profile" "bah_kali_linux_instance_profile" {
  name = local.cfg.aws.instance_profile
}

data "aws_security_group" "bah_kali_linux_security_group" {
  name = local.cfg.aws.security_group
}

data "aws_subnet" "bah_kali_linux_subnet" {
  filter {
    name   = "tag:Name"
    values = [local.cfg.aws.subnet]
  }
}

resource "aws_imagebuilder_infrastructure_configuration" "bah_kali_linux_infra_config" {
  description                   = "Infrastructure for building Kali Linux in the Cloud"
  instance_profile_name         = data.aws_iam_instance_profile.bah_kali_linux_instance_profile.name
  instance_types                = [local.cfg.aws.instance_type]
  key_pair                      = data.aws_key_pair.bah_kali_linux_key_pair.key_name
  name                          = "bah_kali_linux_infra_config"
  security_group_ids            = [data.aws_security_group.bah_kali_linux_security_group.id]
  subnet_id                     = data.aws_subnet.bah_kali_linux_subnet.id
  terminate_instance_on_failure = true

  #sns_topic_arn                 = aws_sns_topic.example.arn
  #logging {
  #  s3_logs {
  #    s3_bucket_name = aws_s3_bucket.example.bucket
  #    s3_key_prefix  = "logs"
  #  }
  #}
}

data "aws_ami" "bah_kali_linux_ami" {
  most_recent = true

  owners = ["679593333241"] # OffSec

  filter {
    name   = "description"
    values = ["Kali Linux kali-last-snapshot (2023.4.0)"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_imagebuilder_image_recipe" "bah_kali_linux_image_recipe" {
  name         = "bah_kali_linux_image_recipe"
  parent_image = data.aws_ami.bah_kali_linux_ami.id
  version      = "1.0.0"

  block_device_mapping {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      volume_size           = local.cfg.aws.disk_size
      volume_type           = "gp2"
    }
  }

  component {
    component_arn = aws_imagebuilder_component.bah_kali_linux_base.arn

    #parameter {
    #  name  = "Parameter1"
    #  value = "Value1"
    #}

    #parameter {
    #  name  = "Parameter2"
    #  value = "Value2"
    #}
  }

  working_directory = "/"

  systems_manager_agent {
    uninstall_after_build = false
  }
}

resource "aws_imagebuilder_distribution_configuration" "bah_kali_linux_distribution" {
  name = "bah_kali_linux_distribution"

  description = "Distribution for building Kali Linux in the Cloud"

  distribution {
    region = local.cfg.aws.region
    ami_distribution_configuration {
      name        = "bah-kali-linux {{ imagebuilder:buildDate }}"
      description = "BAH Kali Linux AMI"
      ami_tags = {
        Project = "cloud-cml"
      }
    }
  }
}

resource "aws_imagebuilder_image" "bah_kali_linux_image" {
  image_recipe_arn                 = aws_imagebuilder_image_recipe.bah_kali_linux_image_recipe.arn
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.bah_kali_linux_distribution.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.bah_kali_linux_infra_config.arn
  image_tests_configuration {
    image_tests_enabled = false
  }
}


output "bah_kali_linux_image_ami_id" {
  value = one(aws_imagebuilder_image.bah_kali_linux_image.output_resources[0].amis).image
}

data "aws_ami" "bah_kali_linux_image_ami" {
  filter {
    name   = "image-id"
    values = [ one(aws_imagebuilder_image.bah_kali_linux_image.output_resources[0].amis).image ]
  }
}

output "bah_kali_linux_image_ami" {
  value = data.aws_ami.bah_kali_linux_image_ami
}

resource "aws_ebs_volume" "bah_kali_linux_image_volume" {
  availability_zone = local.cfg.aws.availability_zone
  size        = one(data.aws_ami.bah_kali_linux_image_ami.block_device_mappings).ebs.volume_size
  snapshot_id = one(data.aws_ami.bah_kali_linux_image_ami.block_device_mappings).ebs.snapshot_id

  tags = {
    Name = "bah-kali-linux-image"
    Region = data.aws_region.current.name
  }
}
