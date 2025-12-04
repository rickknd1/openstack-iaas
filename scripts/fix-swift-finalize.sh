#!/bin/bash
# =============================================================================
# Script: fix-swift-finalize.sh
# Description: Finalise Swift avec la bonne IP storage (10.0.0.41)
# A executer sur: CONTROLLER
# =============================================================================

set -e

STORAGE_IP="10.0.0.41"

echo "=========================================="
echo "Fix Swift Finalize - Storage IP: $STORAGE_IP"
echo "=========================================="

# 1. Test connexion
echo "[1/4] Test connexion vers storage..."
ping -c1 $STORAGE_IP || { echo "ERREUR: Storage non joignable"; exit 1; }

# 2. Copier les rings vers le storage
echo "[2/4] Copie des rings vers storage..."
scp /etc/swift/*.ring.gz root@${STORAGE_IP}:/etc/swift/
scp /etc/swift/swift.conf root@${STORAGE_IP}:/etc/swift/

# 3. Configurer permissions sur storage
echo "[3/4] Configuration permissions sur storage..."
ssh root@${STORAGE_IP} "chown -R swift:swift /etc/swift"

# 4. Redemarrer services sur storage
echo "[4/4] Redemarrage services Swift sur storage..."
ssh root@${STORAGE_IP} "systemctl restart swift-account swift-account-auditor swift-account-reaper swift-account-replicator"
ssh root@${STORAGE_IP} "systemctl restart swift-container swift-container-auditor swift-container-replicator swift-container-updater"
ssh root@${STORAGE_IP} "systemctl restart swift-object swift-object-auditor swift-object-replicator swift-object-updater"

# 5. Redemarrer proxy sur controller
systemctl restart swift-proxy

# 6. Verification
echo ""
echo "Verification Swift:"
source /root/admin-openrc
swift stat

echo "=========================================="
echo "Swift configure avec succes!"
echo "=========================================="
