#!/bin/bash

# ==============================================================================
# DockerDelta - Chapter 4: Production Setup (Microservices Edition)
# Theme: Capstone Project (The Resilient Platform)
# ==============================================================================

BASE_DIR="./04_production"
echo "📂 Creating Chapter 4 Project (Production Capstone) in: $BASE_DIR"

mkdir -p "$BASE_DIR/helm_configs"
mkdir -p "$BASE_DIR/capstone_platform"

# 1. Helm Overrides (Production Settings)
cat > "$BASE_DIR/helm_configs/redis-values.yaml" <<'EOF'
architecture: standalone
auth:
  enabled: true
  password: delta-secure-redis
master:
  persistence:
    enabled: true
    size: 1Gi
EOF

# 2. Capstone Manifests (Production Grade)
# We add Liveness Probes and Resource Limits to the Chapter 3 manifests

cat > "$BASE_DIR/capstone_platform/production-booking.yaml" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: booking-prod
  namespace: delta-ev-platform
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ev-booking-prod
  template:
    metadata:
      labels:
        app: ev-booking-prod
    spec:
      containers:
      - name: api
        image: python:3.9-slim
        command: ["/bin/sh", "-c"]
        args:
          - |
            echo "Starting Production Booking API..."
            # Simulate app with a /health endpoint
            while true; do echo -e "HTTP/1.1 200 OK\n\nOK" | nc -l -p 8000; done
        ports:
        - containerPort: 8000
        # --- PRODUCTION UPGRADE: RESOURCE LIMITS ---
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
        # --- PRODUCTION UPGRADE: SELF-HEALING ---
        livenessProbe:
          exec:
            command:
            - cat
            - /tmp/healthy # File doesn't exist? Crash! (For simulation)
          # In real life, use httpGet
          # httpGet:
          #   path: /health
          #   port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
EOF

# 3. Validation Script
cat > "$BASE_DIR/capstone_platform/verify_resilience.sh" <<'EOF'
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
EOF
chmod +x "$BASE_DIR/capstone_platform/verify_resilience.sh"

# Generate Tutorial
cat > "$BASE_DIR/README.md" <<'EOF'
# 🛡️ Chapter 4: Production Readiness

**Goal:** Harden the Microservices with Health Checks and deploy infrastructure via Helm.

## 📦 Skill 4.1: Helm Infrastructure
**Task:** Install Redis for caching.
1. Add Repo:
   ```bash
   helm repo add bitnami [https://charts.bitnami.com/bitnami](https://charts.bitnami.com/bitnami)
   ```
2. Install Redis:
   ```bash
   helm install infra-redis bitnami/redis -f helm_configs/redis-values.yaml
   ```

## 🏥 Skill 4.2: Health Checks
**Task:** Deploy the hardened Booking Service.
1. Apply Manifest:
   ```bash
   kubectl apply -f capstone_platform/production-booking.yaml
   ```
2. Verify Probes:
   ```bash
   kubectl describe pod -l app=ev-booking-prod
   ```
   *(Look for "Liveness: ...")*

## 💥 Skill 4.3: Resilience Test
**Task:** Validate Self-Healing.
1. Run the test script:
   ```bash
   ./capstone_platform/verify_resilience.sh
   ```
EOF

echo "✅ Chapter 4 Setup Complete."