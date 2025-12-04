#!/bin/bash
# =============================================================================
# Script: 05-cinder-backup-swift.sh
# Description: Configure Cinder Backup avec Swift comme backend
# A executer sur: CONTROLLER (ou le node qui a Cinder)
# =============================================================================

set -e

echo "=========================================="
echo "Configuration Cinder Backup avec Swift"
echo "=========================================="

# =============================================================================
# 1. INSTALLATION DE CINDER-BACKUP
# =============================================================================
echo "[1/4] Installation de cinder-backup..."
apt update
apt install -y cinder-backup

# =============================================================================
# 2. CONFIGURATION DE CINDER POUR SWIFT BACKUP
# =============================================================================
echo "[2/4] Configuration de Cinder..."

# Backup du fichier original
cp /etc/cinder/cinder.conf /etc/cinder/cinder.conf.backup.$(date +%Y%m%d%H%M%S)

# Verifier si la section [DEFAULT] contient deja backup_driver
if grep -q "^backup_driver" /etc/cinder/cinder.conf; then
    # Modifier la ligne existante
    sed -i 's/^backup_driver.*/backup_driver = cinder.backup.drivers.swift.SwiftBackupDriver/' /etc/cinder/cinder.conf
else
    # Ajouter apres [DEFAULT]
    sed -i '/^\[DEFAULT\]/a backup_driver = cinder.backup.drivers.swift.SwiftBackupDriver' /etc/cinder/cinder.conf
fi

# Ajouter les autres parametres Swift si pas presents
if ! grep -q "^backup_swift_url" /etc/cinder/cinder.conf; then
    sed -i '/^backup_driver.*SwiftBackupDriver/a backup_swift_url = http://controller:8080/v1/AUTH_' /etc/cinder/cinder.conf
fi

if ! grep -q "^backup_swift_auth_version" /etc/cinder/cinder.conf; then
    sed -i '/^backup_swift_url/a backup_swift_auth_version = 1' /etc/cinder/cinder.conf
fi

if ! grep -q "^backup_swift_container" /etc/cinder/cinder.conf; then
    sed -i '/^backup_swift_auth_version/a backup_swift_container = cinder-backups' /etc/cinder/cinder.conf
fi

echo "Configuration ajoutee a /etc/cinder/cinder.conf"

# =============================================================================
# 3. AFFICHER LA CONFIGURATION
# =============================================================================
echo "[3/4] Configuration actuelle:"
echo ""
grep -A 10 "backup_driver" /etc/cinder/cinder.conf | head -15

# =============================================================================
# 4. REDEMARRAGE DES SERVICES
# =============================================================================
echo ""
echo "[4/4] Redemarrage des services Cinder..."

systemctl restart cinder-backup
systemctl enable cinder-backup
systemctl restart cinder-volume
systemctl restart cinder-scheduler

echo ""
echo "Status cinder-backup:"
systemctl status cinder-backup --no-pager -l | head -5

echo "=========================================="
echo "Cinder Backup configure avec Swift!"
echo ""
echo "URL Swift: http://controller:8080/v1/AUTH_"
echo "Container: cinder-backups"
echo ""
echo "Pour tester:"
echo "  source /root/admin-openrc"
echo "  openstack volume backup create --name test-backup <volume-id>"
echo "=========================================="
