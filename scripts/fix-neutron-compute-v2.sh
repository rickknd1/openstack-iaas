#!/bin/bash
# =============================================================================
# Script: fix-neutron-compute-v2.sh
# Description: Corrige les permissions sudo pour neutron sur compute
# A executer sur: COMPUTE
# =============================================================================

set -e

echo "=========================================="
echo "Fix Neutron Compute v2 - Permissions"
echo "=========================================="

# 1. Ajouter neutron au sudoers
cat > /etc/sudoers.d/neutron << 'EOF'
neutron ALL=(ALL) NOPASSWD: ALL
Defaults:neutron !requiretty
EOF
chmod 440 /etc/sudoers.d/neutron

# 2. Creer les repertoires avec bonnes permissions
mkdir -p /var/lock/neutron
mkdir -p /var/log/neutron
mkdir -p /var/lib/neutron/tmp
mkdir -p /var/lib/neutron/ovs
chown -R neutron:neutron /var/lock/neutron
chown -R neutron:neutron /var/log/neutron
chown -R neutron:neutron /var/lib/neutron
chmod 755 /var/lib/neutron

# 3. Module br_netfilter
modprobe br_netfilter 2>/dev/null || true
echo "br_netfilter" > /etc/modules-load.d/neutron.conf

# 4. Reset des services
systemctl daemon-reload
systemctl reset-failed neutron-ovs-cleanup 2>/dev/null || true
systemctl reset-failed neutron-openvswitch-agent 2>/dev/null || true

# 5. Restart OVS
systemctl restart openvswitch-switch
sleep 2

# 6. Verifier bridge
ovs-vsctl --may-exist add-br br-provider
ovs-vsctl --may-exist add-port br-provider ens34

# 7. Demarrer les services
systemctl start neutron-ovs-cleanup
sleep 1
systemctl restart neutron-openvswitch-agent
systemctl enable neutron-openvswitch-agent

# 8. Verifier
sleep 2
echo ""
echo "Status des services:"
systemctl status neutron-openvswitch-agent --no-pager -l

echo "=========================================="
echo "Fix termine!"
echo "=========================================="
