#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

output "bah_kali_linux_arn" {
    value = "${aws_imagebuilder_image.bah_kali_linux_image.arn}"
    description = "ARN of the Kali Linux image"
}

#output "bah_kali_linux_ami_id" {
#    value = "${aws_imagebuilder_image.bah_kali_linux_image.output_resources[0].amis[0].image}"
#}

# TODO cmm - I'm currently stuck here
# $ aws ec2 export-image --disk-image-format VMDK --image-id ami-0b89c86d965afab5d --s3-export-location S3Bucket=bah-machine-images,S3Prefix=kali/ --role-name CiscoModelingLabsBuild
#
# An error occurred (InvalidParameter) when calling the ExportImage operation: The service role CiscoModelingLabsBuild provided does not exist or does not have sufficient permissions
