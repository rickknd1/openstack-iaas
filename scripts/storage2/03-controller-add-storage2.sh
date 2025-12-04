#!/bin/bash
# =============================================================================
# Script: 03-controller-add-storage2.sh
# Description: Ajoute Storage2 aux rings Swift (via NAT/port forwarding)
# A executer sur: CONTROLLER (192.168.100.136) - AMENI
# =============================================================================

set -e

echo "=========================================="
echo "Ajout de Storage2 aux rings Swift"
echo "=========================================="

# Variables
# IP publique de Storage2 (IP Wi-Fi du PC de ton camarade)
STORAGE2_IP="192.168.100.155"

# =============================================================================
# 1. VERIFICATION
# =============================================================================
echo "[1/4] Verification de la connectivite..."

ping -c 2 ${STORAGE2_IP} || {
    echo "ERREUR: Storage2 (${STORAGE2_IP}) non joignable!"
    echo "Verifie que ton camarade a configure le port forwarding sur Windows."
    exit 1
}

echo "Storage2 joignable!"

# =============================================================================
# 2. AJOUT AUX RINGS
# =============================================================================
echo "[2/4] Ajout de Storage2 aux rings..."

cd /etc/swift

# Ajouter storage2 aux rings (zone 2)
swift-ring-builder account.builder add --region 1 --zone 2 --ip ${STORAGE2_IP} --port 6202 --device sdc --weight 100
swift-ring-builder container.builder add --region 1 --zone 2 --ip ${STORAGE2_IP} --port 6201 --device sdc --weight 100
swift-ring-builder object.builder add --region 1 --zone 2 --ip ${STORAGE2_IP} --port 6200 --device sdc --weight 100

echo "Storage2 ajoute aux rings."

# =============================================================================
# 3. REBALANCER LES RINGS
# =============================================================================
echo "[3/4] Rebalancement des rings..."

swift-ring-builder account.builder rebalance
swift-ring-builder container.builder rebalance
swift-ring-builder object.builder rebalance

echo "Rings rebalances."

# =============================================================================
# 4. INFO POUR LA SUITE
# =============================================================================
echo ""
echo "=========================================="
echo "Storage2 ajoute aux rings!"
echo ""
echo "IMPORTANT: Tu dois maintenant envoyer les"
echo "fichiers suivants a ton camarade (Storage2):"
echo ""
echo "  /etc/swift/account.ring.gz"
echo "  /etc/swift/container.ring.gz"
echo "  /etc/swift/object.ring.gz"
echo "  /etc/swift/swift.conf"
echo ""
echo "Commande pour copier (si SSH accessible):"
echo "  scp /etc/swift/*.ring.gz /etc/swift/swift.conf root@${STORAGE2_IP}:/etc/swift/"
echo ""
echo "Sinon, utilise une cle USB ou un autre moyen."
echo ""
echo "Apres, ton camarade doit executer:"
echo "  04-start-swift-storage2.sh"
echo "=========================================="
