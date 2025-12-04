#!/bin/bash
# =============================================================================
# Script: 01-chrony-storage2.sh
# Description: Installe et configure Chrony pour la synchronisation temps
# A executer sur: ton COMPUTE transforme en Storage2
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
# 2. CONFIGURATION
# =============================================================================
echo "[2/3] Configuration de Chrony..."

# Utiliser des serveurs NTP publics (plus fiable)
cat > /etc/chrony/chrony.conf << EOF
# Serveurs NTP publics
pool pool.ntp.org iburst
server controller iburst

# Fichiers
keyfile /etc/chrony/chrony.keys
driftfile /var/lib/chrony/chrony.drift
logdir /var/log/chrony

# Options
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

# Attendre un peu pour la synchronisation
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
