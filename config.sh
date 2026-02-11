BACKUP_DIR="backups"
LOGS_DIR="logs"

BASE_ISO="/apps/data/os_repository/F5/TMOS_17.1.3/BIGIP-17.1.3-0.0.11.iso"
HF_ISO="/apps/data/os_repository/F5/TMOS_17.1.3/Hotfix-BIGIP-17.1.3.0.176.11-ENG.iso"
HF_DMZR_ISO="/apps/data/os_repository/F5/TMOS_17.1.3/Hotfix-BIGIP-17.1.3.0.248.11-ENG.iso"
ISO_F505="/apps/data/os_repository/F5/F5OS/F505-A-1.8.3-23493.R5R10.EHF-1.iso"
TARGET_RPM="/apps/data/os_repository/F5/AS3/f5-appsvcs-3.54.6-9.noarch.rpm"
#TARGET_RPM="/apps/data/os_repository/F5/AS3/f5-declarative-onboarding-1.30.0-3.noarch.rpm"

AS3_VERSION="3.54.0"

TIMESTAMP=$(date +"%Y%m%d_%Hh%M")

h=0
o=0
k=0
HOSTS="$1"

SSH_TIMEOUT=10
SSH_TIMEOUT_MEDIUM=30
SSH_TIMEOUT_LONG=300
