#!/bin/bash

# Deploy Fixed Application Script
# This script builds and deploys the fixed version of the application

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Deploy Fixed Application - No More Crashes!  ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════╝${NC}"
echo ""

# Check if Docker is running
if ! docker ps > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Docker is not running${NC}"
    exit 1
fi

# Check if kubectl is available
if ! kubectl cluster-info > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: kubectl is not configured or cluster is not accessible${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Docker and kubectl are ready"
echo ""

# Ask for Docker Hub username
echo -e "${YELLOW}Enter your Docker Hub username:${NC}"
read -p "> " DOCKER_USERNAME

if [ -z "$DOCKER_USERNAME" ]; then
    echo -e "${RED}❌ Username cannot be empty${NC}"
    exit 1
fi

IMAGE_NAME="do-sample-app-fixed"
FULL_IMAGE="${DOCKER_USERNAME}/${IMAGE_NAME}:latest"

echo ""
echo -e "${BLUE}═══ Step 1: Building Docker Image ═══${NC}"
echo -e "Building image with fixed PostgreSQL connection pool..."
echo ""

docker build -t ${IMAGE_NAME}:latest -f code/Dockerfile code/

echo ""
echo -e "${GREEN}✓ Image built successfully!${NC}"
echo ""

echo -e "${BLUE}═══ Step 2: Tagging Image ═══${NC}"
echo -e "Tagging as: ${FULL_IMAGE}"
echo ""

docker tag ${IMAGE_NAME}:latest ${FULL_IMAGE}

echo -e "${GREEN}✓ Image tagged!${NC}"
echo ""

echo -e "${BLUE}═══ Step 3: Pushing to Docker Hub ═══${NC}"
echo -e "${YELLOW}You may need to login to Docker Hub first${NC}"
echo -e "Run: ${BLUE}docker login${NC}"
echo ""
read -p "Press Enter to continue with push (or Ctrl+C to cancel)..."

docker push ${FULL_IMAGE}

echo ""
echo -e "${GREEN}✓ Image pushed to Docker Hub!${NC}"
echo ""

echo -e "${BLUE}═══ Step 4: Updating Kubernetes Deployment ═══${NC}"
echo -e "Updating deployment to use the fixed version..."
echo ""

# Update the image in the deployment
kubectl set image deployment/do-sample-app do-sample-app=${FULL_IMAGE}

echo ""
echo -e "${GREEN}✓ Deployment updated!${NC}"
echo ""

echo -e "${BLUE}═══ Step 5: Waiting for Rollout ═══${NC}"
echo -e "Waiting for pods to be ready..."
echo ""

kubectl rollout status deployment/do-sample-app --timeout=120s

echo ""
echo -e "${GREEN}✓ Rollout complete!${NC}"
echo ""

echo -e "${BLUE}═══ Step 6: Verification ═══${NC}"
echo ""

echo -e "${YELLOW}Current Pods:${NC}"
kubectl get pods -l app=do-sample-app
echo ""

echo -e "${YELLOW}HPA Status:${NC}"
kubectl get hpa do-sample-app-hpa
echo ""

echo -e "${YELLOW}Checking logs for successful database connection...${NC}"
sleep 3
POD_NAME=$(kubectl get pods -l app=do-sample-app -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD_NAME | grep -i "database\|connected\|ready" || echo "Check logs manually"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            🎉 DEPLOYMENT SUCCESSFUL! 🎉           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}What's New:${NC}"
echo -e "  ✅ Connection pool with 25 max connections per pod"
echo -e "  ✅ Graceful error handling (no more panics)"
echo -e "  ✅ Auto-recovery mechanisms"
echo -e "  ✅ Health checks for connections"
echo -e "  ✅ Ready for high-concurrency load testing"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "  1. Run load test: ${BLUE}ansible-playbook ansible/run-load-test.yml${NC}"
echo -e "  2. Monitor HPA: ${BLUE}kubectl get hpa -w${NC}"
echo -e "  3. Watch pods scale: ${BLUE}kubectl get pods -l app=do-sample-app -w${NC}"
echo -e "  4. Access app: ${BLUE}http://45.55.116.144${NC}"
echo ""
echo -e "${GREEN}The app should now handle load tests without crashing! 🚀${NC}"
echo ""
