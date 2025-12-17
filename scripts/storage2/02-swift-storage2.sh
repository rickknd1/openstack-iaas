#!/bin/bash
# =============================================================================
# Script: 02-swift-storage2.sh
# Description: Installe et configure Swift Storage
# A executer sur: Storage2 (192.168.100.155)
# =============================================================================

set -e

echo "=========================================="
echo "Installation de Swift Storage - Storage2"
echo "=========================================="

# Variables - IP locale de la VM (NAT)
# Les collegues accedent via 192.168.100.155 (PC Windows) qui redirige ici
STORAGE_IP="192.168.43.28"

# =============================================================================
# 1. INSTALLATION DES PAQUETS
# =============================================================================
echo "[1/4] Installation des paquets Swift..."
apt update
apt install -y xfsprogs rsync swift swift-account swift-container swift-object

# =============================================================================
# 2. PREPARATION DU STOCKAGE
# =============================================================================
echo "[2/4] Preparation du stockage..."

mkdir -p /srv/node/sdc
mkdir -p /var/lib/swift

# Verifier si un disque dedie existe
if [ -b /dev/sdb ] && [ ! "$(mount | grep /dev/sdb)" ]; then
    echo "Utilisation du disque /dev/sdb..."
    mkfs.xfs -f /dev/sdb
    mount /dev/sdb /srv/node/sdc
    echo "/dev/sdb /srv/node/sdc xfs noatime,nodiratime,logbufs=8 0 2" >> /etc/fstab
elif [ -b /dev/sdc ] && [ ! "$(mount | grep /dev/sdc)" ]; then
    echo "Utilisation du disque /dev/sdc..."
    mkfs.xfs -f /dev/sdc
    mount /dev/sdc /srv/node/sdc
    echo "/dev/sdc /srv/node/sdc xfs noatime,nodiratime,logbufs=8 0 2" >> /etc/fstab
else
    echo "Creation d'un stockage loop pour Swift (10GB)..."
    if [ ! -f /var/lib/swift/swift-storage.img ]; then
        dd if=/dev/zero of=/var/lib/swift/swift-storage.img bs=1M count=10240
    fi

    LOOP_DEVICE=$(losetup -f)
    losetup ${LOOP_DEVICE} /var/lib/swift/swift-storage.img
    mkfs.xfs -f ${LOOP_DEVICE}
    mount ${LOOP_DEVICE} /srv/node/sdc

    # Service pour remount au boot
    cat > /etc/systemd/system/swift-loop.service << 'SVCEOF'
[Unit]
Description=Setup Swift loop device
Before=swift-account.service swift-container.service swift-object.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'losetup /dev/loop0 /var/lib/swift/swift-storage.img && mount /dev/loop0 /srv/node/sdc'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SVCEOF
    systemctl enable swift-loop.service
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

mkdir -p /var/cache/swift
chown -R swift:swift /var/cache/swift

echo "=========================================="
echo "Swift Storage2 installe!"
echo ""
echo "IP locale (bind): ${STORAGE_IP}"
echo "IP visible (collegues): 192.168.100.155"
echo "Ports: 6200 (object), 6201 (container), 6202 (account)"
echo ""
echo "IMPORTANT: Assure-toi que le port forwarding Windows est configure!"
echo ""
echo "PROCHAINE ETAPE:"
echo "  Dis a AMENI d'executer sur le CONTROLLER:"
echo "  bash 03-controller-add-storage2.sh"
echo ""
echo "  Elle utilisera l'IP: 192.168.100.155"
echo "  Puis elle t'enverra les fichiers ring."
echo "=========================================="
