#!/bin/bash

# -----------------------------------
# CONFIGURATION VARIABLES
# -----------------------------------
AWS_REGION="${AWS_REGION}"
AWS_ACCOUNT_ID="${AWS_REGION}"

# ECR
ECR_REPO_NAME="ducklakehouse"

# ECS
ECS_CLUSTER_NAME="dbt-cluster"
TASK_DEFINITION_NAME="dbt_jobs"
TASK_CPU="1024"
TASK_MEMORY="2048"
LOG_GROUP="/ecs/dbt_jobs"

# Secrets
SECRETS_NAME="duck_dbt"
# Replace with your actual credentials
AWS_REGION_SECRET="${AWS_REGION_SECRET}"
S3_ACCESS_KEY_ID="${S3_ACCESS_KEY_ID}"
S3_SECRET_ACCESS_KEY="${S3_SECRET_ACCESS_KEY}"
POSTGRES_HOST="${POSTGRES_HOST}"
POSTGRES_PORT="${POSTGRES_PORT}"
POSTGRES_USER="${POSTGRES_USER}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD}"
POSTGRES_DATABASE="${POSTGRES_DATABASE}"

# GitHub Actions IAM User
GITHUB_USER_NAME="duck"

# ECS Execution Role
ECS_EXECUTION_ROLE_NAME="ecsTaskExecutionRole"

# -----------------------------------
# 1️⃣ Create ECR repository
# -----------------------------------
aws ecr create-repository \
    --repository-name $ECR_REPO_NAME \
    --region $AWS_REGION || echo "ECR repo may already exist"

# -----------------------------------
# 2️⃣ Grant GitHub user permissions to push images
# -----------------------------------
aws iam put-user-policy \
    --user-name $GITHUB_USER_NAME \
    --policy-name ECRPushAccess \
    --policy-document "{
        \"Version\": \"2012-10-17\",
        \"Statement\": [
            {
                \"Effect\": \"Allow\",
                \"Action\": [
                    \"ecr:GetAuthorizationToken\",
                    \"ecr:BatchCheckLayerAvailability\",
                    \"ecr:PutImage\",
                    \"ecr:InitiateLayerUpload\",
                    \"ecr:UploadLayerPart\",
                    \"ecr:CompleteLayerUpload\"
                ],
                \"Resource\": \"arn:aws:ecr:$AWS_REGION:$AWS_ACCOUNT_ID:repository/$ECR_REPO_NAME\"
            }
        ]
    }"

# -----------------------------------
# 3️⃣ Create ECS cluster
# -----------------------------------
aws ecs create-cluster \
    --cluster-name $ECS_CLUSTER_NAME \
    --region $AWS_REGION || echo "ECS cluster may already exist"

# -----------------------------------
# 4️⃣ Create Secrets Manager secret
# -----------------------------------
aws secretsmanager create-secret \
    --name $SECRETS_NAME \
    --region $AWS_REGION \
    --secret-string "{
        \"AWS_REGION\":\"$AWS_REGION_SECRET\",
        \"S3_ACCESS_KEY_ID\":\"$S3_ACCESS_KEY_ID\",
        \"S3_SECRET_ACCESS_KEY\":\"$S3_SECRET_ACCESS_KEY\",
        \"POSTGRES_HOST\":\"$POSTGRES_HOST\",
        \"POSTGRES_PORT\":\"$POSTGRES_PORT\",
        \"POSTGRES_USER\":\"$POSTGRES_USER\",
        \"POSTGRES_PASSWORD\":\"$POSTGRES_PASSWORD\",
        \"POSTGRES_DATABASE\":\"$POSTGRES_DATABASE\"
    }" || echo "Secret may already exist"

# -----------------------------------
# 5️⃣ Attach permissions to ECS execution role
# -----------------------------------
# Attach managed policy for ECS execution
aws iam attach-role-policy \
    --role-name $ECS_EXECUTION_ROLE_NAME \
    --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

# Attach inline policy to allow ECS task to read secret
aws iam put-role-policy \
    --role-name $ECS_EXECUTION_ROLE_NAME \
    --policy-name AccessDBTSecret \
    --policy-document "{
        \"Version\": \"2012-10-17\",
        \"Statement\": [
            {
                \"Effect\": \"Allow\",
                \"Action\": [\"secretsmanager:GetSecretValue\"],
                \"Resource\": \"arn:aws:secretsmanager:$AWS_REGION:$AWS_ACCOUNT_ID:secret:$SECRETS_NAME-*\"
            }
        ]
    }"

# -----------------------------------
# 6️⃣ Create CloudWatch Log Group
# -----------------------------------
aws logs create-log-group \
    --log-group-name $LOG_GROUP \
    --region $AWS_REGION || echo "Log group may already exist"

# -----------------------------------
# 7️⃣ Register ECS Task Definition
# -----------------------------------
cat > ecs-task.json <<EOL
{
  "family": "$TASK_DEFINITION_NAME",
  "requiresCompatibilities": ["FARGATE"],
  "networkMode": "awsvpc",
  "cpu": "$TASK_CPU",
  "memory": "$TASK_MEMORY",
  "executionRoleArn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/$ECS_EXECUTION_ROLE_NAME",
  "containerDefinitions": [
    {
      "name": "$TASK_DEFINITION_NAME",
      "image": "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:latest",
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "$LOG_GROUP",
          "awslogs-region": "$AWS_REGION",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "secrets": [
        { "name": "AWS_REGION", "valueFrom": "arn:aws:secretsmanager:$AWS_REGION:$AWS_ACCOUNT_ID:secret:$SECRETS_NAME:AWS_REGION::" },
        { "name": "S3_ACCESS_KEY_ID", "valueFrom": "arn:aws:secretsmanager:$AWS_REGION:$AWS_ACCOUNT_ID:secret:$SECRETS_NAME:S3_ACCESS_KEY_ID::" },
        { "name": "S3_SECRET_ACCESS_KEY", "valueFrom": "arn:aws:secretsmanager:$AWS_REGION:$AWS_ACCOUNT_ID:secret:$SECRETS_NAME:S3_SECRET_ACCESS_KEY::" },
        { "name": "POSTGRES_HOST", "valueFrom": "arn:aws:secretsmanager:$AWS_REGION:$AWS_ACCOUNT_ID:secret:$SECRETS_NAME:POSTGRES_HOST::" },
        { "name": "POSTGRES_PORT", "valueFrom": "arn:aws:secretsmanager:$AWS_REGION:$AWS_ACCOUNT_ID:secret:$SECRETS_NAME:POSTGRES_PORT::" },
        { "name": "POSTGRES_USER", "valueFrom": "arn:aws:secretsmanager:$AWS_REGION:$AWS_ACCOUNT_ID:secret:$SECRETS_NAME:POSTGRES_USER::" },
        { "name": "POSTGRES_PASSWORD", "valueFrom": "arn:aws:secretsmanager:$AWS_REGION:$AWS_ACCOUNT_ID:secret:$SECRETS_NAME:POSTGRES_PASSWORD::" },
        { "name": "POSTGRES_DATABASE", "valueFrom": "arn:aws:secretsmanager:$AWS_REGION:$AWS_ACCOUNT_ID:secret:$SECRETS_NAME:POSTGRES_DATABASE::" }
      ]
    }
  ]
}
EOL

aws ecs register-task-definition \
    --cli-input-json file://ecs-task.json \
    --region $AWS_REGION

echo "✅ Full setup complete."
echo "ECR repo, ECS cluster, secrets, task definition, and IAM permissions created."
