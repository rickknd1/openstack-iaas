#!/bin/bash
# =============================================================================
# Script: 14-swift-storage.sh
# Description: Installe et configure Swift Storage sur le Storage Node
# A executer sur: storage UNIQUEMENT
# =============================================================================

set -e

echo "=========================================="
echo "Installation de Swift Storage - Storage Node"
echo "=========================================="

# Variables
STORAGE_IP="192.168.10.41"

# =============================================================================
# 1. INSTALLATION DES PAQUETS
# =============================================================================
echo "[1/4] Installation de Swift Storage..."
apt install -y xfsprogs rsync swift swift-account swift-container swift-object

# =============================================================================
# 2. PREPARATION DU STOCKAGE
# =============================================================================
echo "[2/4] Preparation du stockage..."

# Creer un repertoire de stockage si pas de disque dedie
if [ ! -b /dev/sdc ]; then
    echo "Creation d'un stockage loop pour Swift..."
    mkdir -p /srv/node/sdc
    mkdir -p /var/lib/swift

    # Creer un fichier de 20Go pour Swift
    dd if=/dev/zero of=/var/lib/swift/swift-storage.img bs=1M count=20480

    LOOP_DEVICE=$(losetup -f)
    losetup ${LOOP_DEVICE} /var/lib/swift/swift-storage.img
    mkfs.xfs ${LOOP_DEVICE}
    mount ${LOOP_DEVICE} /srv/node/sdc

    # Ajouter au fstab
    echo "${LOOP_DEVICE} /srv/node/sdc xfs noatime,nodiratime,logbufs=8 0 2" >> /etc/fstab
else
    # Utiliser un disque reel
    mkfs.xfs /dev/sdc
    mkdir -p /srv/node/sdc
    mount /dev/sdc /srv/node/sdc
    echo "/dev/sdc /srv/node/sdc xfs noatime,nodiratime,logbufs=8 0 2" >> /etc/fstab
fi

chown -R swift:swift /srv/node

# =============================================================================
# 3. CONFIGURATION DE RSYNC
# =============================================================================
echo "[3/4] Configuration de rsync..."

cat > /etc/rsyncd.conf << EOF
uid = swift
gid = swift
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid
address = ${STORAGE_IP}

[account]
max connections = 2
path = /srv/node/
read only = False
lock file = /var/lock/account.lock

[container]
max connections = 2
path = /srv/node/
read only = False
lock file = /var/lock/container.lock

[object]
max connections = 2
path = /srv/node/
read only = False
lock file = /var/lock/object.lock
EOF

# Activer rsync
sed -i 's/RSYNC_ENABLE=false/RSYNC_ENABLE=true/' /etc/default/rsync
systemctl restart rsync
systemctl enable rsync

# =============================================================================
# 4. CONFIGURATION DES SERVICES SWIFT
# =============================================================================
echo "[4/4] Configuration des services Swift..."

mkdir -p /etc/swift

# Account Server
cat > /etc/swift/account-server.conf << EOF
[DEFAULT]
bind_ip = ${STORAGE_IP}
bind_port = 6202
user = swift
swift_dir = /etc/swift
devices = /srv/node
mount_check = True

[pipeline:main]
pipeline = healthcheck recon account-server

[app:account-server]
use = egg:swift#account

[filter:healthcheck]
use = egg:swift#healthcheck

[filter:recon]
use = egg:swift#recon
recon_cache_path = /var/cache/swift
EOF

# Container Server
cat > /etc/swift/container-server.conf << EOF
[DEFAULT]
bind_ip = ${STORAGE_IP}
bind_port = 6201
user = swift
swift_dir = /etc/swift
devices = /srv/node
mount_check = True

[pipeline:main]
pipeline = healthcheck recon container-server

[app:container-server]
use = egg:swift#container

[filter:healthcheck]
use = egg:swift#healthcheck

[filter:recon]
use = egg:swift#recon
recon_cache_path = /var/cache/swift
EOF

# Object Server
cat > /etc/swift/object-server.conf << EOF
[DEFAULT]
bind_ip = ${STORAGE_IP}
bind_port = 6200
user = swift
swift_dir = /etc/swift
devices = /srv/node
mount_check = True

[pipeline:main]
pipeline = healthcheck recon object-server

[app:object-server]
use = egg:swift#object

[filter:healthcheck]
use = egg:swift#healthcheck

[filter:recon]
use = egg:swift#recon
recon_cache_path = /var/cache/swift
EOF

# Creer les repertoires de cache
mkdir -p /var/cache/swift
chown -R swift:swift /var/cache/swift

echo "=========================================="
echo "Swift Storage configure!"
echo ""
echo "IMPORTANT: Retournez sur le CONTROLLER"
echo "et executez 15-swift-finalize.sh"
echo "=========================================="
