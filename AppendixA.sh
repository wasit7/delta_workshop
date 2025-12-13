#!/bin/bash

# ==============================================================================
# DockerDelta - Appendix A: System Verification Suite
# Description: Automates the "CHECK" phase of the PDCA Preparation Guide.
# Usage: ./setupAppendixA.sh
# ==============================================================================

# Generate Documentation
cat > README_Prerequisites.md <<'EOF'
# 🛠️ Appendix A: System Verification Guide

**Context:** Before diving into containers, we must ensure the host environment (The Foundation) is solid. This suite validates your OS, Virtualization settings, and Docker Runtime.

## 📋 The Checklist (PDCA)

### 1. PLAN (Prerequisites)
- **BIOS/UEFI:** Virtualization Technology (VT-x/AMD-V) must be **Enabled**.
- **Admin Rights:** You need permission to install software.

### 2. DO (Installation)
- **Windows:** Install WSL 2 and Docker Desktop (WSL 2 Backend).
- **Mac:** Install Docker Desktop (Intel/Apple Silicon) or Podman.
- **Linux:** Install Docker CE and add user to `docker` group.

### 3. CHECK (Verification)
Run this script (`./setupAppendixA.sh`) to perform automated checks.

## 🔍 How to Interpret Results

| Symbol | Meaning | Action Required |
| :--- | :--- | :--- |
| ✅ | **PASS** | No action needed. You are ready. |
| ⚠️ | **WARNING** | Feature missing but optional (e.g., VS Code). |
| ❌ | **FAIL** | **STOP.** You cannot proceed until this is fixed. |

## 🚀 Next Steps
If all checks pass, proceed to **Appendix B** or **Chapter 1**.
EOF

echo "📝 Generated README_Prerequisites.md"
echo "🔍 Starting System Verification for DockerDelta Workshop..."
echo "========================================================"

# 1. OS Detection
OS="$(uname -s)"
KERNEL="$(uname -r)"
OS_TYPE="Unknown"

if [[ "$OS" == "Linux" ]]; then
    # WSL kernels usually contain "microsoft" or "WSL"
    if [[ "$KERNEL" == *"microsoft"* || "$KERNEL" == *"WSL"* ]]; then
        OS_TYPE="Windows (WSL)"
    else
        OS_TYPE="Linux (Native)"
    fi
elif [[ "$OS" == "Darwin" ]]; then
    OS_TYPE="Mac"
elif [[ "$OS" == CYGWIN* || "$OS" == MINGW* || "$OS" == MSYS* ]]; then
    OS_TYPE="Windows (Git Bash/Cygwin)"
fi

echo "🖥️  Detected OS: $OS_TYPE"

# 2. Virtualization/Environment Check
if [[ "$OS_TYPE" == "Linux (Native)" ]]; then
    echo -n "⚙️  Checking KVM/Virtualization... "
    if grep -Eoc '(vmx|svm)' /proc/cpuinfo > /dev/null; then
        echo "✅ ENABLED"
    else
        echo "⚠️  WARNING: No hardware virtualization detected (check BIOS)."
    fi
elif [[ "$OS_TYPE" == "Windows (WSL)" ]]; then
    echo -n "⚙️  Checking WSL Kernel... "
    # WSL 2 kernels typically have 'microsoft-standard'
    if [[ "$KERNEL" == *"microsoft-standard"* ]]; then
        echo "✅ WSL 2 Detected ($KERNEL)"
    else
        echo "⚠️  WARNING: Potential WSL 1 detected ($KERNEL). Docker requires WSL 2."
        echo "     👉 Tip: Run 'wsl --set-version <distro> 2' in PowerShell."
    fi
    
    echo -n "   - Checking Windows Interop... "
    if command -v cmd.exe &> /dev/null; then
        echo "✅ Working"
    else
        echo "⚠️  WARNING: Cannot run Windows commands. (Check /etc/wsl.conf for [interop] settings)"
    fi
fi

# 3. Docker Runtime Check
echo -n "🐳 Checking Docker Engine... "
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | tr -d ',')
    echo "✅ FOUND (v$DOCKER_VERSION)"
    
    echo -n "   - Verifying Docker Daemon connectivity... "
    if docker info &> /dev/null; then
        echo "✅ UP"
        if [[ "$OS_TYPE" == "Windows (WSL)" ]]; then
             CONTEXT=$(docker context show)
             echo "     ℹ️  Context: $CONTEXT"
        fi
    else
        echo "❌ DOWN"
        if [[ "$OS_TYPE" == "Windows (WSL)" ]]; then
            echo "     💡 Tip: Ensure Docker Desktop is running."
            echo "     💡 Tip: In Docker Desktop Settings > Resources > WSL Integration, ensure your distro is toggled ON."
        fi
    fi
else
    echo "❌ NOT INSTALLED"
fi

# 4. Podman Check (For Daemonless Labs)
echo -n "🦭 Checking Podman... "
if command -v podman &> /dev/null; then
    PODMAN_VERSION=$(podman --version | awk '{print $3}')
    echo "✅ FOUND (v$PODMAN_VERSION)"
else
    echo "⚠️  NOT FOUND (Required for Chapter 2)"
fi

# 5. VS Code Check
echo -n "📝 Checking VS Code... "
if command -v code &> /dev/null; then
    echo "✅ FOUND"
else
    echo "⚠️  NOT FOUND (Recommended IDE)"
fi

echo "========================================================"
echo "📋 Summary:"
echo "If you see any ❌ marks, please refer to '05_appendix_academic.md' Phase 2 (DO) instructions."
echo "If you see only ✅ or ⚠️, you are ready to proceed."