#!/bin/bash
# =============================================================================
# Script: 00-configure-hosts.sh
# Description: Configure /etc/hosts avec les IPs du groupe
# A executer sur: ton COMPUTE transforme en Storage2
# =============================================================================

set -e

echo "=========================================="
echo "Configuration de /etc/hosts - Storage2"
echo "=========================================="

# Backup
cp /etc/hosts /etc/hosts.backup.$(date +%Y%m%d%H%M%S)

# Supprimer les anciennes entries OpenStack si elles existent
sed -i '/controller/d' /etc/hosts
sed -i '/compute1/d' /etc/hosts
sed -i '/compute2/d' /etc/hosts
sed -i '/compute3/d' /etc/hosts
sed -i '/storage1/d' /etc/hosts
sed -i '/storage2/d' /etc/hosts

# Ajouter les nouvelles entries
cat >> /etc/hosts << 'EOF'

# OpenStack Cluster - Groupe PI
#Ameni
192.168.100.136 controller
#madame fandouli
192.168.100.172 compute1
#madame hedyene
192.168.100.154 compute2
#madame cherni
192.168.100.113 storage1
#Lmallekh
192.168.100.200 compute3
#Moi
192.168.100.155 storage2
EOF

echo "Fichier /etc/hosts mis a jour:"
echo ""
cat /etc/hosts

echo ""
echo "=========================================="
echo "/etc/hosts configure!"
echo "=========================================="
