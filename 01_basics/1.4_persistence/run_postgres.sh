#!/bin/bash
# Skill 1.4: Persistence Implementation
# Metaphor: The Storage Locker

echo "📦 Creating Volume (Locker Key)..."
docker volume create pg-data

echo "🐘 Starting Postgres..."
docker run -d \
  --name delta-db \
  -e POSTGRES_PASSWORD=secret \
  -v pg-data:/var/lib/postgresql/data \
  postgres:15-alpine
