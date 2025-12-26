#!/bin/bash
# =============================================================================
# Script: 19-create-networks.sh
# Description: Cree les reseaux provider et self-service dans OpenStack
# A executer sur: controller UNIQUEMENT
# Prerequis: Neutron configure
# =============================================================================

set -e

echo "=========================================="
echo "Creation des reseaux OpenStack"
echo "=========================================="

# Charger les credentials admin
source /root/admin-openrc

# =============================================================================
# 1. CREATION DU RESEAU PROVIDER (externe)
# =============================================================================
echo "[1/4] Creation du reseau provider..."

openstack network create --share --external \
  --provider-physical-network provider \
  --provider-network-type flat provider 2>/dev/null || echo "Network provider existe"

openstack subnet create --network provider \
  --allocation-pool start=192.168.10.100,end=192.168.10.200 \
  --dns-nameserver 8.8.8.8 \
  --gateway 192.168.10.2 \
  --subnet-range 192.168.10.0/24 provider-subnet 2>/dev/null || echo "Subnet existe"

echo "Reseau provider cree."

# =============================================================================
# 2. CREATION DU RESEAU SELF-SERVICE (interne)
# =============================================================================
echo "[2/4] Creation du reseau self-service..."

openstack network create selfservice 2>/dev/null || echo "Network selfservice existe"

openstack subnet create --network selfservice \
  --dns-nameserver 8.8.8.8 \
  --gateway 10.10.0.1 \
  --subnet-range 10.10.0.0/24 selfservice-subnet 2>/dev/null || echo "Subnet existe"

echo "Reseau self-service cree."

# =============================================================================
# 3. CREATION DU ROUTEUR
# =============================================================================
echo "[3/4] Creation du routeur..."

openstack router create router 2>/dev/null || echo "Router existe"

# Connecter le routeur au reseau externe
openstack router set --external-gateway provider router 2>/dev/null || true

# Connecter le routeur au sous-reseau interne
openstack router add subnet router selfservice-subnet 2>/dev/null || true

echo "Routeur cree et configure."

# =============================================================================
# 4. CREATION DES SECURITY GROUPS
# =============================================================================
echo "[4/4] Configuration des security groups..."

# Autoriser ICMP (ping)
openstack security group rule create --proto icmp default 2>/dev/null || true

# Autoriser SSH
openstack security group rule create --proto tcp --dst-port 22 default 2>/dev/null || true

# Autoriser HTTP
openstack security group rule create --proto tcp --dst-port 80 default 2>/dev/null || true

# Autoriser HTTPS
openstack security group rule create --proto tcp --dst-port 443 default 2>/dev/null || true

echo "=========================================="
echo "Reseaux configures avec succes!"
echo ""
echo "Reseaux crees:"
echo "  - provider (externe): 192.168.10.0/24"
echo "  - selfservice (interne): 10.10.0.0/24"
echo ""
echo "Verification:"
echo "  openstack network list"
echo "  openstack router list"
echo "  openstack security group rule list"
echo "=========================================="
