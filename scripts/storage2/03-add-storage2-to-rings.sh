#!/bin/bash
# =============================================================================
# Script: 03-add-storage2-to-rings.sh
# Description: Ajoute Storage2 aux rings Swift et distribue les fichiers
# A executer sur: CONTROLLER (192.168.100.136) - AMENI
# =============================================================================

set -e

echo "=========================================="
echo "Ajout de Storage2 aux rings Swift"
echo "=========================================="

# Variables
STORAGE2_IP="192.168.100.150"

# =============================================================================
# 1. AJOUT DE STORAGE2 AUX RINGS
# =============================================================================
echo "[1/3] Ajout de Storage2 aux rings..."

cd /etc/swift

# Ajouter storage2 aux rings (zone 2 pour differencier de storage1)
swift-ring-builder account.builder add --region 1 --zone 2 --ip ${STORAGE2_IP} --port 6202 --device sdc --weight 100
swift-ring-builder container.builder add --region 1 --zone 2 --ip ${STORAGE2_IP} --port 6201 --device sdc --weight 100
swift-ring-builder object.builder add --region 1 --zone 2 --ip ${STORAGE2_IP} --port 6200 --device sdc --weight 100

echo "Storage2 ajoute aux rings."

# =============================================================================
# 2. REBALANCER LES RINGS
# =============================================================================
echo "[2/3] Rebalancement des rings..."

swift-ring-builder account.builder rebalance
swift-ring-builder container.builder rebalance
swift-ring-builder object.builder rebalance

echo "Rings rebalances."

# =============================================================================
# 3. DISTRIBUTION DES FICHIERS VERS STORAGE2
# =============================================================================
echo "[3/3] Distribution des fichiers vers Storage2..."

# Copier les rings et swift.conf vers storage2
scp /etc/swift/account.ring.gz /etc/swift/container.ring.gz \
    /etc/swift/object.ring.gz /etc/swift/swift.conf \
    root@${STORAGE2_IP}:/etc/swift/

# Ajuster les permissions sur storage2
ssh root@${STORAGE2_IP} "chown -R swift:swift /etc/swift"

echo "=========================================="
echo "Storage2 ajoute avec succes!"
echo ""
echo "Dis maintenant a ton camarade (Storage2)"
echo "d'executer: 04-start-swift-services.sh"
echo "=========================================="
