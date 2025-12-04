#!/bin/bash
# =============================================================================
# Script: 01-configure-hosts.sh
# Description: Configure /etc/hosts pour Storage2
# A executer sur: storage2 (192.168.100.150) - TOI
# =============================================================================

set -e

echo "=========================================="
echo "Configuration des hosts - Storage2"
echo "=========================================="

# Backup du fichier hosts
cp /etc/hosts /etc/hosts.backup

# Ajouter les entries du groupe
cat >> /etc/hosts << EOF

# OpenStack Cluster - Groupe PI
192.168.100.136 controller
192.168.100.162 compute1
192.168.100.154 compute2
192.168.100.113 storage1
192.168.100.200 compute3
192.168.100.150 storage2
EOF

echo "Fichier /etc/hosts configure!"
echo ""
echo "Verification:"
cat /etc/hosts

echo ""
echo "Test de connectivite vers le controller..."
ping -c 2 controller || echo "ATTENTION: Controller non joignable!"

echo "=========================================="
echo "Configuration hosts terminee!"
echo "=========================================="
