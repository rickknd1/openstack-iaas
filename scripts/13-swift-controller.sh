#!/bin/bash
# =============================================================================
# Script: 13-swift-controller.sh
# Description: Installe et configure Swift Proxy sur le Controller
# A executer sur: controller UNIQUEMENT
# =============================================================================

set -e

echo "=========================================="
echo "Installation de Swift Proxy - Controller"
echo "=========================================="

# Variables
SWIFT_PASS="swift_pass"

# Charger les credentials admin
source /root/admin-openrc

# =============================================================================
# 1. CREATION DE L'UTILISATEUR ET DU SERVICE SWIFT
# =============================================================================
echo "[1/4] Creation de l'utilisateur Swift dans Keystone..."

openstack user create --domain default --password ${SWIFT_PASS} swift
openstack role add --project service --user swift admin
openstack service create --name swift --description "OpenStack Object Storage" object-store

openstack endpoint create --region RegionOne object-store public http://controller:8080/v1/AUTH_%\(project_id\)s
openstack endpoint create --region RegionOne object-store internal http://controller:8080/v1/AUTH_%\(project_id\)s
openstack endpoint create --region RegionOne object-store admin http://controller:8080/v1

echo "Utilisateur et service Swift crees."

# =============================================================================
# 2. INSTALLATION DE SWIFT PROXY
# =============================================================================
echo "[2/4] Installation de Swift Proxy..."
apt install -y swift swift-proxy python3-swiftclient python3-keystoneclient python3-keystonemiddleware

# =============================================================================
# 3. CONFIGURATION DE SWIFT PROXY
# =============================================================================
echo "[3/4] Configuration de Swift Proxy..."

mkdir -p /etc/swift

cat > /etc/swift/proxy-server.conf << EOF
[DEFAULT]
bind_ip = 0.0.0.0
bind_port = 8080
workers = auto
user = swift

[pipeline:main]
pipeline = catch_errors gatekeeper healthcheck proxy-logging cache container_sync bulk ratelimit authtoken keystoneauth container-quotas account-quotas slo dlo versioned_writes proxy-logging proxy-server

[app:proxy-server]
use = egg:swift#proxy
account_autocreate = True

[filter:keystoneauth]
use = egg:swift#keystoneauth
operator_roles = admin,member

[filter:authtoken]
paste.filter_factory = keystonemiddleware.auth_token:filter_factory
www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = swift
password = ${SWIFT_PASS}
delay_auth_decision = True

[filter:cache]
use = egg:swift#memcache
memcache_servers = controller:11211

[filter:catch_errors]
use = egg:swift#catch_errors

[filter:gatekeeper]
use = egg:swift#gatekeeper

[filter:healthcheck]
use = egg:swift#healthcheck

[filter:proxy-logging]
use = egg:swift#proxy_logging

[filter:container_sync]
use = egg:swift#container_sync

[filter:bulk]
use = egg:swift#bulk

[filter:ratelimit]
use = egg:swift#ratelimit

[filter:container-quotas]
use = egg:swift#container_quotas

[filter:account-quotas]
use = egg:swift#account_quotas

[filter:slo]
use = egg:swift#slo

[filter:dlo]
use = egg:swift#dlo

[filter:versioned_writes]
use = egg:swift#versioned_writes
EOF

# =============================================================================
# 4. CREATION DU RING SWIFT (sera complete apres configuration du storage)
# =============================================================================
echo "[4/4] Preparation des rings Swift..."

cd /etc/swift

# Creer les ring builders
swift-ring-builder account.builder create 10 1 1
swift-ring-builder container.builder create 10 1 1
swift-ring-builder object.builder create 10 1 1

echo "=========================================="
echo "Swift Proxy installe!"
echo ""
echo "IMPORTANT: Executez maintenant le script"
echo "14-swift-storage.sh sur le node STORAGE"
echo "puis revenez executer 15-swift-finalize.sh"
echo "=========================================="
