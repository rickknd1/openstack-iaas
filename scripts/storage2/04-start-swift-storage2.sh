#!/bin/bash
# =============================================================================
# Script: 04-start-swift-storage2.sh
# Description: Demarre les services Swift sur Storage2
# A executer sur: ton COMPUTE transforme en Storage2
# Prerequis: Ameni a execute 03-controller-add-storage2.sh
#            et t'a envoye les fichiers ring
# =============================================================================

set -e

echo "=========================================="
echo "Demarrage des services Swift - Storage2"
echo "=========================================="

# =============================================================================
# 1. VERIFICATION DES FICHIERS
# =============================================================================
echo "[1/3] Verification des fichiers ring..."

if [ ! -f /etc/swift/account.ring.gz ]; then
    echo "ERREUR: /etc/swift/account.ring.gz manquant!"
    echo ""
    echo "Demande a Ameni de t'envoyer les fichiers:"
    echo "  - account.ring.gz"
    echo "  - container.ring.gz"
    echo "  - object.ring.gz"
    echo "  - swift.conf"
    echo ""
    echo "Place-les dans /etc/swift/"
    exit 1
fi

if [ ! -f /etc/swift/swift.conf ]; then
    echo "ERREUR: /etc/swift/swift.conf manquant!"
    exit 1
fi

echo "Fichiers ring presents."

# =============================================================================
# 2. PERMISSIONS
# =============================================================================
echo "[2/3] Configuration des permissions..."

chown -R swift:swift /etc/swift
chown -R swift:swift /srv/node
chown -R swift:swift /var/cache/swift

# =============================================================================
# 3. DEMARRAGE DES SERVICES
# =============================================================================
echo "[3/3] Demarrage des services Swift..."

# Services Account
systemctl restart swift-account
systemctl restart swift-account-auditor
systemctl restart swift-account-reaper
systemctl restart swift-account-replicator

systemctl enable swift-account
systemctl enable swift-account-auditor
systemctl enable swift-account-reaper
systemctl enable swift-account-replicator

# Services Container
systemctl restart swift-container
systemctl restart swift-container-auditor
systemctl restart swift-container-replicator
systemctl restart swift-container-updater

systemctl enable swift-container
systemctl enable swift-container-auditor
systemctl enable swift-container-replicator
systemctl enable swift-container-updater

# Services Object
systemctl restart swift-object
systemctl restart swift-object-auditor
systemctl restart swift-object-replicator
systemctl restart swift-object-updater

systemctl enable swift-object
systemctl enable swift-object-auditor
systemctl enable swift-object-replicator
systemctl enable swift-object-updater

echo ""
echo "=========================================="
echo "Services Swift demarres!"
echo ""
echo "Verification des services:"
systemctl status swift-account --no-pager -l | head -5
systemctl status swift-container --no-pager -l | head -5
systemctl status swift-object --no-pager -l | head -5
echo ""
echo "Pour tester depuis le CONTROLLER (Ameni):"
echo "  source /root/admin-openrc"
echo "  swift stat"
echo "  openstack container create test-container"
echo "  echo 'Hello Swift' > test.txt"
echo "  openstack object create test-container test.txt"
echo "  openstack object list test-container"
echo "=========================================="
