#!/bin/bash
# =============================================================================
# Script: 02-swift-storage2.sh
# Description: Installe et configure Swift Storage sur Storage2
# A executer sur: storage2 (192.168.100.150) - TOI
# =============================================================================

set -e

echo "=========================================="
echo "Installation de Swift Storage - Storage2"
echo "=========================================="

# Variables - TON IP
STORAGE_IP="192.168.100.150"

# =============================================================================
# 1. INSTALLATION DES PAQUETS
# =============================================================================
echo "[1/5] Installation des paquets Swift Storage..."
apt update
apt install -y xfsprogs rsync swift swift-account swift-container swift-object

# =============================================================================
# 2. PREPARATION DU STOCKAGE
# =============================================================================
echo "[2/5] Preparation du stockage..."

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
    echo "Creation d'un stockage loop pour Swift (20GB)..."
    # Creer un fichier de 20Go pour Swift
    if [ ! -f /var/lib/swift/swift-storage.img ]; then
        dd if=/dev/zero of=/var/lib/swift/swift-storage.img bs=1M count=20480
    fi

    LOOP_DEVICE=$(losetup -f)
    losetup ${LOOP_DEVICE} /var/lib/swift/swift-storage.img
    mkfs.xfs -f ${LOOP_DEVICE}
    mount ${LOOP_DEVICE} /srv/node/sdc

    # Script pour remount au boot
    cat > /etc/rc.local << 'RCEOF'
#!/bin/bash
LOOP_DEVICE=$(losetup -f)
losetup ${LOOP_DEVICE} /var/lib/swift/swift-storage.img
mount ${LOOP_DEVICE} /srv/node/sdc
exit 0
RCEOF
    chmod +x /etc/rc.local
fi

chown -R swift:swift /srv/node

# =============================================================================
# 3. CONFIGURATION DE RSYNC
# =============================================================================
echo "[3/5] Configuration de rsync..."

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
echo "[4/5] Configuration des services Swift..."

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

# =============================================================================
# 5. CONFIGURATION SSH POUR LE CONTROLLER
# =============================================================================
echo "[5/5] Preparation de l'acces SSH..."

# S'assurer que SSH est actif
systemctl enable ssh
systemctl start ssh

echo "=========================================="
echo "Swift Storage2 configure!"
echo ""
echo "TON IP: ${STORAGE_IP}"
echo "Ports ouverts: 6200, 6201, 6202"
echo ""
echo "PROCHAINE ETAPE:"
echo "  Dis a AMENI (controller) d'executer:"
echo "  03-add-storage2-to-rings.sh"
echo ""
echo "  Puis toi, execute:"
echo "  04-start-swift-services.sh"
echo "=========================================="
