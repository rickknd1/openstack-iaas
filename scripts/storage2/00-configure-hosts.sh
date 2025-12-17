#!/bin/bash
# =============================================================================
# Script: 00-configure-hosts.sh
# Description: Configure /etc/hosts et le reseau pour Storage2 (via NAT)
# A executer sur: Storage2
# =============================================================================

set -e

echo "=========================================="
echo "Configuration reseau et hosts - Storage2"
echo "=========================================="

# =============================================================================
# 1. CONFIGURATION /etc/hosts
# =============================================================================
echo "[1/2] Configuration de /etc/hosts..."

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
#Moi (IP visible via port forwarding Windows)
192.168.100.155 storage2
EOF

echo "/etc/hosts configure."

# =============================================================================
# 2. CONFIGURATION ROUTE RESEAU (NAT vers reseau collegues)
# =============================================================================
echo "[2/2] Configuration de la route reseau..."

# Activer ens38 (NAT) si pas deja fait
ip link set ens38 up 2>/dev/null || true
dhclient ens38 2>/dev/null || true

# Ajouter route vers le reseau des collegues via la passerelle NAT
ip route add 192.168.100.0/24 via 192.168.43.1 dev ens38 2>/dev/null || echo "Route deja presente ou via autre interface"

# Test connectivite
echo ""
echo "Test de connectivite vers le controller..."
ping -c 2 192.168.100.136 && echo "OK: Controller joignable!" || echo "ATTENTION: Controller non joignable - verifiez le reseau"

echo ""
echo "=========================================="
echo "Configuration terminee!"
echo ""
echo "PROCHAINE ETAPE: bash 01-chrony-storage2.sh"
echo "=========================================="
