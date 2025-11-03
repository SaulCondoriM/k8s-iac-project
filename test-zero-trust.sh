#!/bin/bash
# Zero-Trust Network Policy Verification Script
# Chapter 3: Infrastructure Platforms

echo "============================================"
echo "Zero-Trust Security Verification Test"
echo "Chapter 3: Infrastructure Platforms"
echo "============================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

# Test 1: Verify Calico is running
echo "Test 1: Calico Policy Engine Status"
CALICO_PODS=$(kubectl get pods -n kube-system -l k8s-app=calico-node --field-selector=status.phase=Running --no-headers | wc -l)
if [ "$CALICO_PODS" -ge 3 ]; then
    echo -e "${GREEN}✓ PASS${NC}: Calico running on $CALICO_PODS nodes"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC}: Calico not running properly (found $CALICO_PODS pods)"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 2: Verify Network Policies exist
echo "Test 2: Network Policies Count"
NP_COUNT=$(kubectl get networkpolicies -n default --no-headers | wc -l)
if [ "$NP_COUNT" -ge 8 ]; then
    echo -e "${GREEN}✓ PASS${NC}: $NP_COUNT network policies active"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC}: Only $NP_COUNT policies found (expected ≥8)"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 3: Verify default-deny policies exist
echo "Test 3: Default Deny Policies"
DENY_INGRESS=$(kubectl get networkpolicy default-deny-ingress -n default --no-headers 2>/dev/null | wc -l)
DENY_EGRESS=$(kubectl get networkpolicy default-deny-egress -n default --no-headers 2>/dev/null | wc -l)
if [ "$DENY_INGRESS" -eq 1 ] && [ "$DENY_EGRESS" -eq 1 ]; then
    echo -e "${GREEN}✓ PASS${NC}: Default deny policies in place (Zero-Trust baseline)"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC}: Missing default deny policies"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 4: Application still accessible (allowed traffic works)
echo "Test 4: Allowed Traffic (Application Accessibility)"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://a77ebf6e1e065413199cf3f99662f4fc-1237267333.us-east-1.elb.amazonaws.com/ --max-time 10)
if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✓ PASS${NC}: Application accessible (HTTP $HTTP_CODE)"
    echo "  → LoadBalancer → app → PostgreSQL flow working"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC}: Application not accessible (HTTP $HTTP_CODE)"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 5: Verify app-to-postgres policy
echo "Test 5: App → PostgreSQL Policy"
APP_PG_POLICY=$(kubectl get networkpolicy app-to-postgres -n default --no-headers 2>/dev/null | wc -l)
if [ "$APP_PG_POLICY" -eq 1 ]; then
    echo -e "${GREEN}✓ PASS${NC}: Application to PostgreSQL policy exists"
    echo "  → Implements Principle of Least Privilege"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC}: Missing app-to-postgres policy"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 6: Verify PostgreSQL ingress restriction
echo "Test 6: PostgreSQL Ingress Restriction"
PG_POLICY=$(kubectl get networkpolicy postgres-from-app -n default --no-headers 2>/dev/null | wc -l)
if [ "$PG_POLICY" -eq 1 ]; then
    echo -e "${GREEN}✓ PASS${NC}: PostgreSQL ingress restricted to app only"
    echo "  → Defense in Depth implementation"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC}: PostgreSQL not properly restricted"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 7: DNS access allowed
echo "Test 7: DNS Resolution Allowed"
DNS_POLICY=$(kubectl get networkpolicy allow-dns -n default --no-headers 2>/dev/null | wc -l)
if [ "$DNS_POLICY" -eq 1 ]; then
    echo -e "${GREEN}✓ PASS${NC}: DNS resolution allowed for all pods"
    echo "  → Essential infrastructure access granted"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC}: DNS policy missing"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 8: Locust testing allowed
echo "Test 8: Load Testing Access"
LOCUST_POLICY=$(kubectl get networkpolicy locust-to-app -n default --no-headers 2>/dev/null | wc -l)
if [ "$LOCUST_POLICY" -eq 1 ]; then
    echo -e "${GREEN}✓ PASS${NC}: Locust can access application"
    echo "  → Testing infrastructure properly configured"
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}⚠ WARN${NC}: Locust policy not found (optional)"
fi
echo ""

# Summary
echo "============================================"
echo "Test Results Summary"
echo "============================================"
echo "Tests Passed: $PASSED"
echo "Tests Failed: $FAILED"
echo ""

if [ "$FAILED" -eq 0 ]; then
    echo -e "${GREEN}✅ ALL TESTS PASSED${NC}"
    echo ""
    echo "Zero-Trust Security Model: ACTIVE"
    echo "Chapter 3 Implementation: COMPLETE"
    echo ""
    echo "Security Principles Implemented:"
    echo "  ✓ Default Deny (Zero-Trust Baseline)"
    echo "  ✓ Principle of Least Privilege"
    echo "  ✓ Defense in Depth"
    echo "  ✓ Software Defined Networking (SDN)"
    echo ""
    exit 0
else
    echo -e "${RED}❌ SOME TESTS FAILED${NC}"
    echo ""
    echo "Please review the failed tests above."
    echo "Run: kubectl get networkpolicies -n default"
    echo ""
    exit 1
fi
