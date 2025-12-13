#!/bin/bash
echo "🧪 Testing Chapter 4 Resilience..."

# Test Case 1: Helm Infrastructure
if helm list | grep -q "infra-redis"; then
    echo "✅ PASS: Redis Infrastructure found (Helm)."
else
    echo "❌ FAIL: Redis release missing."
fi

# Test Case 2: Self-Healing (Simulating Crash)
echo "[2/2] Simulating Pod Crash (Deleting Booking Pod)..."
POD_NAME=$(kubectl get pod -n delta-ev-platform -l app=ev-booking-prod -o jsonpath="{.items[0].metadata.name}")
kubectl delete pod $POD_NAME -n delta-ev-platform

echo "Waiting for Recovery..."
sleep 5
NEW_POD_NAME=$(kubectl get pod -n delta-ev-platform -l app=ev-booking-prod -o jsonpath="{.items[0].metadata.name}")

if [ "$POD_NAME" != "$NEW_POD_NAME" ]; then
    echo "✅ PASS: Kubernetes replaced the crashed pod."
else
    echo "❌ FAIL: Pod identity did not change (Restart failed)."
fi
