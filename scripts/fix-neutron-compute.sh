#!/bin/bash
# =============================================================================
# Script: fix-neutron-compute.sh
# Description: Corrige le probleme neutron-openvswitch-agent sur compute
# A executer sur: COMPUTE
# =============================================================================

set -e

echo "=========================================="
echo "Fix Neutron Compute"
echo "=========================================="

# 1. Creer les repertoires manquants
mkdir -p /var/lock/neutron
mkdir -p /var/log/neutron
mkdir -p /var/lib/neutron/tmp
chown -R neutron:neutron /var/lock/neutron
chown -R neutron:neutron /var/log/neutron
chown -R neutron:neutron /var/lib/neutron

# 2. Charger le module br_netfilter
modprobe br_netfilter
echo "br_netfilter" >> /etc/modules-load.d/neutron.conf

# 3. Fix neutron-ovs-cleanup
systemctl stop neutron-ovs-cleanup 2>/dev/null || true
systemctl reset-failed neutron-ovs-cleanup 2>/dev/null || true

# 4. Demarrer OVS proprement
systemctl restart openvswitch-switch
sleep 2

# 5. Verifier/creer le bridge
ovs-vsctl --may-exist add-br br-provider
ovs-vsctl --may-exist add-port br-provider ens34

# 6. Demarrer neutron-ovs-cleanup
systemctl start neutron-ovs-cleanup || true

# 7. Demarrer l'agent
systemctl restart neutron-openvswitch-agent
systemctl enable neutron-openvswitch-agent

# 8. Verifier
sleep 2
systemctl status neutron-openvswitch-agent --no-pager

echo "=========================================="
echo "Fix termine!"
echo "=========================================="
