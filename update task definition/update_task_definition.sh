#/bin/bash

ECR_ACCOUNT="999999999999.dkr.ecr.${REGION}.amazonaws.com"
REGION="us-east-1"

APP_NAME="$1"
APP_TAG="$2"
ECS_CLUSTER="$3"
SERVICE_NAME="$4"


TASK_NAME=$(aws ecs describe-services --cluster $ECS_CLUSTER --services $SERVICE_NAME --query 'services[].taskDefinition[]' --region us-east-1 --output text | cut -d "/" -f 2 | cut -d ":" -f 1)
ECR_IMAGE="${ECR_ACCOUNT}/${APP_NAME}:${APP_TAG}"
TASK_DEFINITION=$(aws ecs describe-task-definition --task-definition "$TASK_NAME" --region us-east-1)
NEW_TASK_DEFINITION=$(echo $TASK_DEFINITION | jq --arg IMAGE "$ECR_IMAGE" '.taskDefinition | .containerDefinitions[0].image = $IMAGE | del(.taskDefinitionArn) | del(.revision) | del(.status) | del(.requiresAttributes) | del(.compatibilities) | del(.registeredAt) | del(.registeredBy)')
NEW_TASK_INFO=$(aws ecs register-task-definition --region us-east-1 --cli-input-json "$NEW_TASK_DEFINITION")
NEW_REVISION=$(echo $NEW_TASK_INFO | jq '.taskDefinition.revision')
aws ecs update-service --cluster ${ECS_CLUSTER} --service ${SERVICE_NAME} --task-definition ${TASK_NAME}:${NEW_REVISION}