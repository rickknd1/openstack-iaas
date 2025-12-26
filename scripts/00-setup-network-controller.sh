#!/bin/bash
# =============================================================================
# Script: 00-setup-network-controller.sh
# Description: Configure le reseau pour le CONTROLLER
# A executer sur: controller UNIQUEMENT
# =============================================================================

set -e

echo "=========================================="
echo "Configuration Reseau - Controller"
echo "=========================================="

HOSTNAME="controller"
IP_ADDRESS="192.168.10.11"
GATEWAY="192.168.10.2"
DNS="8.8.8.8"

# =============================================================================
# 1. CONFIGURER LE HOSTNAME
# =============================================================================
echo "[1/3] Configuration du hostname..."
hostnamectl set-hostname ${HOSTNAME}

# =============================================================================
# 2. CONFIGURER LE RESEAU (Netplan)
# =============================================================================
echo "[2/3] Configuration du reseau..."

cat > /etc/netplan/00-installer-config.yaml << EOF
network:
  ethernets:
    ens33:
      addresses:
        - ${IP_ADDRESS}/24
      routes:
        - to: default
          via: ${GATEWAY}
      nameservers:
        addresses:
          - ${DNS}
          - 8.8.4.4
  version: 2
EOF

# Appliquer la configuration
netplan apply

echo "Reseau configure: ${IP_ADDRESS}"

# =============================================================================
# 3. VERIFIER LA CONNECTIVITE
# =============================================================================
echo "[3/3] Verification de la connectivite..."

sleep 2
echo "Test ping vers gateway..."
ping -c 2 ${GATEWAY} && echo "OK: Gateway joignable!" || echo "ERREUR: Gateway non joignable"

echo "Test ping vers internet..."
ping -c 2 8.8.8.8 && echo "OK: Internet joignable!" || echo "ERREUR: Internet non joignable"

echo "=========================================="
echo "Configuration reseau terminee!"
echo "IP: ${IP_ADDRESS}"
echo ""
echo "PROCHAINE ETAPE: bash 01-prerequisites-all-nodes.sh"
echo "=========================================="
