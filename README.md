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
