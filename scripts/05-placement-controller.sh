#!/bin/bash
# =============================================================================
# Script: 05-placement-controller.sh
# Description: Installe et configure Placement
# A executer sur: controller UNIQUEMENT
# Prerequis: Keystone doit etre installe
# =============================================================================

set -e

echo "=========================================="
echo "Installation de Placement"
echo "=========================================="

# Variables
MYSQL_ROOT_PASS="openstack_root_pwd"
PLACEMENT_DB_PASS="placement_dbpass"
PLACEMENT_PASS="placement_pass"

# Charger les credentials admin
source /root/admin-openrc

# =============================================================================
# 1. CREATION DE LA BASE DE DONNEES PLACEMENT
# =============================================================================
echo "[1/5] Creation de la base de donnees Placement..."

mysql -u root -p${MYSQL_ROOT_PASS} << EOF
CREATE DATABASE IF NOT EXISTS placement;
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' IDENTIFIED BY '${PLACEMENT_DB_PASS}';
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' IDENTIFIED BY '${PLACEMENT_DB_PASS}';
FLUSH PRIVILEGES;
EOF

echo "Base de donnees Placement creee."

# =============================================================================
# 2. CREATION DE L'UTILISATEUR ET DU SERVICE PLACEMENT
# =============================================================================
echo "[2/5] Creation de l'utilisateur Placement dans Keystone..."

# Creer l'utilisateur placement
openstack user create --domain default --password ${PLACEMENT_PASS} placement

# Ajouter le role admin
openstack role add --project service --user placement admin

# Creer le service placement
openstack service create --name placement --description "Placement API" placement

# Creer les endpoints
openstack endpoint create --region RegionOne placement public http://controller:8778
openstack endpoint create --region RegionOne placement internal http://controller:8778
openstack endpoint create --region RegionOne placement admin http://controller:8778

echo "Utilisateur et service Placement crees."

# =============================================================================
# 3. INSTALLATION DE PLACEMENT
# =============================================================================
echo "[3/5] Installation de Placement..."
apt install -y placement-api

# =============================================================================
# 4. CONFIGURATION DE PLACEMENT
# =============================================================================
echo "[4/5] Configuration de Placement..."

cat > /etc/placement/placement.conf << EOF
[DEFAULT]

[api]
auth_strategy = keystone

[keystone_authtoken]
auth_url = http://controller:5000/v3
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = placement
password = ${PLACEMENT_PASS}

[placement_database]
connection = mysql+pymysql://placement:${PLACEMENT_DB_PASS}@controller/placement
EOF

# =============================================================================
# 5. SYNCHRONISATION DE LA BASE DE DONNEES
# =============================================================================
echo "[5/5] Synchronisation de la base de donnees Placement..."
su -s /bin/sh -c "placement-manage db sync" placement

# Redemarrer Apache
systemctl restart apache2

echo "=========================================="
echo "Placement installe avec succes!"
echo ""
echo "Verification:"
echo "  source /root/admin-openrc"
echo "  placement-status upgrade check"
echo "=========================================="
