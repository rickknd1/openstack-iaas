#!/bin/bash
# =============================================================================
# Script: 00-setup-network-nat.sh
# Description: Configure le reseau pour Storage2 via NAT
# A executer sur: ton COMPUTE transforme en Storage2
# =============================================================================

set -e

echo "=========================================="
echo "Configuration Reseau - Storage2 (NAT)"
echo "=========================================="

# =============================================================================
# 1. CONFIGURER /etc/hosts
# =============================================================================
echo "[1/3] Configuration de /etc/hosts..."

# Backup
cp /etc/hosts /etc/hosts.backup

# Ajouter les entries du groupe
cat >> /etc/hosts << EOF

# OpenStack Cluster - Groupe PI
192.168.100.136 controller
192.168.100.162 compute1
192.168.100.154 compute2
192.168.100.113 storage1
192.168.100.200 compute3
192.168.100.155 storage2
EOF

echo "/etc/hosts configure."

# =============================================================================
# 2. ACTIVER L'INTERFACE NAT
# =============================================================================
echo "[2/3] Activation de l'interface NAT (ens38)..."

# Activer ens38 et obtenir une IP via DHCP
ip link set ens38 up
dhclient ens38

# Afficher l'IP obtenue
echo "IP obtenue sur ens38:"
ip addr show ens38 | grep "inet "

# =============================================================================
# 3. AJOUTER LA ROUTE VERS LE RESEAU DE LA CLASSE
# =============================================================================
echo "[3/3] Ajout de la route vers 192.168.100.0/24..."

# Ajouter la route
ip route add 192.168.100.0/24 via 192.168.43.2 dev ens38 2>/dev/null || echo "Route deja presente"

# Tester la connectivite
echo ""
echo "Test de connectivite vers le controller..."
ping -c 2 192.168.100.136 && echo "OK: Controller joignable!" || echo "ERREUR: Controller non joignable"

echo "=========================================="
echo "Reseau configure!"
echo ""
echo "PROCHAINE ETAPE: bash 01-chrony-storage2.sh"
echo "=========================================="
