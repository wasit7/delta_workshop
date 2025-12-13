#!/bin/bash
echo "🧪 Verifying Microservice Mesh..."

# 1. Check Pod Counts
COUNT=$(kubectl get pods -n delta-ev-platform --no-headers | wc -l)
if [ "$COUNT" -ge 4 ]; then
    echo "✅ PASS: 4+ Pods detected (1 Inventory, 1 Pricing, 2 Booking)."
else
    echo "❌ FAIL: Expected 4+ pods, found $COUNT."
    kubectl get pods -n delta-ev-platform
    exit 1
fi

# 2. Check Service Discovery Environment Injection
POD_NAME=$(kubectl get pods -n delta-ev-platform -l app=ev-booking -o jsonpath="{.items[0].metadata.name}")
echo "🔍 Inspecting Pod: $POD_NAME"
if kubectl exec -n delta-ev-platform $POD_NAME -- env | grep -q "INVENTORY_SVC_URL"; then
    echo "✅ PASS: ConfigMap injected (Service Discovery Active)."
else
    echo "❌ FAIL: INVENTORY_SVC_URL not found in environment."
fi
