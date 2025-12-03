#!/bin/bash
# =============================================================================
# Script: 16-heat-controller.sh
# Description: Installe et configure Heat (Orchestration) sur le Controller
# A executer sur: controller UNIQUEMENT
# =============================================================================

set -e

echo "=========================================="
echo "Installation de Heat (Orchestration)"
echo "=========================================="

# Variables
MYSQL_ROOT_PASS="openstack_root_pwd"
HEAT_DB_PASS="heat_dbpass"
HEAT_PASS="heat_pass"
HEAT_DOMAIN_PASS="heat_domain_pass"
RABBITMQ_PASS="rabbit_openstack_pwd"

# Charger les credentials admin
source /root/admin-openrc

# =============================================================================
# 1. CREATION DE LA BASE DE DONNEES HEAT
# =============================================================================
echo "[1/6] Creation de la base de donnees Heat..."

mysql -u root -p${MYSQL_ROOT_PASS} << EOF
CREATE DATABASE IF NOT EXISTS heat;
GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'localhost' IDENTIFIED BY '${HEAT_DB_PASS}';
GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'%' IDENTIFIED BY '${HEAT_DB_PASS}';
FLUSH PRIVILEGES;
EOF

echo "Base de donnees Heat creee."

# =============================================================================
# 2. CREATION DE L'UTILISATEUR ET DU SERVICE HEAT
# =============================================================================
echo "[2/6] Creation de l'utilisateur Heat dans Keystone..."

openstack user create --domain default --password ${HEAT_PASS} heat
openstack role add --project service --user heat admin

# Creer les services Heat
openstack service create --name heat --description "Orchestration" orchestration
openstack service create --name heat-cfn --description "Orchestration" cloudformation

# Creer les endpoints pour orchestration
openstack endpoint create --region RegionOne orchestration public http://controller:8004/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne orchestration internal http://controller:8004/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne orchestration admin http://controller:8004/v1/%\(tenant_id\)s

# Creer les endpoints pour cloudformation
openstack endpoint create --region RegionOne cloudformation public http://controller:8000/v1
openstack endpoint create --region RegionOne cloudformation internal http://controller:8000/v1
openstack endpoint create --region RegionOne cloudformation admin http://controller:8000/v1

echo "Utilisateur et services Heat crees."

# =============================================================================
# 3. CREATION DU DOMAINE HEAT
# =============================================================================
echo "[3/6] Creation du domaine Heat..."

openstack domain create --description "Stack projects and users" heat
openstack user create --domain heat --password ${HEAT_DOMAIN_PASS} heat_domain_admin
openstack role add --domain heat --user-domain heat --user heat_domain_admin admin

# Creer le role heat_stack_owner
openstack role create heat_stack_owner
openstack role add --project admin --user admin heat_stack_owner

# Creer le role heat_stack_user
openstack role create heat_stack_user

echo "Domaine Heat configure."

# =============================================================================
# 4. INSTALLATION DE HEAT
# =============================================================================
echo "[4/6] Installation de Heat..."
apt install -y heat-api heat-api-cfn heat-engine

# =============================================================================
# 5. CONFIGURATION DE HEAT
# =============================================================================
echo "[5/6] Configuration de Heat..."

cat > /etc/heat/heat.conf << EOF
[DEFAULT]
transport_url = rabbit://openstack:${RABBITMQ_PASS}@controller
heat_metadata_server_url = http://controller:8000
heat_waitcondition_server_url = http://controller:8000/v1/waitcondition
stack_domain_admin = heat_domain_admin
stack_domain_admin_password = ${HEAT_DOMAIN_PASS}
stack_user_domain_name = heat

[database]
connection = mysql+pymysql://heat:${HEAT_DB_PASS}@controller/heat

[keystone_authtoken]
www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = heat
password = ${HEAT_PASS}

[trustee]
auth_type = password
auth_url = http://controller:5000
username = heat
password = ${HEAT_PASS}
user_domain_name = Default

[clients_keystone]
auth_uri = http://controller:5000

[oslo_concurrency]
lock_path = /var/lib/heat/tmp
EOF

# =============================================================================
# 6. SYNCHRONISATION ET DEMARRAGE
# =============================================================================
echo "[6/6] Synchronisation de la base de donnees..."

su -s /bin/sh -c "heat-manage db_sync" heat

systemctl restart heat-api heat-api-cfn heat-engine
systemctl enable heat-api heat-api-cfn heat-engine

echo "=========================================="
echo "Heat installe avec succes!"
echo ""
echo "Verification:"
echo "  source /root/admin-openrc"
echo "  openstack orchestration service list"
echo ""
echo "Exemple de template Heat:"
echo "  Voir /root/heat-templates/"
echo "=========================================="

# Creer un repertoire pour les templates Heat
mkdir -p /root/heat-templates

# Creer un template exemple
cat > /root/heat-templates/simple-instance.yaml << 'EOF'
heat_template_version: 2021-04-16

description: Simple template to deploy a single compute instance

parameters:
  image:
    type: string
    description: Image to use for the instance
    default: cirros
  flavor:
    type: string
    description: Flavor to use for the instance
    default: m1.tiny
  network:
    type: string
    description: Network to attach the instance to

resources:
  server:
    type: OS::Nova::Server
    properties:
      name: heat-instance
      image: { get_param: image }
      flavor: { get_param: flavor }
      networks:
        - network: { get_param: network }

outputs:
  server_ip:
    description: IP address of the instance
    value: { get_attr: [server, first_address] }
EOF

echo "Template exemple cree dans /root/heat-templates/"
