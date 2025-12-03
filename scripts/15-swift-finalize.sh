#!/bin/bash
# =============================================================================
# Script: 15-swift-finalize.sh
# Description: Finalise la configuration Swift (rings et demarrage)
# A executer sur: controller UNIQUEMENT
# Prerequis: 13-swift-controller.sh et 14-swift-storage.sh executes
# =============================================================================

set -e

echo "=========================================="
echo "Finalisation de Swift"
echo "=========================================="

# Variables
STORAGE_IP="10.0.0.1"

# =============================================================================
# 1. AJOUT DU STORAGE NODE AUX RINGS
# =============================================================================
echo "[1/4] Configuration des rings Swift..."

cd /etc/swift

# Ajouter le storage node aux rings
swift-ring-builder account.builder add --region 1 --zone 1 --ip ${STORAGE_IP} --port 6202 --device sdc --weight 100
swift-ring-builder container.builder add --region 1 --zone 1 --ip ${STORAGE_IP} --port 6201 --device sdc --weight 100
swift-ring-builder object.builder add --region 1 --zone 1 --ip ${STORAGE_IP} --port 6200 --device sdc --weight 100

# Rebalancer les rings
swift-ring-builder account.builder rebalance
swift-ring-builder container.builder rebalance
swift-ring-builder object.builder rebalance

# =============================================================================
# 2. CREATION DU FICHIER SWIFT.CONF
# =============================================================================
echo "[2/4] Creation de swift.conf..."

cat > /etc/swift/swift.conf << EOF
[swift-hash]
swift_hash_path_suffix = $(openssl rand -hex 10)
swift_hash_path_prefix = $(openssl rand -hex 10)

[storage-policy:0]
name = Policy-0
default = yes
aliases = yellow, orange
EOF

# =============================================================================
# 3. COPIE DES FICHIERS VERS LE STORAGE NODE
# =============================================================================
echo "[3/4] Distribution des fichiers de configuration..."

# Copier les rings et swift.conf vers le storage node
scp /etc/swift/account.ring.gz /etc/swift/container.ring.gz \
    /etc/swift/object.ring.gz /etc/swift/swift.conf \
    root@${STORAGE_IP}:/etc/swift/

# Ajuster les permissions sur le storage
ssh root@${STORAGE_IP} "chown -R swift:swift /etc/swift"

# =============================================================================
# 4. DEMARRAGE DES SERVICES
# =============================================================================
echo "[4/4] Demarrage des services Swift..."

# Sur le controller
chown -R swift:swift /etc/swift
systemctl restart swift-proxy
systemctl enable swift-proxy

# Sur le storage node
ssh root@${STORAGE_IP} << 'REMOTE'
systemctl restart swift-account swift-account-auditor swift-account-reaper swift-account-replicator
systemctl restart swift-container swift-container-auditor swift-container-replicator swift-container-updater
systemctl restart swift-object swift-object-auditor swift-object-replicator swift-object-updater

systemctl enable swift-account swift-account-auditor swift-account-reaper swift-account-replicator
systemctl enable swift-container swift-container-auditor swift-container-replicator swift-container-updater
systemctl enable swift-object swift-object-auditor swift-object-replicator swift-object-updater
REMOTE

echo "=========================================="
echo "Swift installe avec succes!"
echo ""
echo "Verification:"
echo "  source /root/admin-openrc"
echo "  swift stat"
echo "  openstack container create test-container"
echo "  echo 'Hello Swift' > test.txt"
echo "  openstack object create test-container test.txt"
echo "  openstack object list test-container"
echo "=========================================="
