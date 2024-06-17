#!/bin/bash

set -e
set -x

env

flock -w 120 /var/lib/apt/lists/lock -c 'echo waiting for lock'

#apt-get install -y <some package>

cloud-init clean -c all -l --machine-id
