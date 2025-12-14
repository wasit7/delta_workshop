#!/bin/bash

# ==========================================
# ☁️ Workshop Environment Generator (v2.0)
# ==========================================

# Default Configuration
DEFAULT_ZONE="asia-southeast1-a"
KEY_NAME="workshop_key"

echo "📂 Initializing Workshop Environment..."

# --- 1. PRE-FLIGHT CHECKS ---
if ! command -v gcloud &> /dev/null; then
    echo "❌ Error: Google Cloud SDK (gcloud) is not installed."
    exit 1
fi

echo "🔍 Checking Google Cloud Configuration..."

# Detect Project ID
DETECTED_PROJECT=$(gcloud config get-value project 2>/dev/null)

if [ -z "$DETECTED_PROJECT" ] || [ "$DETECTED_PROJECT" == "(unset)" ]; then
    echo "⚠️  No active project detected."
    read -p "👉 Please enter your Google Cloud Project ID: " USER_PROJECT
    PROJECT_ID=$USER_PROJECT
else
    echo "✅ Detected active project: $DETECTED_PROJECT"
    read -p "   Press ENTER to use this project, or type a new ID: " USER_INPUT
    if [ -z "$USER_INPUT" ]; then
        PROJECT_ID=$DETECTED_PROJECT
    else
        PROJECT_ID=$USER_INPUT
    fi
fi

# Confirm Zone
read -p "👉 Enter Zone (Press ENTER for '$DEFAULT_ZONE'): " USER_ZONE
ZONE=${USER_ZONE:-$DEFAULT_ZONE}

echo "----------------------------------------"
echo "⚙️  Configuration Set:"
echo "   Project: $PROJECT_ID"
echo "   Zone:    $ZONE"
echo "----------------------------------------"

# ==========================================
# GENERATE: 0_create_key.sh
# ==========================================
cat << EOF > 0_create_key.sh
#!/bin/bash
KEY_PATH="\$HOME/.ssh/$KEY_NAME"
USER_NAME="student"

echo "🔑 Step 0: Setting up SSH Keys..."
mkdir -p "\$HOME/.ssh"

if [ ! -f "\$KEY_PATH" ]; then
    ssh-keygen -t rsa -f \$KEY_PATH -C \$USER_NAME -N ""
    echo "✅ Key generated at: \$KEY_PATH"
else
    echo "✅ Key already exists."
fi

# Create the format Google needs (username:key)
echo "\$USER_NAME:\$(cat \${KEY_PATH}.pub)" > \${KEY_PATH}_formatted.pub
echo "📄 Formatted key created at: \${KEY_PATH}_formatted.pub"
EOF

# ==========================================
# GENERATE: 1_create_vms.sh
# ==========================================
# We inject the variables we captured earlier
echo "#!/bin/bash" > 1_create_vms.sh
echo "PROJECT_ID=\"$PROJECT_ID\"" >> 1_create_vms.sh
echo "ZONE=\"$ZONE\"" >> 1_create_vms.sh
echo "KEY_FILE=\"\$HOME/.ssh/${KEY_NAME}_formatted.pub\"" >> 1_create_vms.sh

cat << 'EOF' >> 1_create_vms.sh

# --- LOGIN CHECK ---
echo "🔍 Checking authentication..."
if ! gcloud auth print-access-token >/dev/null 2>&1; then
    echo "❌ Error: You are not logged in."
    echo "👉 Run: gcloud auth login"
    exit 1
fi

# --- PROJECT CHECK ---
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
if [ "$CURRENT_PROJECT" != "$PROJECT_ID" ]; then
    echo "⚠️  Switching active project to: $PROJECT_ID"
    gcloud config set project $PROJECT_ID
fi

# --- KEY CHECK ---
if [ ! -f "$KEY_FILE" ]; then
    echo "❌ Error: Key file missing. Run './0_create_key.sh' first."
    exit 1
fi

# --- CREATE VMS ---
read -p "Enter number of VMs to create: " NUM_VMS
echo "🚀 Creating $NUM_VMS Spot VMs in $ZONE..."

if gcloud compute instances create $(seq -f "vm-%g" 1 $NUM_VMS) \
    --zone=$ZONE \
    --machine-type=e2-standard-2 \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --provisioning-model=SPOT \
    --instance-termination-action=STOP \
    --metadata-from-file ssh-keys=$KEY_FILE \
    --tags=http-server,https-server; then
    
    echo ""
    echo "✅ Success! $NUM_VMS VMs are running."
else
    echo ""
    echo "❌ Creation Failed. (If they already exist, run Step 3 to clean up)."
    exit 1
fi
EOF

# ==========================================
# GENERATE: 2_get_info.sh
# ==========================================
echo "#!/bin/bash" > 2_get_info.sh
echo "PROJECT_ID=\"$PROJECT_ID\"" >> 2_get_info.sh
echo "KEY_NAME=\"$KEY_NAME\"" >> 2_get_info.sh

