#!/bin/bash
# One-time CodeDeploy setup for eu-north-1.
# Run from a machine with AWS CLI configured for account 104531737272.
set -e

AWS_REGION="eu-north-1"
APP_NAME="deliverytimeprediction"
DEPLOY_GROUP="deliverytimepredictiondeploymentgroup"
EC2_TAG_KEY="Project"
EC2_TAG_VALUE="delivery-time-prediction"

echo "Creating CodeDeploy application: ${APP_NAME}"
aws deploy create-application \
  --application-name "${APP_NAME}" \
  --compute-platform Server \
  --region "${AWS_REGION}" \
  2>/dev/null || echo "Application may already exist."

echo "Creating CodeDeploy service role (if missing)..."
aws iam create-role \
  --role-name CodeDeployServiceRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "codedeploy.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }' 2>/dev/null || true

aws iam attach-role-policy \
  --role-name CodeDeployServiceRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole \
  2>/dev/null || true

SERVICE_ROLE_ARN=$(aws iam get-role --role-name CodeDeployServiceRole --query Role.Arn --output text)

echo "Creating deployment group: ${DEPLOY_GROUP}"
aws deploy create-deployment-group \
  --application-name "${APP_NAME}" \
  --deployment-group-name "${DEPLOY_GROUP}" \
  --service-role-arn "${SERVICE_ROLE_ARN}" \
  --deployment-config-name CodeDeployDefault.OneAtATime \
  --ec2-tag-filters "Key=${EC2_TAG_KEY},Value=${EC2_TAG_VALUE},Type=KEY_AND_VALUE" \
  --region "${AWS_REGION}" \
  2>/dev/null || echo "Deployment group may already exist."

echo ""
echo "Done. Tag your EC2 instance before deploying:"
echo "  aws ec2 create-tags --resources i-042e09d5f739a0678 --tags Key=${EC2_TAG_KEY},Value=${EC2_TAG_VALUE} --region ${AWS_REGION}"
echo ""
echo "On the EC2 instance, install and start the CodeDeploy agent:"
echo "  sudo apt-get update && sudo apt-get install -y ruby wget"
echo "  cd /home/ubuntu"
echo "  wget https://aws-codedeploy-${AWS_REGION}.s3.${AWS_REGION}.amazonaws.com/latest/install"
echo "  chmod +x ./install && sudo ./install auto"
echo "  sudo service codedeploy-agent status"
