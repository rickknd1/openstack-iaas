#!/bin/bash
# =============================================================================
# Script: 06-nova-controller.sh
# Description: Installe et configure Nova sur le Controller
# A executer sur: controller UNIQUEMENT
# Prerequis: Keystone, Glance, Placement
# =============================================================================

set -e

echo "=========================================="
echo "Installation de Nova (Compute) - Controller"
echo "=========================================="

# Variables
MYSQL_ROOT_PASS="openstack_root_pwd"
NOVA_DB_PASS="nova_dbpass"
NOVA_PASS="nova_pass"
PLACEMENT_PASS="placement_pass"
RABBITMQ_PASS="rabbit_openstack_pwd"
CONTROLLER_IP="192.168.10.130"

# Charger les credentials admin
source /root/admin-openrc

# =============================================================================
# 1. CREATION DES BASES DE DONNEES NOVA
# =============================================================================
echo "[1/6] Creation des bases de donnees Nova..."

mysql -u root -p${MYSQL_ROOT_PASS} << EOF
CREATE DATABASE IF NOT EXISTS nova_api;
CREATE DATABASE IF NOT EXISTS nova;
CREATE DATABASE IF NOT EXISTS nova_cell0;

GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY '${NOVA_DB_PASS}';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY '${NOVA_DB_PASS}';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '${NOVA_DB_PASS}';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '${NOVA_DB_PASS}';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY '${NOVA_DB_PASS}';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY '${NOVA_DB_PASS}';
FLUSH PRIVILEGES;
EOF

echo "Bases de donnees Nova creees."

# =============================================================================
# 2. CREATION DE L'UTILISATEUR ET DU SERVICE NOVA
# =============================================================================
echo "[2/6] Creation de l'utilisateur Nova dans Keystone..."

# Creer l'utilisateur nova
openstack user create --domain default --password ${NOVA_PASS} nova 2>/dev/null || echo "User nova existe"

# Ajouter le role admin
openstack role add --project service --user nova admin 2>/dev/null || true

# Creer le service compute
openstack service create --name nova --description "OpenStack Compute" compute 2>/dev/null || echo "Service existe"

# Creer les endpoints
openstack endpoint create --region RegionOne compute public http://controller:8774/v2.1 2>/dev/null || true
openstack endpoint create --region RegionOne compute internal http://controller:8774/v2.1 2>/dev/null || true
openstack endpoint create --region RegionOne compute admin http://controller:8774/v2.1 2>/dev/null || true

echo "Utilisateur et service Nova crees."

# =============================================================================
# 3. INSTALLATION DE NOVA
# =============================================================================
echo "[3/6] Installation de Nova..."
apt install -y nova-api nova-conductor nova-novncproxy nova-scheduler

# =============================================================================
# 4. CONFIGURATION DE NOVA
# =============================================================================
echo "[4/6] Configuration de Nova..."

cat > /etc/nova/nova.conf << EOF
[DEFAULT]
log_dir = /var/log/nova
lock_path = /var/lock/nova
state_path = /var/lib/nova
transport_url = rabbit://openstack:${RABBITMQ_PASS}@controller
my_ip = ${CONTROLLER_IP}

[api]
auth_strategy = keystone

[api_database]
connection = mysql+pymysql://nova:${NOVA_DB_PASS}@controller/nova_api

[database]
connection = mysql+pymysql://nova:${NOVA_DB_PASS}@controller/nova

[keystone_authtoken]
www_authenticate_uri = http://controller:5000/
auth_url = http://controller:5000/
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = ${NOVA_PASS}

[service_user]
send_service_user_token = true
auth_url = http://controller:5000/
auth_strategy = keystone
auth_type = password
project_domain_name = Default
project_name = service
user_domain_name = Default
username = nova
password = ${NOVA_PASS}

[vnc]
enabled = true
server_listen = \$my_ip
server_proxyclient_address = \$my_ip

[glance]
api_servers = http://controller:9292

[oslo_concurrency]
lock_path = /var/lib/nova/tmp

[placement]
region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://controller:5000/v3
username = placement
password = ${PLACEMENT_PASS}

[scheduler]
discover_hosts_in_cells_interval = 300
EOF

# =============================================================================
# 5. SYNCHRONISATION DES BASES DE DONNEES
# =============================================================================
echo "[5/6] Synchronisation des bases de donnees Nova..."

su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova 2>/dev/null || echo "Cell1 existe deja"
su -s /bin/sh -c "nova-manage db sync" nova
su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova

# =============================================================================
# 6. DEMARRAGE DES SERVICES
# =============================================================================
echo "[6/6] Demarrage des services Nova..."

systemctl restart nova-api
systemctl restart nova-scheduler
systemctl restart nova-conductor
systemctl restart nova-novncproxy

systemctl enable nova-api nova-scheduler nova-conductor nova-novncproxy

echo "=========================================="
echo "Nova Controller installe avec succes!"
echo ""
echo "Verification:"
echo "  source /root/admin-openrc"
echo "  openstack compute service list"
echo ""
echo "IMPORTANT: Executez maintenant le script"
echo "07-nova-compute.sh sur le node COMPUTE"
echo "=========================================="
