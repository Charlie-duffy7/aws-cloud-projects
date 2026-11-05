#!/bin/bash
# AWS CLI commands I ran for this project, in order.
# I ran these from inside the NASA EPIC package repo with Dockerfile.lambda added.
# Put your own bucket name and email here first.

REGION="us-east-1"
BUCKET="nasa-epic-images-yourname"
EMAIL="you@example.com"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
IMAGE="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/nasa-epic-lambda:latest"


# ---- ECR repo and Docker image ----
aws ecr create-repository --repository-name nasa-epic-lambda --region "$REGION"
aws ecr get-login-password --region "$REGION" | \
  docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

# --provenance=false or Lambda won't accept the image
docker buildx build --platform linux/amd64 --provenance=false \
  -f Dockerfile.lambda -t "$IMAGE" --push .


# ---- IAM role for Lambda ----
aws iam create-role \
  --role-name nasa-epic-lambda-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
aws iam attach-role-policy --role-name nasa-epic-lambda-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
aws iam attach-role-policy --role-name nasa-epic-lambda-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

sleep 10   # role needs a few seconds before Lambda can use it


# ---- Lambda function ----
aws lambda create-function \
  --function-name nasa-epic-lambda \
  --package-type Image \
  --code ImageUri="$IMAGE" \
  --role "arn:aws:iam::$ACCOUNT_ID:role/nasa-epic-lambda-role" \
  --timeout 300 \
  --memory-size 512 \
  --region "$REGION"

sleep 15   # wait for the function to go from Pending to Active


# ---- S3 bucket ----
aws s3api create-bucket --bucket "$BUCKET" --region "$REGION"
aws lambda update-function-configuration \
  --function-name nasa-epic-lambda \
  --environment "Variables={S3_BUCKET=$BUCKET}" \
  --region "$REGION"


# ---- Test it ----
aws lambda invoke \
  --function-name nasa-epic-lambda \
  --payload file://test-event.json \
  --cli-binary-format raw-in-base64-out \
  --region "$REGION" \
  response.json
cat response.json


# ---- SNS topic + email ----
# AWS sends a confirmation email, click the link before moving on
TOPIC_ARN="arn:aws:sns:$REGION:$ACCOUNT_ID:nasa-epic-s3-events"
aws sns create-topic --name nasa-epic-s3-events --region "$REGION"
aws sns subscribe --topic-arn "$TOPIC_ARN" --protocol email \
  --notification-endpoint "$EMAIL" --region "$REGION"


# ---- Let S3 publish to SNS, then send upload events there ----
aws sns set-topic-attributes \
  --topic-arn "$TOPIC_ARN" \
  --attribute-name Policy \
  --attribute-value "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"s3.amazonaws.com\"},\"Action\":\"SNS:Publish\",\"Resource\":\"$TOPIC_ARN\",\"Condition\":{\"ArnLike\":{\"aws:SourceArn\":\"arn:aws:s3:::$BUCKET\"}}}]}" \
  --region "$REGION"
aws s3api put-bucket-notification-configuration \
  --bucket "$BUCKET" \
  --notification-configuration "{\"TopicConfigurations\":[{\"TopicArn\":\"$TOPIC_ARN\",\"Events\":[\"s3:ObjectCreated:Put\",\"s3:ObjectCreated:Post\"]}]}"


# ---- EventBridge schedule (every 5 min) ----
# the scheduler needs its own role to call Lambda
aws iam create-role \
  --role-name eventbridge-scheduler-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"scheduler.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
aws iam attach-role-policy --role-name eventbridge-scheduler-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaRole

sleep 15   # this failed for me until the role had time to show up

aws scheduler create-schedule \
  --name nasa-epic-every-5-min \
  --schedule-expression "rate(5 minutes)" \
  --target "{\"Arn\":\"arn:aws:lambda:$REGION:$ACCOUNT_ID:function:nasa-epic-lambda\",\"RoleArn\":\"arn:aws:iam::$ACCOUNT_ID:role/eventbridge-scheduler-role\",\"Input\":\"{\\\"days_back\\\":1,\\\"collection\\\":\\\"natural\\\",\\\"bucket\\\":\\\"$BUCKET\\\"}\"}" \
  --flexible-time-window '{"Mode":"OFF"}' \
  --region "$REGION"
