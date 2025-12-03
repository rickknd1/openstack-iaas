#!/bin/bash
# =============================================================================
# Script: 11-cinder-controller.sh
# Description: Installe et configure Cinder API sur le Controller
# A executer sur: controller UNIQUEMENT
# =============================================================================

set -e

echo "=========================================="
echo "Installation de Cinder - Controller"
echo "=========================================="

# Variables
MYSQL_ROOT_PASS="openstack_root_pwd"
CINDER_DB_PASS="cinder_dbpass"
CINDER_PASS="cinder_pass"
RABBITMQ_PASS="rabbit_openstack_pwd"
CONTROLLER_IP="10.0.0.11"

# Charger les credentials admin
source /root/admin-openrc

# =============================================================================
# 1. CREATION DE LA BASE DE DONNEES CINDER
# =============================================================================
echo "[1/5] Creation de la base de donnees Cinder..."

mysql -u root -p${MYSQL_ROOT_PASS} << EOF
CREATE DATABASE IF NOT EXISTS cinder;
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY '${CINDER_DB_PASS}';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY '${CINDER_DB_PASS}';
FLUSH PRIVILEGES;
EOF

echo "Base de donnees Cinder creee."

# =============================================================================
# 2. CREATION DE L'UTILISATEUR ET DU SERVICE CINDER
# =============================================================================
echo "[2/5] Creation de l'utilisateur Cinder dans Keystone..."

openstack user create --domain default --password ${CINDER_PASS} cinder
openstack role add --project service --user cinder admin
openstack service create --name cinderv3 --description "OpenStack Block Storage" volumev3

openstack endpoint create --region RegionOne volumev3 public http://controller:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 internal http://controller:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 admin http://controller:8776/v3/%\(project_id\)s

echo "Utilisateur et service Cinder crees."

# =============================================================================
# 3. INSTALLATION DE CINDER
# =============================================================================
echo "[3/5] Installation de Cinder..."
apt install -y cinder-api cinder-scheduler

# =============================================================================
# 4. CONFIGURATION DE CINDER
# =============================================================================
echo "[4/5] Configuration de Cinder..."

cat > /etc/cinder/cinder.conf << EOF
[DEFAULT]
transport_url = rabbit://openstack:${RABBITMQ_PASS}@controller
auth_strategy = keystone
my_ip = ${CONTROLLER_IP}

[database]
connection = mysql+pymysql://cinder:${CINDER_DB_PASS}@controller/cinder

[keystone_authtoken]
www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = cinder
password = ${CINDER_PASS}

[oslo_concurrency]
lock_path = /var/lib/cinder/tmp
EOF

# =============================================================================
# 5. SYNCHRONISATION ET DEMARRAGE
# =============================================================================
echo "[5/5] Synchronisation de la base de donnees..."

su -s /bin/sh -c "cinder-manage db sync" cinder

systemctl restart nova-api
systemctl restart cinder-scheduler
systemctl restart apache2

systemctl enable cinder-scheduler

echo "=========================================="
echo "Cinder Controller installe avec succes!"
echo ""
echo "IMPORTANT: Executez maintenant le script"
echo "12-cinder-storage.sh sur le node STORAGE"
echo "=========================================="
