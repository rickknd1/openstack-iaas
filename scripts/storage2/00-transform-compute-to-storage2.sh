#!/bin/bash
# =============================================================================
# Script: 00-transform-compute-to-storage2.sh
# Description: Transforme un compute node en Storage2 pour Swift
# A executer sur: ton COMPUTE que tu veux transformer en Storage2
# =============================================================================

set -e

echo "=========================================="
echo "Transformation Compute -> Storage2"
echo "=========================================="

NEW_IP="192.168.100.150"
NEW_HOSTNAME="storage2"

# =============================================================================
# 1. CHANGER LE HOSTNAME
# =============================================================================
echo "[1/4] Changement du hostname..."

hostnamectl set-hostname ${NEW_HOSTNAME}
echo "${NEW_HOSTNAME}" > /etc/hostname

echo "Hostname change en: ${NEW_HOSTNAME}"

# =============================================================================
# 2. CONFIGURER L'IP STATIQUE
# =============================================================================
echo "[2/4] Configuration de l'IP statique..."

# Trouver l'interface reseau principale
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)

if [ -z "$INTERFACE" ]; then
    INTERFACE="ens33"
fi

echo "Interface detectee: ${INTERFACE}"

# Backup de la config netplan existante
cp /etc/netplan/*.yaml /etc/netplan/backup.yaml.bak 2>/dev/null || true

# Creer la nouvelle config netplan
cat > /etc/netplan/01-storage2-config.yaml << EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    ${INTERFACE}:
      addresses:
        - ${NEW_IP}/24
      routes:
        - to: default
          via: 192.168.100.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
EOF

echo "Configuration netplan creee."

# =============================================================================
# 3. CONFIGURER /etc/hosts
# =============================================================================
echo "[3/4] Configuration de /etc/hosts..."

# Backup
cp /etc/hosts /etc/hosts.backup

# Nettoyer les anciennes entries openstack
sed -i '/controller/d' /etc/hosts
sed -i '/compute/d' /etc/hosts
sed -i '/storage/d' /etc/hosts

# Ajouter les nouvelles entries
cat >> /etc/hosts << EOF

# OpenStack Cluster - Groupe PI
192.168.100.136 controller
192.168.100.162 compute1
192.168.100.154 compute2
192.168.100.113 storage1
192.168.100.200 compute3
192.168.100.150 storage2
EOF

echo "/etc/hosts configure."

# =============================================================================
# 4. APPLIQUER LA CONFIGURATION RESEAU
# =============================================================================
echo "[4/4] Application de la configuration reseau..."

echo ""
echo "=========================================="
echo "ATTENTION: Le reseau va etre reconfigure!"
echo "Tu risques de perdre la connexion SSH."
echo ""
echo "Nouvelle IP: ${NEW_IP}"
echo "Nouveau hostname: ${NEW_HOSTNAME}"
echo ""
echo "Apres le reboot, reconnecte-toi avec:"
echo "  ssh root@${NEW_IP}"
echo "=========================================="
echo ""
read -p "Appuie sur ENTRER pour continuer (ou Ctrl+C pour annuler)..."

netplan apply

echo ""
echo "Configuration reseau appliquee!"
echo ""
echo "PROCHAINE ETAPE:"
echo "  Reconnecte-toi: ssh root@${NEW_IP}"
echo "  Puis execute: bash 02-swift-storage2.sh"
echo ""
echo "Si tu perds la connexion, reboot la VM"
echo "et connecte-toi avec la nouvelle IP."
echo "=========================================="
