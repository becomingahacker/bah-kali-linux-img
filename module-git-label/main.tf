#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

data "external" "git_label" {
  program = ["bash", "${path.module}/git_label.sh"]
}

# Show the results of running the data source. This is a map of environment
# variable names to their values.
output "git_label" {
  description = "value of the git label"
  value       = data.external.git_label.result
}