cat << 'EOF' >> 2_get_info.sh

echo "===================================================="
echo "📋 VS CODE CONFIGURATION INFO"
echo "===================================================="
echo "Copy the block below into your SSH Config file:"
echo "   Windows: C:\\Users\\NAME\\.ssh\\config"
echo "   Mac/Linux: ~/.ssh/config"
echo "===================================================="
echo ""

gcloud compute instances list \
    --project=$PROJECT_ID \
    --filter="status=RUNNING" \
    --format="csv[no-heading](name,networkInterfaces[0].accessConfigs[0].natIP)" \
    | while IFS=, read -r name ip; do
        if [ -n "$ip" ]; then
            echo "Host $name"
            echo "    HostName $ip"
            echo "    User student"
            echo "    IdentityFile ~/.ssh/$KEY_NAME" 
            echo "    StrictHostKeyChecking no"
            echo "    UserKnownHostsFile /dev/null"
            echo ""
        fi
    done

echo "===================================================="
echo "⚠️  WINDOWS USERS:"
echo "1. Copy the '$KEY_NAME' file from here to C:\\Users\\YourName\\.ssh\\"
echo "2. Change 'IdentityFile' above to: IdentityFile C:\\Users\\YourName\\.ssh\\$KEY_NAME"
echo "===================================================="
EOF

# ==========================================
# GENERATE: 3_terminate_vms.sh
# ==========================================
echo "#!/bin/bash" > 3_terminate_vms.sh
echo "PROJECT_ID=\"$PROJECT_ID\"" >> 3_terminate_vms.sh
echo "ZONE=\"$ZONE\"" >> 3_terminate_vms.sh

cat << 'EOF' >> 3_terminate_vms.sh

echo "⚠️  WARNING: Deleting ALL 'vm-*' instances in $ZONE ($PROJECT_ID)."
read -p "Are you sure? (y/n): " CONFIRM

if [[ "$CONFIRM" == "y" ]]; then
    echo "🔥 Deleting VMs..."
    VM_LIST=$(gcloud compute instances list --project=$PROJECT_ID --filter="name:vm-*" --format="value(name)")
    
    if [ -z "$VM_LIST" ]; then
        echo "Example: No VMs found to delete."
    else
        echo "$VM_LIST" | xargs -r gcloud compute instances delete --project=$PROJECT_ID --zone=$ZONE --quiet
        echo "✅ All VMs deleted."
    fi
else
    echo "❌ Cancelled."
fi
EOF

# ==========================================
# GENERATE: 4_fix_vscode.sh (NEW)
# ==========================================
echo "#!/bin/bash" > 4_fix_vscode.sh
echo "PROJECT_ID=\"$PROJECT_ID\"" >> 4_fix_vscode.sh
echo "ZONE=\"$ZONE\"" >> 4_fix_vscode.sh

cat << 'EOF' >> 4_fix_vscode.sh

echo "🚑 VS CODE FIX TOOL"
echo "This will delete the .vscode-server folder on the remote VM."
echo "Use this if you get 'Failed to set up dynamic port forwarding'."
echo ""
read -p "Enter the VM number to fix (e.g., enter 1 for vm-1): " VM_NUM

VM_NAME="vm-$VM_NUM"

echo "Attempting to fix $VM_NAME..."
gcloud compute ssh $VM_NAME --project=$PROJECT_ID --zone=$ZONE --command="rm -rf ~/.vscode-server"

if [ $? -eq 0 ]; then
    echo "✅ Cleaned up $VM_NAME."
    echo "👉 Now: In VS Code, press F1 -> 'Developer: Reload Window' and try again."
else
    echo "❌ Failed to connect. Is the VM running?"
fi
EOF

# ==========================================
# GENERATE: README.md
# ==========================================
cat << EOF > README.md
# ☁️ Workshop Manager (Project: $PROJECT_ID)

**Region:** \`$ZONE\`
**User:** \`student\`

## 🚀 Workflow

### 1. Setup
\`\`\`bash
./0_create_key.sh   # Run once to generate keys
./1_create_vms.sh   # Create your VMs
\`\`\`

### 2. Connect
\`\`\`bash
./2_get_info.sh     # Get the text to paste into VS Code Config
\`\`\`

### 3. Troubleshooting
**Error: "Failed to set up dynamic port forwarding"**
If VS Code fails to connect, run the fix script:
\`\`\`bash
./4_fix_vscode.sh
\`\`\`
Then reload your VS Code window.

### 4. Cleanup
\`\`\`bash
./3_terminate_vms.sh # Stop billing!
\`\`\`
EOF

# ==========================================
# FINALIZE
# ==========================================
chmod +x 0_create_key.sh 1_create_vms.sh 2_get_info.sh 3_terminate_vms.sh 4_fix_vscode.sh

echo "✅ Initialization complete for project: $PROJECT_ID"
echo "👉 Run './0_create_key.sh' to begin."
