#!/bin/bash
set -e

################################################################################
# 🧹 stop.sh – Cleanly shuts down LocalStack and removes local DNS entries
#
# This script:
#   1. Stops any running LocalStack containers.
#   2. Force removes all LocalStack containers, even if exited.
#   3. Cleans up the `/etc/hosts` file by removing any leftover entries related
#      to LocalStack's API Gateway domain.
#
# Meant to be run from the /scripts directory.
################################################################################

# 🛑 Stop all running LocalStack containers (ignores errors if none found)
docker ps --filter "ancestor=localstack/localstack" -q | xargs -r -n1 docker stop 2>/dev/null || true

# 🧨 Remove all LocalStack containers, including stopped ones (safe cleanup)
docker ps -a --filter "ancestor=localstack/localstack" -q | xargs -r -n1 docker rm -f 2>/dev/null || true

echo "LocalStack containers stopped and removed."

# 🧼 Remove LocalStack API Gateway hostnames from /etc/hosts (no port numbers)
# This ensures local DNS entries are cleaned up to avoid conflicts later
sudo /usr/bin/sed -i.bak '/\.execute-api\.localhost\.localstack\.cloud/d' /etc/hosts

echo "Removed LocalStack host entries from /etc/hosts."