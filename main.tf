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

module "git_label" {
  source = "./module-git-label"
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
              commands = [for command in local.cfg.kali_linux_build_commands : command]
            }
            name      = "kali_linux_build_commands"
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

data "aws_ami" "offsec_kali_linux_ami" {
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
  parent_image = data.aws_ami.offsec_kali_linux_ami.id
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
    uninstall_after_build = true
  }
}

resource "aws_imagebuilder_distribution_configuration" "bah_kali_linux_distribution" {
  name = "bah_kali_linux_distribution"

  description = "Distribution for building Kali Linux in the Cloud"

  distribution {
    region = local.cfg.aws.region
    ami_distribution_configuration {
      name        = "bah-kali-linux-{{ imagebuilder:buildDate }}"
      description = "BAH Kali Linux AMI"
      ami_tags = {
        Name    = "bah-kali-linux-{{ imagebuilder:buildDate }}"
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

  enhanced_image_metadata_enabled = false

  timeouts {
    create = "60m"
  }
}


output "bah_kali_linux_ami_id" {
  value = one(aws_imagebuilder_image.bah_kali_linux_image.output_resources[0].amis).image
}

data "aws_ami" "bah_kali_linux_ami" {
  filter {
    name   = "image-id"
    values = [one(aws_imagebuilder_image.bah_kali_linux_image.output_resources[0].amis).image]
  }
}

output "bah_kali_linux_ami" {
  value = data.aws_ami.bah_kali_linux_ami
}

resource "aws_ebs_volume" "bah_kali_linux_image_volume" {
  availability_zone = local.cfg.aws.availability_zone
  size              = one(data.aws_ami.bah_kali_linux_ami.block_device_mappings).ebs.volume_size
  snapshot_id       = one(data.aws_ami.bah_kali_linux_ami.block_device_mappings).ebs.snapshot_id

  tags = {
    Name   = "bah-kali-linux-image"
    Region = data.aws_region.current.name
  }
}

data "aws_ami" "ubuntu_jammy_server_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_imagebuilder_component" "bah_kali_linux_exporter" {
  data = yamlencode({
    phases = [
      {
        name = "build"
        steps = [
          {
            action    = "ExecuteBash"
            name      = "Install_Dependencies"
            onFailure = "Abort"
            inputs = {
              commands = [
                "apt update",
                "apt upgrade -y",
                "apt install -y qemu-utils jq awscli",
              ]
            }
          },
          {
            action    = "ExecuteBash"
            name      = "Export_Kali_Linux_to_Cisco_Modeling_Labs"
            onFailure = "Abort"
            inputs = {
              commands = [
                "lsblk",
                #	2024-02-20T00:44:58.141-05:00	Stdout: nvme1n1 259:1 0 16G 0 disk
                # 2024-02-20T00:44:58.141-05:00	Stdout: ├─nvme1n1p1 259:6 0 15.9G 0 part
                # 2024-02-20T00:44:58.141-05:00	Stdout: ├─nvme1n1p14 259:7 0 3M 0 part
                # 2024-02-20T00:44:58.141-05:00	Stdout: └─nvme1n1p15 259:8 0 124M 0 part
                "qemu-img convert -p -f raw -O qcow2 /dev/nvme1n1 /root/${local.cfg.kali_linux_image_definition.disk_image}",
                "PASS=\"$(aws secretsmanager get-secret-value --region ${local.cfg.aws.region} --secret-id ${local.cfg.secrets.app_password} | jq -r .SecretString)\"",
                "TOKEN=\"$(curl -s -k -X 'POST' '${local.cfg.cml_controller_url}/api/v0/authenticate' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{\"username\": \"admin\", \"password\": \"'$PASS'\"}' | jq -r . )\"",
                "curl -k -X 'POST' -H \"Authorization: Bearer $TOKEN\" -H 'X-Original-File-Name: ${local.cfg.kali_linux_image_definition.disk_image}' -T /root/${local.cfg.kali_linux_image_definition.disk_image} -H 'Content-Type: application/octet-stream' '${local.cfg.cml_controller_url}/api/v0/images/upload'",
              ]
            }
          },
          {
            action    = "CreateFile"
            name      = "Create_Image_and_Node_Definition_Files"
            onFailure = "Abort"
            inputs = [
              {
                path    = "/root/image_definition.json"
                content =  jsonencode(local.cfg.kali_linux_image_definition)
              },
              {
                path    = "/root/node_definition.json"
                content = jsonencode(local.cfg.kali_linux_node_definition)
              }
            ]
          },
          {
            action    = "ExecuteBash"
            name      = "Create_Image_and_Node_Definitions_in_Cisco_Modeling_Labs"
            onFailure = "Abort"
            inputs = {
              commands = [
                "PASS=\"$(aws secretsmanager get-secret-value --region ${local.cfg.aws.region} --secret-id ${local.cfg.secrets.app_password} | jq -r .SecretString)\"",
                "TOKEN=\"$(curl -s -k -X 'POST' '${local.cfg.cml_controller_url}/api/v0/authenticate' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{\"username\": \"admin\", \"password\": \"'$PASS'\"}' | jq -r . )\"",
                "curl -k -v -X 'POST' -H \"Authorization: Bearer $TOKEN\" -H 'Content-Type: application/json' --data-binary @/root/node_definition.json '${local.cfg.cml_controller_url}/api/v0/node_definitions'",
                "curl -k -v -X 'POST' -H \"Authorization: Bearer $TOKEN\" -H 'Content-Type: application/json' --data-binary @/root/image_definition.json '${local.cfg.cml_controller_url}/api/v0/image_definitions'",
              ]
            }
          },
        ]
      },
    ]
    schemaVersion = 1.0
  })
  name        = "bah_kali_linux_exporter"
  description = "Export Kali Linux to Cisco Modeling Labs"
  platform    = "Linux"
  version     = "1.0.0"
}

resource "aws_imagebuilder_image_recipe" "bah_kali_linux_exporter_recipe" {
  name         = "bah_kali_linux_exporter_recipe"
  parent_image = data.aws_ami.ubuntu_jammy_server_ami.id
  version      = "1.0.0"

  block_device_mapping {
    device_name = "/dev/sda1"

    ebs {
      delete_on_termination = true
      volume_size           = local.cfg.aws.disk_size * 2
      volume_type           = "gp2"
    }
  }

  block_device_mapping {
    device_name = "/dev/sdd"

    ebs {
      delete_on_termination = true
      volume_size           = local.cfg.aws.disk_size
      volume_type           = "gp2"
      snapshot_id           = aws_ebs_volume.bah_kali_linux_image_volume.snapshot_id
    }
  }

  component {
    component_arn = aws_imagebuilder_component.bah_kali_linux_exporter.arn

    #parameter {
    #  name  = "Parameter1"
    #  value = "Value1"
    #}

    #parameter {
    #  name  = "Parameter2"
    #  value = "Value2"
    #}
  }

  working_directory = "/root"

  systems_manager_agent {
    uninstall_after_build = false
  }
}

resource "aws_imagebuilder_distribution_configuration" "bah_kali_linux_exporter_distribution" {
  name = "bah_kali_linux_exporter_distribution"

  description = "Distribution for exporting Kali Linux in the Cloud"

  distribution {
    region = local.cfg.aws.region
    ami_distribution_configuration {
      name        = "bah-kali-linux-exporter-{{ imagebuilder:buildDate }}"
      description = "BAH Kali Linux Exporter AMI"
      ami_tags = {
        Name = "bah-kali-linux-exporter-{{ imagebuilder:buildDate }}"
      }
    }
  }
}

resource "aws_imagebuilder_image" "bah_kali_linux_exporter" {
  image_recipe_arn                 = aws_imagebuilder_image_recipe.bah_kali_linux_exporter_recipe.arn
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.bah_kali_linux_exporter_distribution.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.bah_kali_linux_infra_config.arn

  image_tests_configuration {
    image_tests_enabled = false
  }

  enhanced_image_metadata_enabled = false

  #timeouts {
  #  create = "60m"
  #}
}
