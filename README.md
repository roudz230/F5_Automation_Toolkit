# F5 Admin Toolkit

Automation scripts for F5 BIG-IP/F5OS administration (API & SSH based).

This repository contains reusable Bash scripts designed to automate
common BIG-IP operational tasks such as:

- Cluster synchronization
- UCS backup (parallel execution)
- Pre/Post upgrade verification
- Configuration diff
- Virtual Server / Pool / Member status checks
- `load sys config verify` parsing and validation

---

## 🚀 Features

### 🔹 Cluster Synchronization (API)
- Detect active device
- List sync-failover device groups
- Interactive selection
- Trigger config-sync
- Polling until "In Sync"
- Multi-host summary

### 🔹 UCS Backup (Parallel Mode)
- Parallel execution with job control
- Configurable max concurrent jobs
- Per-host status tracking
- Global success / failure summary

### 🔹 Pre / Post Upgrade Check
Collect and compare:

- AFM policies
- ASM policies
- WideIPs (GTM)
- Virtual Servers (availability)
- Pools
- Pool Members
- Object counts summary

### 🔹 Targeted Diff
Compare BEFORE / AFTER summary sections only.

### 🔹 Load Config Verify Parser
- Logs full output
- Displays only Errors / Warnings
- Counts occurrences
- Returns status usable in automation pipelines

---

## 📂 Structure 

f5-admin-toolkit/  
├─ backups/  
├─ logs/  
├...├── before/  
├...└── after/  
├─ tmp/  
├─ run_menu.sh  
├─ sub_xxx.sh  
├─ fonctions.sh  
├─ config.sh  
└─ hosts.txt  
