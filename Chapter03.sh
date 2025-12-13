#!/bin/bash

# ==============================================================================
# DockerDelta - Chapter 3: Kubernetes Setup (Microservices Edition)
# Theme: The Distributed EV Platform (Booking, Inventory, Pricing)
# ==============================================================================

BASE_DIR="./03_kubernetes"
echo "📂 Creating Chapter 3 Project (Microservices) in: $BASE_DIR"

mkdir -p "$BASE_DIR/manifests/services"
mkdir -p "$BASE_DIR/scripts"

# ------------------------------------------------------------------------------
# 1. MANIFESTS: The Distributed System
# ------------------------------------------------------------------------------

# Namespace
cat > "$BASE_DIR/manifests/00_namespace.yaml" <<'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: delta-ev-platform
EOF

# Configuration (Service Discovery)
cat > "$BASE_DIR/manifests/01_configmap.yaml" <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: microservice-config
  namespace: delta-ev-platform
data:
  # Internal DNS names provided by K8s Services
  INVENTORY_SVC_URL: "http://ev-inventory"
  PRICING_SVC_URL: "http://ev-pricing"
  ENV_TYPE: "staging"
EOF

# Secret (DB Credentials)
cat > "$BASE_DIR/manifests/02_secret.yaml" <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: delta-ev-platform
type: Opaque
stringData:
  API_KEY: "delta-super-secret-key-2025"
EOF

# --- MICROSERVICE A: INVENTORY (ClusterIP - Internal Only) ---
cat > "$BASE_DIR/manifests/services/inventory.yaml" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inventory-deploy
  namespace: delta-ev-platform
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ev-inventory
  template:
    metadata:
      labels:
        app: ev-inventory
    spec:
      containers:
      - name: api
        image: python:3.9-slim
        # Simulating a FastAPI App
        command: ["/bin/sh", "-c"]
        args:
          - |
            echo "Starting Inventory Service..."
            # Create a fake server responding on port 8000
            while true; do echo -e "HTTP/1.1 200 OK\n\n{\"cars\": [\"Tesla\", \"BYD\"]}" | nc -l -p 8000; done
        ports:
        - containerPort: 8000
---
apiVersion: v1
kind: Service
metadata:
  name: ev-inventory
  namespace: delta-ev-platform
spec:
  type: ClusterIP  # Internal only
  selector:
    app: ev-inventory
  ports:
    - port: 80
      targetPort: 8000
EOF

# --- MICROSERVICE B: PRICING (ClusterIP - Internal Only) ---
cat > "$BASE_DIR/manifests/services/pricing.yaml" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pricing-deploy
  namespace: delta-ev-platform
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ev-pricing
  template:
    metadata:
      labels:
        app: ev-pricing
    spec:
      containers:
      - name: api
        image: python:3.9-slim
        command: ["/bin/sh", "-c"]
        args:
          - |
            echo "Starting Pricing Engine..."
            while true; do echo -e "HTTP/1.1 200 OK\n\n{\"base_price\": 100}" | nc -l -p 8000; done
        ports:
        - containerPort: 8000
---
apiVersion: v1
kind: Service
metadata:
  name: ev-pricing
  namespace: delta-ev-platform
spec:
  type: ClusterIP
  selector:
    app: ev-pricing
  ports:
    - port: 80
      targetPort: 8000
EOF

# --- MICROSERVICE C: BOOKING (NodePort - Public Entry) ---
cat > "$BASE_DIR/manifests/services/booking.yaml" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: booking-deploy
  namespace: delta-ev-platform
spec:
  replicas: 2 # Scaled for availability
  selector:
    matchLabels:
      app: ev-booking
  template:
    metadata:
      labels:
        app: ev-booking
    spec:
      containers:
      - name: api
        image: python:3.9-slim
        # This service effectively proxies to the others (simulated logic)
        command: ["/bin/sh", "-c"]
        args:
          - |
            echo "Starting Booking Aggregator..."
            # In a real app, this would use the env vars to call Inventory
            while true; do echo -e "HTTP/1.1 200 OK\n\n{\"status\": \"Booking Confirmed\", \"inventory_source\": \"$INVENTORY_SVC_URL\"}" | nc -l -p 8000; done
        ports:
        - containerPort: 8000
        envFrom:
        - configMapRef:
            name: microservice-config
        - secretRef:
            name: app-secrets
---
apiVersion: v1
kind: Service
metadata:
  name: ev-booking
  namespace: delta-ev-platform
spec:
  type: NodePort # External Access
  selector:
    app: ev-booking
  ports:
    - port: 80
      targetPort: 8000
      nodePort: 30007
EOF

# ------------------------------------------------------------------------------
# 2. SCRIPTS
# ------------------------------------------------------------------------------

cat > "$BASE_DIR/scripts/bootstrap_cluster.sh" <<'EOF'
#!/bin/bash
echo "🚀 Initializing Minikube (Microservices Profile)..."
if ! command -v minikube &> /dev/null; then
    echo "❌ Minikube not found."
    exit 1
fi
# Microservices need more RAM
minikube start --driver=docker --cpus 2 --memory 4096 --disk-size 20g
kubectl config use-context minikube
echo "✅ Cluster Ready!"
EOF
chmod +x "$BASE_DIR/scripts/bootstrap_cluster.sh"

cat > "$BASE_DIR/scripts/verify_deployment.sh" <<'EOF'
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
EOF
chmod +x "$BASE_DIR/scripts/verify_deployment.sh"

# Generate Tutorial
cat > "$BASE_DIR/README.md" <<'EOF'
# 🕸️ Chapter 3: Kubernetes Microservices

**Goal:** Deploy the **Distributed EV Platform**. Separate services for Inventory, Pricing, and Booking.

## 🚀 Skill 3.1: Bootstrap
1. Start Minikube: `./scripts/bootstrap_cluster.sh`

## 🏗️ Skill 3.2 & 3.3: Deploy the Mesh
1. Create Namespace & Config:
   ```bash
   kubectl apply -f manifests/00_namespace.yaml
   kubectl apply -f manifests/01_configmap.yaml
   kubectl apply -f manifests/02_secret.yaml
   ```
2. Deploy Microservices:
   ```bash
   kubectl apply -f manifests/services/
   ```
3. Watch them start:
   ```bash
   kubectl get pods -n delta-ev-platform -w
   ```

## 🧪 Verification
1. Run the test suite: `./scripts/verify_deployment.sh`
2. Manually test Booking (if using Minikube):
   ```bash
   # In a new terminal
   minikube service ev-booking -n delta-ev-platform
   ```
EOF

echo "✅ Chapter 3 Setup Complete."