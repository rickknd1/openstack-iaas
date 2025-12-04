#!/bin/bash
# =============================================================================
# Script: fix-horizon-v2.sh
# Description: Fix complet Horizon + Memcached
# A executer sur: CONTROLLER
# =============================================================================

set -e

echo "=========================================="
echo "Fix Horizon v2 - Complete"
echo "=========================================="

# 1. Forcer memcached a ecouter sur 127.0.0.1
cat > /etc/memcached.conf << 'EOF'
-d
logfile /var/log/memcached.log
-m 64
-p 11211
-u memcache
-l 127.0.0.1
-c 1024
EOF

systemctl restart memcached
sleep 2

# 2. Verifier memcached
echo "Memcached ecoute sur:"
ss -tlnp | grep 11211

# 3. Corriger Horizon local_settings.py
HORIZON_CONF="/etc/openstack-dashboard/local_settings.py"

# Backup
cp $HORIZON_CONF ${HORIZON_CONF}.bak

# Remplacer CACHES configuration
python3 << 'PYEOF'
import re

conf_file = "/etc/openstack-dashboard/local_settings.py"
with open(conf_file, 'r') as f:
    content = f.read()

# Pattern pour remplacer la config CACHES
new_caches = '''CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.memcached.PyMemcacheCache',
        'LOCATION': '127.0.0.1:11211',
    },
}'''

# Chercher et remplacer CACHES
if 'CACHES' in content:
    # Supprimer l'ancienne config CACHES (multi-lignes)
    content = re.sub(r'CACHES\s*=\s*\{[^}]+\{[^}]+\}[^}]+\}', new_caches, content, flags=re.DOTALL)

with open(conf_file, 'w') as f:
    f.write(content)

print("Config CACHES mise a jour")
PYEOF

# 4. Verifier SESSION_ENGINE
grep -q "SESSION_ENGINE" $HORIZON_CONF || echo "SESSION_ENGINE = 'django.contrib.sessions.backends.cache'" >> $HORIZON_CONF

# 5. Redemarrer Apache
systemctl restart apache2
sleep 3

# 6. Test de connexion memcached
echo ""
echo "Test connexion memcached:"
python3 -c "
import socket
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
try:
    s.connect(('127.0.0.1', 11211))
    print('OK - Connexion reussie')
except Exception as e:
    print(f'ERREUR - {e}')
finally:
    s.close()
"

echo ""
echo "Status services:"
systemctl is-active memcached
systemctl is-active apache2

echo "=========================================="
echo "Fix termine! Testez http://192.168.43.11/horizon"
echo "=========================================="
