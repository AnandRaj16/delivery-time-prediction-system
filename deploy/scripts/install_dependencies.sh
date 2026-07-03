#!/bin/bash
set -e

# Install Docker if it is not already present
if ! command -v docker &> /dev/null; then
    apt-get update -y
    apt-get install -y docker.io
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ubuntu || true
fi

# Install AWS CLI v2 if it is not already present
if ! command -v aws &> /dev/null; then
    apt-get install -y unzip curl
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    ./aws/install
    rm -rf awscliv2.zip aws
fi
