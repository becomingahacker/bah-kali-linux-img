#!/bin/bash

# Becoming a Hacker installation script

# HACK cmm - This script installs requisite software and tools for the Becoming
# a Hacker Foundations labs.  Things are copied into
# /provision/becoming-a-hacker and cloud-init is meant to copy this directory to
# the user's home directory or root to make everything available.

set -x
set -e

cd /provision/becoming-a-hacker
gcloud storage cp --recursive gs://bah-machine-images/becoming-a-hacker/www/* ./
