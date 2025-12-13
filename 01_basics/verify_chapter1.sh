#!/bin/bash
echo "🧪 Testing Chapter 1 Skills..."
if docker ps --format '{{.Names}}' | grep -q "delta-proxy"; then
    echo "✅ PASS: Nginx is running."
else
    echo "❌ FAIL: Nginx not found."
fi

if docker volume ls | grep -q "pg-data"; then
    echo "✅ PASS: Postgres volume exists."
else
    echo "❌ FAIL: Postgres volume missing."
fi
