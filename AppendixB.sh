#!/bin/bash

# ==============================================================================
# DockerDelta - Appendix B: Linux Labs Setup
# Description: Generates files for filesystem and permission exercises.
# ==============================================================================

PROJECT_DIR="./00_appendix_b_linux_labs"

echo "📂 Creating Lab Environment in: $PROJECT_DIR"
mkdir -p "$PROJECT_DIR/delta-project/src"

# Lab 1: Hidden Files
echo "DB_HOST=localhost" > "$PROJECT_DIR/delta-project/.env"
echo "Project Configured." > "$PROJECT_DIR/delta-project/README.txt"

# Lab 2: Permissions Script
# Intentionally created without +x permissions for the student to fix
cat > "$PROJECT_DIR/start.sh" <<EOF
#!/bin/bash
echo '🚀 Service Started Successfully!'
echo '✅ You have fixed the permissions correctly.'
EOF

# Generate Tutorial
cat > "$PROJECT_DIR/README.md" <<'EOF'
# 🐧 Appendix B: Essential Linux Skills

**Context:** Proficiency with the CLI is vital for debugging containers. These exercises simulate common scenarios.

## 🧪 Exercise 1: Filesystem Navigation
*Objective:* Verify project configuration files.

1. Navigate to the project folder:
   ```bash
   cd delta-project
   ```
2. List files to find the configuration:
   ```bash
   ls -lah
   ```
   *(Look for `.env` - the dot prefix makes it hidden)*

## 🧪 Exercise 2: Permissions & Ownership
*Objective:* Fix a "Permission Denied" error for an entrypoint script.

1. Go back to the root of Appendix B:
   ```bash
   cd ..
   ```
2. Try to run the startup script:
   ```bash
   ./start.sh
   ```
   *(Expected Result: Permission denied)*
3. Inspect permissions:
   ```bash
   ls -l start.sh
   ```
4. **Fix it:** Make the script executable:
   ```bash
   chmod +x start.sh
   ```
5. Verify success:
   ```bash
   ./start.sh
   ```

## 🧪 Exercise 3: Connectivity
*Objective:* Check if you can reach external services.

1. Check Google DNS:
   ```bash
   ping -c 4 8.8.8.8
   ```
EOF

echo "✅ Appendix B setup complete."
echo "👉 Run: cd $PROJECT_DIR"