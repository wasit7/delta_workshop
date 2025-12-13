#!/bin/bash
# Skill 1.2: Lifecycle Management
# Metaphor: Renting the Apartment
echo "🏢 Deploying Nginx Container..."
docker run -d --name delta-proxy -p 8080:80 nginx:alpine
echo "✅ Access at http://localhost:8080"
