#!/bin/bash
# =============================================================================
# Script: 03-keystone-controller.sh
# Description: Installe et configure Keystone (Identity Service)
# A executer sur: controller UNIQUEMENT
# =============================================================================

set -e

echo "=========================================="
echo "Installation de Keystone (Identity Service)"
echo "=========================================="

# Variables
MYSQL_ROOT_PASS="openstack_root_pwd"
KEYSTONE_DB_PASS="keystone_dbpass"
ADMIN_PASS="admin_secret_pwd"
CONTROLLER_IP="10.0.0.11"

# =============================================================================
# 1. CREATION DE LA BASE DE DONNEES KEYSTONE
# =============================================================================
echo "[1/5] Creation de la base de donnees Keystone..."

mysql -u root -p${MYSQL_ROOT_PASS} << EOF
CREATE DATABASE IF NOT EXISTS keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '${KEYSTONE_DB_PASS}';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '${KEYSTONE_DB_PASS}';
FLUSH PRIVILEGES;
EOF

echo "Base de donnees Keystone creee."

# =============================================================================
# 2. INSTALLATION DE KEYSTONE
# =============================================================================
echo "[2/5] Installation de Keystone..."
apt install -y keystone

# =============================================================================
# 3. CONFIGURATION DE KEYSTONE
# =============================================================================
echo "[3/5] Configuration de Keystone..."

# Backup du fichier original
cp /etc/keystone/keystone.conf /etc/keystone/keystone.conf.bak

# Configuration
cat > /etc/keystone/keystone.conf << EOF
[DEFAULT]

[database]
connection = mysql+pymysql://keystone:${KEYSTONE_DB_PASS}@controller/keystone

[token]
provider = fernet

[cache]
enabled = true
backend = oslo_cache.memcache_pool
memcache_servers = controller:11211
EOF

# =============================================================================
# 4. SYNCHRONISATION DE LA BASE DE DONNEES
# =============================================================================
echo "[4/5] Synchronisation de la base de donnees Keystone..."
su -s /bin/sh -c "keystone-manage db_sync" keystone

# Initialisation des repositories Fernet
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

# Bootstrap de Keystone
keystone-manage bootstrap --bootstrap-password ${ADMIN_PASS} \
  --bootstrap-admin-url http://controller:5000/v3/ \
  --bootstrap-internal-url http://controller:5000/v3/ \
  --bootstrap-public-url http://controller:5000/v3/ \
  --bootstrap-region-id RegionOne

# =============================================================================
# 5. CONFIGURATION D'APACHE
# =============================================================================
echo "[5/5] Configuration d'Apache pour Keystone..."

# Configurer ServerName dans Apache
echo "ServerName controller" >> /etc/apache2/apache2.conf

systemctl restart apache2
systemctl enable apache2

# =============================================================================
# CREATION DES FICHIERS D'ENVIRONNEMENT
# =============================================================================
echo "Creation des fichiers d'environnement..."

# Admin RC file
cat > /root/admin-openrc << EOF
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=${ADMIN_PASS}
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

chmod 600 /root/admin-openrc

# =============================================================================
# CREATION DU PROJET SERVICE
# =============================================================================
echo "Creation du projet service..."
source /root/admin-openrc
openstack project create --domain default --description "Service Project" service 2>/dev/null || echo "Projet service existe deja"

echo "=========================================="
echo "Keystone installe avec succes!"
echo ""
echo "Pour utiliser OpenStack CLI:"
echo "  source /root/admin-openrc"
echo "  openstack token issue"
echo "=========================================="
