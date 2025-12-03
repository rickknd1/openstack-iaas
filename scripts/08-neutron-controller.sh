#!/bin/bash
# =============================================================================
# Script: 08-neutron-controller.sh
# Description: Installe et configure Neutron sur le Controller
# A executer sur: controller UNIQUEMENT
# Prerequis: Nova Controller configure
# =============================================================================

set -e

echo "=========================================="
echo "Installation de Neutron - Controller"
echo "(Provider Networks + Self-service Networks)"
echo "=========================================="

# Variables
MYSQL_ROOT_PASS="openstack_root_pwd"
NEUTRON_DB_PASS="neutron_dbpass"
NEUTRON_PASS="neutron_pass"
NOVA_PASS="nova_pass"
RABBITMQ_PASS="rabbit_openstack_pwd"
METADATA_SECRET="metadata_secret_key"
CONTROLLER_IP="10.0.0.11"
PROVIDER_INTERFACE="ens34"  # Interface reseau externe

# Charger les credentials admin
source /root/admin-openrc

# =============================================================================
# 1. CREATION DE LA BASE DE DONNEES NEUTRON
# =============================================================================
echo "[1/7] Creation de la base de donnees Neutron..."

mysql -u root -p${MYSQL_ROOT_PASS} << EOF
CREATE DATABASE IF NOT EXISTS neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '${NEUTRON_DB_PASS}';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '${NEUTRON_DB_PASS}';
FLUSH PRIVILEGES;
EOF

echo "Base de donnees Neutron creee."

# =============================================================================
# 2. CREATION DE L'UTILISATEUR ET DU SERVICE NEUTRON
# =============================================================================
echo "[2/7] Creation de l'utilisateur Neutron dans Keystone..."

openstack user create --domain default --password ${NEUTRON_PASS} neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron --description "OpenStack Networking" network

openstack endpoint create --region RegionOne network public http://controller:9696
openstack endpoint create --region RegionOne network internal http://controller:9696
openstack endpoint create --region RegionOne network admin http://controller:9696

echo "Utilisateur et service Neutron crees."

# =============================================================================
# 3. INSTALLATION DE NEUTRON
# =============================================================================
echo "[3/7] Installation de Neutron..."
apt install -y neutron-server neutron-plugin-ml2 \
    neutron-openvswitch-agent neutron-l3-agent \
    neutron-dhcp-agent neutron-metadata-agent

# =============================================================================
# 4. CONFIGURATION DE NEUTRON SERVER
# =============================================================================
echo "[4/7] Configuration de Neutron Server..."

cat > /etc/neutron/neutron.conf << EOF
[DEFAULT]
core_plugin = ml2
service_plugins = router
transport_url = rabbit://openstack:${RABBITMQ_PASS}@controller
auth_strategy = keystone
notify_nova_on_port_status_changes = true
notify_nova_on_port_data_changes = true

[database]
connection = mysql+pymysql://neutron:${NEUTRON_DB_PASS}@controller/neutron

[keystone_authtoken]
www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = neutron
password = ${NEUTRON_PASS}

[nova]
auth_url = http://controller:5000
auth_type = password
project_domain_name = Default
user_domain_name = Default
region_name = RegionOne
project_name = service
username = nova
password = ${NOVA_PASS}

[oslo_concurrency]
lock_path = /var/lib/neutron/tmp
EOF

# =============================================================================
# 5. CONFIGURATION DU PLUGIN ML2
# =============================================================================
echo "[5/7] Configuration du plugin ML2..."

cat > /etc/neutron/plugins/ml2/ml2_conf.ini << EOF
[ml2]
type_drivers = flat,vlan,vxlan
tenant_network_types = vxlan
mechanism_drivers = openvswitch,l2population
extension_drivers = port_security

[ml2_type_flat]
flat_networks = provider

[ml2_type_vxlan]
vni_ranges = 1:1000

[securitygroup]
enable_ipset = true
EOF

# =============================================================================
# 6. CONFIGURATION DES AGENTS
# =============================================================================
echo "[6/7] Configuration des agents Neutron..."

# Open vSwitch Agent
cat > /etc/neutron/plugins/ml2/openvswitch_agent.ini << EOF
[ovs]
bridge_mappings = provider:br-provider
local_ip = ${CONTROLLER_IP}

[agent]
tunnel_types = vxlan
l2_population = true

[securitygroup]
enable_security_group = true
firewall_driver = openvswitch
EOF

# L3 Agent
cat > /etc/neutron/l3_agent.ini << EOF
[DEFAULT]
interface_driver = openvswitch
EOF

# DHCP Agent
cat > /etc/neutron/dhcp_agent.ini << EOF
[DEFAULT]
interface_driver = openvswitch
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
enable_isolated_metadata = true
EOF

# Metadata Agent
cat > /etc/neutron/metadata_agent.ini << EOF
[DEFAULT]
nova_metadata_host = controller
metadata_proxy_shared_secret = ${METADATA_SECRET}
EOF

# =============================================================================
# 7. CONFIGURATION D'OPEN VSWITCH
# =============================================================================
echo "[7/7] Configuration d'Open vSwitch..."

# Demarrer OVS
systemctl start openvswitch-switch
systemctl enable openvswitch-switch

# Creer le bridge provider
ovs-vsctl add-br br-provider 2>/dev/null || true
ovs-vsctl add-port br-provider ${PROVIDER_INTERFACE} 2>/dev/null || true

# Mettre a jour la configuration Nova pour Neutron
cat >> /etc/nova/nova.conf << EOF

[neutron]
auth_url = http://controller:5000
auth_type = password
project_domain_name = Default
user_domain_name = Default
region_name = RegionOne
project_name = service
username = neutron
password = ${NEUTRON_PASS}
service_metadata_proxy = true
metadata_proxy_shared_secret = ${METADATA_SECRET}
EOF

# Synchronisation de la base de donnees
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

# Redemarrage des services
systemctl restart nova-api
systemctl restart neutron-server
systemctl restart neutron-openvswitch-agent
systemctl restart neutron-dhcp-agent
systemctl restart neutron-metadata-agent
systemctl restart neutron-l3-agent

systemctl enable neutron-server neutron-openvswitch-agent \
    neutron-dhcp-agent neutron-metadata-agent neutron-l3-agent

echo "=========================================="
echo "Neutron Controller installe avec succes!"
echo ""
echo "Verification:"
echo "  source /root/admin-openrc"
echo "  openstack network agent list"
echo ""
echo "IMPORTANT: Executez maintenant le script"
echo "09-neutron-compute.sh sur le node COMPUTE"
echo "=========================================="
