#!/bin/bash
# =============================================================================
# Script: 04-glance-controller.sh
# Description: Installe et configure Glance (Image Service)
# A executer sur: controller UNIQUEMENT
# Prerequis: Keystone doit etre installe
# =============================================================================

echo "=========================================="
echo "Installation de Glance (Image Service)"
echo "=========================================="

# Variables
MYSQL_ROOT_PASS="openstack_root_pwd"
GLANCE_DB_PASS="glance_dbpass"
GLANCE_PASS="glance_pass"

# Charger les credentials admin
source /root/admin-openrc

# =============================================================================
# 1. CREATION DE LA BASE DE DONNEES GLANCE
# =============================================================================
echo "[1/6] Creation de la base de donnees Glance..."

mysql -u root -p${MYSQL_ROOT_PASS} << EOF
CREATE DATABASE IF NOT EXISTS glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '${GLANCE_DB_PASS}';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '${GLANCE_DB_PASS}';
FLUSH PRIVILEGES;
EOF

echo "Base de donnees Glance creee."

# =============================================================================
# 2. CREATION DE L'UTILISATEUR ET DU SERVICE GLANCE
# =============================================================================
echo "[2/6] Creation de l'utilisateur Glance dans Keystone..."

# Creer le projet service s'il n'existe pas
openstack project create --domain default --description "Service Project" service 2>/dev/null || echo "Projet service existe deja"

# Creer l'utilisateur glance (ignorer si existe)
openstack user create --domain default --password ${GLANCE_PASS} glance 2>/dev/null || echo "Utilisateur glance existe deja"

# Ajouter le role admin a l'utilisateur glance
openstack role add --project service --user glance admin 2>/dev/null || echo "Role deja assigne"

# Creer le service glance (ignorer si existe)
openstack service create --name glance --description "OpenStack Image" image 2>/dev/null || echo "Service glance existe deja"

# Creer les endpoints (ignorer si existent)
openstack endpoint create --region RegionOne image public http://controller:9292 2>/dev/null || echo "Endpoint public existe"
openstack endpoint create --region RegionOne image internal http://controller:9292 2>/dev/null || echo "Endpoint internal existe"
openstack endpoint create --region RegionOne image admin http://controller:9292 2>/dev/null || echo "Endpoint admin existe"

echo "Utilisateur et service Glance crees."

# =============================================================================
# 3. INSTALLATION DE GLANCE
# =============================================================================
echo "[3/6] Installation de Glance..."
apt install -y glance

# =============================================================================
# 4. CONFIGURATION DE GLANCE API
# =============================================================================
echo "[4/6] Configuration de Glance..."

cat > /etc/glance/glance-api.conf << EOF
[DEFAULT]
show_image_direct_url = True

[database]
connection = mysql+pymysql://glance:${GLANCE_DB_PASS}@controller/glance

[keystone_authtoken]
www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = glance
password = ${GLANCE_PASS}

[paste_deploy]
flavor = keystone

[glance_store]
stores = file,http
default_store = file
filesystem_store_datadir = /var/lib/glance/images/

[oslo_limit]
auth_url = http://controller:5000
auth_type = password
user_domain_id = default
username = glance
system_scope = all
password = ${GLANCE_PASS}
endpoint_id = ENDPOINT_ID
region_name = RegionOne
EOF

# =============================================================================
# 5. SYNCHRONISATION DE LA BASE DE DONNEES
# =============================================================================
echo "[5/6] Synchronisation de la base de donnees Glance..."
su -s /bin/sh -c "glance-manage db_sync" glance

# =============================================================================
# 6. DEMARRAGE DU SERVICE
# =============================================================================
echo "[6/6] Demarrage du service Glance..."
systemctl restart glance-api
systemctl enable glance-api

echo "=========================================="
echo "Glance installe avec succes!"
echo ""
echo "Verification:"
echo "  source /root/admin-openrc"
echo "  openstack image list"
echo ""
echo "Pour telecharger une image Cirros de test:"
echo "  wget http://download.cirros-cloud.net/0.6.2/cirros-0.6.2-x86_64-disk.img"
echo "  openstack image create \"cirros\" --file cirros-0.6.2-x86_64-disk.img --disk-format qcow2 --container-format bare --public"
echo "=========================================="
