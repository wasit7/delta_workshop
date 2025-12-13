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
