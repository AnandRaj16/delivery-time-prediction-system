#!/bin/bash
set -e

# ---- Configure these for your AWS account ----
AWS_REGION="ap-south-1"
ECR_REGISTRY="<ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com"   # TODO: set your ECR registry host
ECR_REPOSITORY="<REPO_NAME>"                                    # TODO: set your ECR repository name
IMAGE_TAG="latest"
CONTAINER_NAME="delivery-time-prediction"
HOST_PORT="80"
# DAGSHUB token so the container can load the model from the MLflow registry at startup.
# Recommended: inject via SSM Parameter Store / instance env rather than committing it.
DAGSHUB_USER_TOKEN="${DAGSHUB_USER_TOKEN:-}"
MODEL_STAGE="${MODEL_STAGE:-Production}"
# ----------------------------------------------

IMAGE_URI="${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"

# Authenticate to ECR using the EC2 instance IAM role
aws ecr get-login-password --region "$AWS_REGION" \
    | docker login --username AWS --password-stdin "$ECR_REGISTRY"

# Pull the latest image
docker pull "$IMAGE_URI"

# Remove any existing container
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

# Run the new container (host port 80 -> container port 8000)
docker run -d \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    -p "${HOST_PORT}":8000 \
    -e DAGSHUB_USER_TOKEN="$DAGSHUB_USER_TOKEN" \
    -e MODEL_STAGE="$MODEL_STAGE" \
    "$IMAGE_URI"
