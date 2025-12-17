#!/bin/bash
# =============================================================================
# Script: 01-chrony-storage2.sh
# Description: Installe et configure Chrony pour synchronisation avec controller
# A executer sur: Storage2 (192.168.100.155)
# =============================================================================

set -e

echo "=========================================="
echo "Installation de Chrony - Storage2"
echo "=========================================="

# =============================================================================
# 1. INSTALLATION
# =============================================================================
echo "[1/3] Installation de Chrony..."
apt update
apt install -y chrony

# =============================================================================
# 2. CONFIGURATION - Synchronisation avec le controller
# =============================================================================
echo "[2/3] Configuration de Chrony..."

cat > /etc/chrony/chrony.conf << 'EOF'
# Configuration Chrony pour Storage2 OpenStack
# Se synchronise avec le controller (192.168.100.136)
server controller iburst

# Fichiers standards
driftfile /var/lib/chrony/chrony.drift
logdir /var/log/chrony
maxupdateskew 100.0
rtcsync
makestep 1 3
EOF

# =============================================================================
# 3. DEMARRAGE
# =============================================================================
echo "[3/3] Demarrage de Chrony..."

systemctl restart chrony
systemctl enable chrony

sleep 3

echo ""
echo "Status de synchronisation:"
chronyc sources

echo "=========================================="
echo "Chrony configure!"
echo ""
echo "Note: ^* = synchronise, ^? = en attente"
echo ""
echo "PROCHAINE ETAPE: bash 02-swift-storage2.sh"
echo "=========================================="
