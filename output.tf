#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

output "bah_kali_linux_arn" {
  value       = aws_imagebuilder_image.bah_kali_linux_image.arn
  description = "ARN of the Kali Linux image"
}
