#!/bin/bash
# =============================================================================
# Script: 07-nova-compute.sh
# Description: Installe et configure Nova Compute
# A executer sur: compute UNIQUEMENT
# Prerequis: Prerequisites + Nova Controller configure
# =============================================================================

set -e

echo "=========================================="
echo "Installation de Nova Compute"
echo "=========================================="

# Variables
NOVA_PASS="nova_pass"
PLACEMENT_PASS="placement_pass"
RABBITMQ_PASS="rabbit_openstack_pwd"
COMPUTE_IP="10.0.0.31"
CONTROLLER_IP="10.0.0.11"

# =============================================================================
# 1. INSTALLATION DE NOVA COMPUTE
# =============================================================================
echo "[1/4] Installation de Nova Compute..."
apt install -y nova-compute

# =============================================================================
# 2. CONFIGURATION DE NOVA COMPUTE
# =============================================================================
echo "[2/4] Configuration de Nova Compute..."

cat > /etc/nova/nova.conf << EOF
[DEFAULT]
log_dir = /var/log/nova
lock_path = /var/lock/nova
state_path = /var/lib/nova
transport_url = rabbit://openstack:${RABBITMQ_PASS}@controller
my_ip = ${COMPUTE_IP}

[api]
auth_strategy = keystone

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
server_listen = 0.0.0.0
server_proxyclient_address = \$my_ip
novncproxy_base_url = http://${CONTROLLER_IP}:6080/vnc_auto.html

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
EOF

# =============================================================================
# 3. CONFIGURATION DE L'HYPERVISEUR KVM
# =============================================================================
echo "[3/4] Configuration de l'hyperviseur..."

# Verifier si la virtualisation materielle est supportee
if egrep -c '(vmx|svm)' /proc/cpuinfo > /dev/null; then
    echo "Virtualisation materielle supportee - utilisation de KVM"
    VIRT_TYPE="kvm"
else
    echo "Pas de virtualisation materielle - utilisation de QEMU"
    VIRT_TYPE="qemu"
fi

cat > /etc/nova/nova-compute.conf << EOF
[DEFAULT]
compute_driver = libvirt.LibvirtDriver

[libvirt]
virt_type = ${VIRT_TYPE}
EOF

# =============================================================================
# 4. DEMARRAGE DU SERVICE
# =============================================================================
echo "[4/4] Demarrage du service Nova Compute..."

systemctl restart nova-compute
systemctl enable nova-compute

echo "=========================================="
echo "Nova Compute installe avec succes!"
echo ""
echo "IMPORTANT: Sur le CONTROLLER, executez:"
echo "  source /root/admin-openrc"
echo "  openstack compute service list --service nova-compute"
echo "  su -s /bin/sh -c 'nova-manage cell_v2 discover_hosts --verbose' nova"
echo "=========================================="
