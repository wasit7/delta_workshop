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
