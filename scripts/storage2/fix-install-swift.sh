#!/bin/bash
# =============================================================================
# Script: fix-install-swift.sh
# Description: Installe Swift et vérifie l'installation
# A executer sur: ton COMPUTE transforme en Storage2
# =============================================================================

set -e

echo "=========================================="
echo "Installation de Swift - Storage2"
echo "=========================================="

# =============================================================================
# 1. MISE A JOUR
# =============================================================================
echo "[1/4] Mise a jour des paquets..."
apt update

# =============================================================================
# 2. INSTALLATION SWIFT
# =============================================================================
echo "[2/4] Installation de Swift..."
apt install -y swift swift-account swift-container swift-object python3-swiftclient xfsprogs rsync

# =============================================================================
# 3. VERIFICATION
# =============================================================================
echo "[3/4] Verification de l'installation..."
echo ""
echo "Version Swift:"
swift --version || echo "ERREUR: swift non installe"

echo ""
echo "Paquets installes:"
dpkg -l | grep swift

# =============================================================================
# 4. STATUS DES SERVICES
# =============================================================================
echo ""
echo "[4/4] Status des services Swift..."
systemctl status swift-account --no-pager -l 2>/dev/null | head -3 || echo "swift-account: non demarre"
systemctl status swift-container --no-pager -l 2>/dev/null | head -3 || echo "swift-container: non demarre"
systemctl status swift-object --no-pager -l 2>/dev/null | head -3 || echo "swift-object: non demarre"

echo ""
echo "=========================================="
echo "Installation terminee!"
echo ""
echo "PROCHAINE ETAPE:"
echo "  Relance le script de configuration:"
echo "  bash 02-swift-storage2.sh"
echo "=========================================="
