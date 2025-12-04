#!/bin/bash
# =============================================================================
# Script: fix-horizon.sh
# Description: Corrige le probleme de connexion memcached pour Horizon
# A executer sur: CONTROLLER
# =============================================================================

set -e

echo "=========================================="
echo "Fix Horizon - Memcached Connection"
echo "=========================================="

# 1. Reconfigurer memcached pour ecouter sur toutes les interfaces
sed -i 's/-l 127.0.0.1/-l 0.0.0.0/' /etc/memcached.conf
sed -i 's/-l localhost/-l 0.0.0.0/' /etc/memcached.conf

# 2. Redemarrer memcached
systemctl restart memcached
sleep 2

# 3. Verifier que memcached ecoute
echo "Verification memcached:"
ss -tlnp | grep 11211

# 4. Corriger la config Horizon pour utiliser 127.0.0.1 au lieu de controller
if [ -f /etc/openstack-dashboard/local_settings.py ]; then
    sed -i "s/'controller:11211'/'127.0.0.1:11211'/g" /etc/openstack-dashboard/local_settings.py
    sed -i "s/\"controller:11211\"/\"127.0.0.1:11211\"/g" /etc/openstack-dashboard/local_settings.py
fi

# 5. Redemarrer Apache
systemctl restart apache2
sleep 2

# 6. Verifier
echo ""
echo "Status Apache:"
systemctl status apache2 --no-pager | head -5

echo ""
echo "Status Memcached:"
systemctl status memcached --no-pager | head -5

echo "=========================================="
echo "Fix termine!"
echo "Testez: http://192.168.43.11/horizon"
echo "=========================================="
