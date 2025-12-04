#!/bin/bash
# =============================================================================
# Script: 04-start-swift-services.sh
# Description: Demarre les services Swift sur Storage2
# A executer sur: storage2 (192.168.100.150) - TOI
# Prerequis: Ameni a execute 03-add-storage2-to-rings.sh
# =============================================================================

set -e

echo "=========================================="
echo "Demarrage des services Swift - Storage2"
echo "=========================================="

# Verifier que les fichiers ring sont presents
if [ ! -f /etc/swift/account.ring.gz ]; then
    echo "ERREUR: Les fichiers ring ne sont pas presents!"
    echo "Demande a Ameni d'executer 03-add-storage2-to-rings.sh d'abord"
    exit 1
fi

# Ajuster les permissions
chown -R swift:swift /etc/swift
chown -R swift:swift /srv/node
chown -R swift:swift /var/cache/swift

# Demarrer les services Account
echo "Demarrage des services Account..."
systemctl restart swift-account
systemctl restart swift-account-auditor
systemctl restart swift-account-reaper
systemctl restart swift-account-replicator

systemctl enable swift-account
systemctl enable swift-account-auditor
systemctl enable swift-account-reaper
systemctl enable swift-account-replicator

# Demarrer les services Container
echo "Demarrage des services Container..."
systemctl restart swift-container
systemctl restart swift-container-auditor
systemctl restart swift-container-replicator
systemctl restart swift-container-updater

systemctl enable swift-container
systemctl enable swift-container-auditor
systemctl enable swift-container-replicator
systemctl enable swift-container-updater

# Demarrer les services Object
echo "Demarrage des services Object..."
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
systemctl status swift-account --no-pager || true
systemctl status swift-container --no-pager || true
systemctl status swift-object --no-pager || true
echo ""
echo "Pour tester depuis le controller (Ameni):"
echo "  source /root/admin-openrc"
echo "  swift stat"
echo "=========================================="
