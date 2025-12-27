#!/bin/bash
# =============================================================================
# Script: 01-prerequisites-all-nodes.sh
# Description: Configure les prerequis sur TOUTES les VMs OpenStack
# A executer sur: controller, compute, storage
# =============================================================================

set -e

echo "=========================================="
echo "Configuration des prerequis OpenStack"
echo "=========================================="

# =============================================================================
# 1. CONFIGURATION DU FICHIER /etc/hosts
# =============================================================================
echo "[1/6] Configuration de /etc/hosts..."

# Supprimer anciennes entrees si elles existent
sed -i '/controller/d' /etc/hosts
sed -i '/compute/d' /etc/hosts
sed -i '/storage/d' /etc/hosts

cat >> /etc/hosts << 'EOF'

# OpenStack Nodes (NAT - 192.168.10.0/24)
192.168.10.130   controller
192.168.10.131   compute
192.168.10.132   storage

# Infrastructure classe (pour connexion future)
# 192.168.100.136  controller-ameni
# 192.168.100.172  compute1-fandouli
# 192.168.100.154  compute2-hedyene
# 192.168.100.113  storage1-cherni
# 192.168.100.200  compute3-lmallekh
# 192.168.100.155  storage2-toi
EOF

echo "Fichier /etc/hosts configure."

# =============================================================================
# 2. MISE A JOUR DU SYSTEME
# =============================================================================
echo "[2/6] Mise a jour du systeme..."
apt update && apt upgrade -y

# =============================================================================
# 3. INSTALLATION ET CONFIGURATION DE CHRONY (NTP)
# =============================================================================
echo "[3/6] Installation de Chrony pour la synchronisation NTP..."
apt install -y chrony

# Determiner si c'est le controller ou un autre node
HOSTNAME=$(hostname)

if [ "$HOSTNAME" == "controller" ]; then
    # Le controller sert de serveur NTP pour les autres nodes
    cat > /etc/chrony/chrony.conf << 'EOF'
# Configuration Chrony pour le Controller OpenStack
server ntp.ubuntu.com iburst
server pool.ntp.org iburst
allow 192.168.10.0/24
local stratum 10
EOF
else
    # Les autres nodes se synchronisent avec le controller
    cat > /etc/chrony/chrony.conf << 'EOF'
# Configuration Chrony pour les nodes OpenStack
server controller iburst
EOF
fi

systemctl restart chrony
systemctl enable chrony

echo "Chrony configure et demarre."

# =============================================================================
# 4. AJOUT DU REPOSITORY OPENSTACK (Caracal)
# =============================================================================
echo "[4/6] Ajout du repository OpenStack Caracal..."
apt install -y software-properties-common
add-apt-repository -y cloud-archive:caracal
apt update

echo "Repository OpenStack Caracal ajoute."

# =============================================================================
# 5. INSTALLATION DES PAQUETS UTILITAIRES
# =============================================================================
echo "[5/6] Installation des paquets utilitaires..."
apt install -y python3-openstackclient python3-pip wget curl vim net-tools

# =============================================================================
# 6. CONFIGURATION DU FIREWALL (optionnel - desactiver pour le lab)
# =============================================================================
echo "[6/6] Desactivation du firewall pour l'environnement de lab..."
systemctl stop ufw 2>/dev/null || true
systemctl disable ufw 2>/dev/null || true

echo "=========================================="
echo "Prerequisites configures avec succes!"
echo "Redemarrez la VM: sudo reboot"
echo "=========================================="
