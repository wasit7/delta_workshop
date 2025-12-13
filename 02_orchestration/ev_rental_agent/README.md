# 🥘 Chapter 2: Orchestration Basics

**Goal:** Deploy the **EV Rental Agent**, a "Modular Monolith" consisting of a Django Web App and a PostgreSQL Database.

## 🚀 Skill 2.1: Stack Deployment
**Task:** Use Docker Compose to act as the "Recipe Card."

1. **Configure Secrets:**
   Open `.env` and add your `GEMINI_API_KEY`.
2. **Build and Run:**
   ```bash
   docker-compose up --build -d
   ```
3. **Verify:**
   - Web: `http://localhost:8000`
   - Logs: `docker-compose logs -f web`

## 🦭 Skill 2.2: Platform Migration (Podman)
**Task:** Switch from the Docker Daemon to Daemonless Podman.

1. Stop Docker:
   ```bash
   docker-compose down
   ```
2. Enable Alias (if installed):
   ```bash
   alias docker=podman
   ```
3. Run again:
   ```bash
   docker-compose up -d
   ```

## 🔒 Skill 2.3: Rootless Security
**Task:** Verify the app is running as a non-privileged user.

1. Inspect the running container:
   ```bash
   docker exec ev_agent_web id
   ```
   *Expected Output:* `uid=1000(appuser) gid=1000(appuser)` (Not root!)
