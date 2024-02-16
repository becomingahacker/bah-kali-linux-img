#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

resource "aws_imagebuilder_component" "kali_linux_base" {
  name      = "kali-linux-base"
  version   = "1.0.0"
  platform  = "Linux"
  data_type = "Shell"
  uri       = "https://example.com/kali-linux-base.sh"
}

resource "aws_imagebuilder_image_recipe" "kali_linux_recipe" {
  name        = "kali-linux-recipe"
  parent_image = "arn:aws:imagebuilder:us-west-2:aws:image/amazon-linux-2-x86/x.x.x"
  components  = [aws_imagebuilder_component.kali_linux_base.arn]
}

resource "aws_imagebuilder_distribution_configuration" "kali_linux_distribution" {
  name = "kali-linux-distribution"
  distributions {
    region = "us-west-2"
    ami_distribution_configuration {
      name      = "kali-linux-ami"
      description = "Kali Linux AMI"
      ami_tags = {
        Name = "Kali Linux"
      }
    }
  }
}

resource "aws_imagebuilder_image" "kali_linux_image" {
  name                    = "kali-linux-image"
  image_recipe_arn        = aws_imagebuilder_image_recipe.kali_linux_recipe.arn
  distribution_configuration_arns = [aws_imagebuilder_distribution_configuration.kali_linux_distribution.arn]
  infrastructure_configuration {
    instance_profile_name = "image-builder-role"
    instance_types        = ["t2.micro"]
    subnet_id             = "subnet-12345678"
} 
