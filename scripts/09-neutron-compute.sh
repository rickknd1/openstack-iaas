#!/bin/bash
# =============================================================================
# Script: 09-neutron-compute.sh
# Description: Installe et configure Neutron sur le Compute Node
# A executer sur: compute UNIQUEMENT
# =============================================================================

set -e

echo "=========================================="
echo "Installation de Neutron - Compute Node"
echo "=========================================="

# Variables
NEUTRON_PASS="neutron_pass"
RABBITMQ_PASS="rabbit_openstack_pwd"
COMPUTE_IP="192.168.10.31"
PROVIDER_INTERFACE="ens33"

# =============================================================================
# 1. INSTALLATION DE NEUTRON
# =============================================================================
echo "[1/3] Installation de Neutron OVS Agent..."
apt install -y neutron-openvswitch-agent

# =============================================================================
# 2. CONFIGURATION DE NEUTRON
# =============================================================================
echo "[2/3] Configuration de Neutron..."

cat > /etc/neutron/neutron.conf << EOF
[DEFAULT]
transport_url = rabbit://openstack:${RABBITMQ_PASS}@controller
auth_strategy = keystone

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

[oslo_concurrency]
lock_path = /var/lib/neutron/tmp
EOF

# Configuration OVS Agent
cat > /etc/neutron/plugins/ml2/openvswitch_agent.ini << EOF
[ovs]
bridge_mappings = provider:br-provider
local_ip = ${COMPUTE_IP}

[agent]
tunnel_types = vxlan
l2_population = true

[securitygroup]
enable_security_group = true
firewall_driver = openvswitch
EOF

# =============================================================================
# 3. CONFIGURATION D'OPEN VSWITCH
# =============================================================================
echo "[3/3] Configuration d'Open vSwitch..."

systemctl start openvswitch-switch
systemctl enable openvswitch-switch

ovs-vsctl add-br br-provider 2>/dev/null || true
ovs-vsctl add-port br-provider ${PROVIDER_INTERFACE} 2>/dev/null || true

# Mettre a jour Nova pour utiliser Neutron
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
EOF

# Redemarrage des services
systemctl restart nova-compute
systemctl restart neutron-openvswitch-agent
systemctl enable neutron-openvswitch-agent

echo "=========================================="
echo "Neutron Compute installe avec succes!"
echo ""
echo "Verification sur le CONTROLLER:"
echo "  source /root/admin-openrc"
echo "  openstack network agent list"
echo "=========================================="
