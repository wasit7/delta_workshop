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
