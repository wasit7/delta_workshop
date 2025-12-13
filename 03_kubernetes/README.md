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
