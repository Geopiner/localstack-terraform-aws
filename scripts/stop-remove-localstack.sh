#!/bin/bash
set -e

# Stop all running LocalStack containers (ignore errors)
docker ps --filter "ancestor=localstack/localstack" -q | xargs -r -n1 docker stop 2>/dev/null || true

# Remove all LocalStack containers (running or stopped) (ignore errors)
docker ps -a --filter "ancestor=localstack/localstack" -q | xargs -r -n1 docker rm -f 2>/dev/null || true

echo "LocalStack containers stopped and removed."

# Remove LocalStack API hostname from /etc/hosts (without port)
sudo /usr/bin/sed -i.bak '/\.execute-api\.localhost\.localstack\.cloud/d' /etc/hosts

echo "Removed LocalStack host entries from /etc/hosts."