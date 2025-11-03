#!/bin/bash
# Anti-Drift Detection Script
# Implements: "Minimize Variation" - Chapter 2, Infrastructure as Code
# Purpose: Detect and report configuration drift in EKS cluster

set -e

echo "=========================================="
echo "Anti-Drift Monitor - $(date)"
echo "Chapter 2: Principles of Cloud Age Infrastructure"
echo "=========================================="

# Configuration
NAMESPACE=${NAMESPACE:-"default"}
CLUSTER_NAME=${CLUSTER_NAME:-"k8s-autoscaling-cluster"}
REGION=${REGION:-"us-east-1"}
SLACK_WEBHOOK=${SLACK_WEBHOOK:-""}
DRIFT_THRESHOLD=5  # Number of drifted resources to trigger alert

# Counters
DRIFT_COUNT=0
TOTAL_CHECKS=0

# Function to send alert
send_alert() {
    local message=$1
    local severity=$2
    
    echo "⚠️  DRIFT DETECTED: $message"
    
    if [ -n "$SLACK_WEBHOOK" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"🚨 *Drift Alert* [$severity]\n$message\"}" \
            "$SLACK_WEBHOOK" 2>/dev/null || true
    fi
}

# Function to check resource
check_resource() {
    local resource_type=$1
    local expected_count=$2
    local label_selector=$3
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    actual_count=$(kubectl get $resource_type -l $label_selector -n $NAMESPACE --no-headers 2>/dev/null | wc -l)
    
    if [ "$actual_count" -ne "$expected_count" ]; then
        DRIFT_COUNT=$((DRIFT_COUNT + 1))
        send_alert "Resource drift: Expected $expected_count $resource_type, found $actual_count" "HIGH"
        return 1
    else
        echo "✓ $resource_type count matches: $actual_count"
        return 0
    fi
}

# Function to check HPA configuration
check_hpa() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    echo "Checking HPA configuration..."
    
    hpa_min=$(kubectl get hpa do-sample-app-hpa -n $NAMESPACE -o jsonpath='{.spec.minReplicas}' 2>/dev/null || echo "0")
    hpa_max=$(kubectl get hpa do-sample-app-hpa -n $NAMESPACE -o jsonpath='{.spec.maxReplicas}' 2>/dev/null || echo "0")
    
    if [ "$hpa_min" != "1" ] || [ "$hpa_max" != "10" ]; then
        DRIFT_COUNT=$((DRIFT_COUNT + 1))
        send_alert "HPA drift: min=$hpa_min (expected 1), max=$hpa_max (expected 10)" "MEDIUM"
        return 1
    else
        echo "✓ HPA configuration matches"
        return 0
    fi
}

# Function to check Cluster Autoscaler
check_cluster_autoscaler() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    echo "Checking Cluster Autoscaler..."
    
    ca_status=$(kubectl get deployment cluster-autoscaler -n kube-system -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo "0")
    
    if [ "$ca_status" != "1" ]; then
        DRIFT_COUNT=$((DRIFT_COUNT + 1))
        send_alert "Cluster Autoscaler drift: Not running (expected 1, found $ca_status)" "CRITICAL"
        return 1
    else
        echo "✓ Cluster Autoscaler is running"
        return 0
    fi
}

# Function to check node count
check_nodes() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    echo "Checking node configuration..."
    
    node_count=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    
    if [ "$node_count" -lt 2 ] || [ "$node_count" -gt 5 ]; then
        DRIFT_COUNT=$((DRIFT_COUNT + 1))
        send_alert "Node count drift: Found $node_count nodes (expected 2-5)" "HIGH"
        return 1
    else
        echo "✓ Node count within limits: $node_count"
        return 0
    fi
}

# Function to check application image
check_application_image() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    echo "Checking application image..."
    
    current_image=$(kubectl get deployment do-sample-app -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "")
    expected_image="978848629209.dkr.ecr.us-east-1.amazonaws.com/do-sample-app:v1.0.0"
    
    if [ "$current_image" != "$expected_image" ]; then
        DRIFT_COUNT=$((DRIFT_COUNT + 1))
        send_alert "Application image drift: Using '$current_image' (expected '$expected_image')" "HIGH"
        return 1
    else
        echo "✓ Application image matches"
        return 0
    fi
}

# Function to check metrics server
check_metrics_server() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    echo "Checking Metrics Server..."
    
    ms_status=$(kubectl get deployment metrics-server -n kube-system -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo "0")
    
    if [ "$ms_status" != "2" ]; then
        DRIFT_COUNT=$((DRIFT_COUNT + 1))
        send_alert "Metrics Server drift: Expected 2 replicas, found $ms_status" "MEDIUM"
        return 1
    else
        echo "✓ Metrics Server is running"
        return 0
    fi
}

# Function to validate AWS resources
check_aws_resources() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    echo "Checking AWS Auto Scaling Group..."
    
    asg_desired=$(aws autoscaling describe-auto-scaling-groups \
        --region $REGION \
        --query "AutoScalingGroups[?contains(Tags[?Key=='eks:nodegroup-name'].Value, 'worker-nodes')].DesiredCapacity" \
        --output text 2>/dev/null || echo "0")
    
    if [ -z "$asg_desired" ] || [ "$asg_desired" == "0" ]; then
        DRIFT_COUNT=$((DRIFT_COUNT + 1))
        send_alert "ASG drift: Cannot verify Auto Scaling Group configuration" "MEDIUM"
        return 1
    else
        echo "✓ Auto Scaling Group configured: Desired=$asg_desired"
        return 0
    fi
}

# Main execution
echo ""
echo "Starting drift detection checks..."
echo ""

# Configure kubectl
aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION 2>&1 | grep -v "Updated context" || true

# Run all checks
check_resource "deployment" 1 "app=do-sample-app"
check_resource "service" 3 "app=do-sample-app"  # service, metrics, loadbalancer
check_hpa
check_cluster_autoscaler
check_nodes
check_application_image
check_metrics_server
check_aws_resources

# Summary
echo ""
echo "=========================================="
echo "Drift Detection Summary"
echo "=========================================="
echo "Total checks: $TOTAL_CHECKS"
echo "Drifted resources: $DRIFT_COUNT"
echo "Compliance rate: $(( (TOTAL_CHECKS - DRIFT_COUNT) * 100 / TOTAL_CHECKS ))%"
echo ""

if [ $DRIFT_COUNT -eq 0 ]; then
    echo "✅ NO DRIFT DETECTED - Infrastructure matches code"
    exit 0
elif [ $DRIFT_COUNT -lt $DRIFT_THRESHOLD ]; then
    echo "⚠️  MINOR DRIFT DETECTED - $DRIFT_COUNT issue(s) found"
    exit 0
else
    echo "🚨 MAJOR DRIFT DETECTED - $DRIFT_COUNT issue(s) found"
    send_alert "Major drift detected: $DRIFT_COUNT/$TOTAL_CHECKS resources drifted" "CRITICAL"
    exit 1
fi
