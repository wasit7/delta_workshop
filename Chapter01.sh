#!/bin/bash

# ==============================================================================
# DockerDelta - Chapter 1: Basics Setup
# Theme: The Containerization Paradigm
# ==============================================================================

BASE_DIR="./01_basics"
echo "📂 Creating Chapter 1 Project Structure in: $BASE_DIR"

mkdir -p "$BASE_DIR/1.2_lifecycle"
mkdir -p "$BASE_DIR/1.3_image_engineering"
mkdir -p "$BASE_DIR/1.4_persistence"

# 1.2 Lifecycle Script (Nginx)
cat > "$BASE_DIR/1.2_lifecycle/run_nginx.sh" <<'EOF'
#!/bin/bash
# Skill 1.2: Lifecycle Management
# Metaphor: Renting the Apartment
echo "🏢 Deploying Nginx Container..."
docker run -d --name delta-proxy -p 8080:80 nginx:alpine
echo "✅ Access at http://localhost:8080"
EOF
chmod +x "$BASE_DIR/1.2_lifecycle/run_nginx.sh"

# 1.3 Image Engineering (FastAPI)
cat > "$BASE_DIR/1.3_image_engineering/requirements.txt" <<EOF
fastapi
uvicorn
EOF

cat > "$BASE_DIR/1.3_image_engineering/main.py" <<'EOF'
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Hello from DockerDelta Container!"}
EOF

cat > "$BASE_DIR/1.3_image_engineering/Dockerfile" <<'EOF'
# --- Stage 1: The Workshop (Builder) ---
FROM python:3.9 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user -r requirements.txt

# --- Stage 2: The Apartment (Runtime) ---
FROM python:3.9-slim
WORKDIR /app
# Copy only the installed artifacts
COPY --from=builder /root/.local /root/.local
COPY . .
ENV PATH=/root/.local/bin:$PATH
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
EOF

# 1.4 Persistence Script (Postgres)
cat > "$BASE_DIR/1.4_persistence/run_postgres.sh" <<'EOF'
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
EOF
chmod +x "$BASE_DIR/1.4_persistence/run_postgres.sh"

# Verification Script
cat > "$BASE_DIR/verify_chapter1.sh" <<'EOF'
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
EOF
chmod +x "$BASE_DIR/verify_chapter1.sh"

# Generate Tutorial
cat > "$BASE_DIR/README.md" <<'EOF'
# 📘 Chapter 1: The Containerization Paradigm

**Goal:** Master the lifecycle of individual containers, optimize images, and manage persistent data.

## 🏢 Skill 1.2: Lifecycle (The Apartment)
**Task:** Run a lightweight Web Server.
1. Navigate to folder: `cd 1.2_lifecycle`
2. Execute the script: `./run_nginx.sh`
3. Verify: Open browser to `http://localhost:8080`.
4. Cleanup: `docker rm -f delta-proxy`

## 🏭 Skill 1.3: Image Engineering (The Workshop)
**Task:** Build an optimized FastAPI image using Multi-stage builds.
1. Navigate: `cd ../1.3_image_engineering`
2. Build the image:
   ```bash
   docker build -t delta-api:v1 .
   ```
3. Run it:
   ```bash
   docker run -d -p 8000:80 delta-api:v1
   ```
4. Test: `curl http://localhost:8000`

## 📦 Skill 1.4: Persistence (The Storage Locker)
**Task:** Run a Database that remembers data even if the container crashes.
1. Navigate: `cd ../1.4_persistence`
2. Run script: `./run_postgres.sh`
3. Verify Volume:
   ```bash
   docker volume ls | grep pg-data
   ```

## ✅ Final Verification
Run `./verify_chapter1.sh` to grade your work.
EOF

echo "✅ Chapter 1 Setup Complete."