#!/bin/bash
# Build and push Docker image to ECR
# Usage: ./build-and-push.sh [version]

set -e

VERSION=${1:-"latest"}
ECR_REPO="978848629209.dkr.ecr.us-east-1.amazonaws.com/do-sample-app"
REGION="us-east-1"

echo "🔨 Building Docker image..."
docker build -t do-sample-app:${VERSION} .

echo "🏷️  Tagging image for ECR..."
docker tag do-sample-app:${VERSION} ${ECR_REPO}:${VERSION}

if [ "$VERSION" != "latest" ]; then
    docker tag do-sample-app:${VERSION} ${ECR_REPO}:latest
fi

echo "🔐 Authenticating with ECR..."
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REPO}

echo "📤 Pushing image to ECR..."
docker push ${ECR_REPO}:${VERSION}

if [ "$VERSION" != "latest" ]; then
    docker push ${ECR_REPO}:latest
fi

echo "✅ Image pushed successfully: ${ECR_REPO}:${VERSION}"
echo ""
echo "To deploy to Kubernetes, run:"
echo "  kubectl set image deployment/do-sample-app do-sample-app=${ECR_REPO}:${VERSION}"
echo "  kubectl rollout status deployment/do-sample-app"
