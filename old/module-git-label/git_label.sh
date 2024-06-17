#!/bin/bash

#
# This file is part of Becoming a Hacker Foundations
# Copyright (c) 2024, Cisco Systems, Inc.
# All rights reserved.
#

# This script is for getting the current git label
# e.g. main-0-g1519e3f-dirty
# https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external

# Exit if any of the intermediate steps fail
set -e

LABEL="$(git describe --all --long --tags --dirty 2>/dev/null | cut -d '/' -f 2)"

# Safely produce a JSON object containing the result value.
# jq will ensure that the value is properly quoted
# and escaped to produce a valid JSON string.
jq -n --arg LABEL "$LABEL" '{"git-label":$LABEL}'
