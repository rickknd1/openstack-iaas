#!/bin/bash
# =============================================================================
# Script: 12-cinder-storage.sh
# Description: Installe et configure Cinder Volume sur le Storage Node
# A executer sur: storage UNIQUEMENT
# =============================================================================

set -e

echo "=========================================="
echo "Installation de Cinder Volume - Storage Node"
echo "=========================================="

# Variables
CINDER_PASS="cinder_pass"
RABBITMQ_PASS="rabbit_openstack_pwd"
STORAGE_IP="192.168.10.41"

# =============================================================================
# 1. INSTALLATION DES PAQUETS
# =============================================================================
echo "[1/4] Installation de LVM et Cinder Volume..."
apt install -y lvm2 thin-provisioning-tools cinder-volume

# =============================================================================
# 2. CREATION DU VOLUME GROUP POUR CINDER
# =============================================================================
echo "[2/4] Configuration de LVM..."

# Creer un volume physique sur /dev/sdb (adapter selon votre configuration)
# Si vous n'avez pas de disque supplementaire, creez un fichier loop:

# Option 1: Utiliser un fichier loop (pour le lab)
if [ ! -b /dev/sdb ]; then
    echo "Creation d'un volume loop pour le lab..."
    mkdir -p /var/lib/cinder
    dd if=/dev/zero of=/var/lib/cinder/cinder-volumes.img bs=1M count=10240
    LOOP_DEVICE=$(losetup -f)
    losetup ${LOOP_DEVICE} /var/lib/cinder/cinder-volumes.img
    pvcreate ${LOOP_DEVICE}
    vgcreate cinder-volumes ${LOOP_DEVICE}

    # Ajouter au demarrage
    cat > /etc/systemd/system/cinder-loop.service << EOFSERVICE
[Unit]
Description=Setup Cinder Loop Device
Before=cinder-volume.service

[Service]
Type=oneshot
ExecStart=/sbin/losetup ${LOOP_DEVICE} /var/lib/cinder/cinder-volumes.img
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOFSERVICE
    systemctl enable cinder-loop.service
else
    # Option 2: Utiliser un disque reel
    pvcreate /dev/sdb
    vgcreate cinder-volumes /dev/sdb
fi

# Configurer LVM pour scanner uniquement les volumes Cinder
cat >> /etc/lvm/lvm.conf << 'EOF'
devices {
    filter = [ "a/sda/", "a/sdb/", "a/loop.*/", "r/.*/" ]
}
EOF

# =============================================================================
# 3. CONFIGURATION DE CINDER VOLUME
# =============================================================================
echo "[3/4] Configuration de Cinder Volume..."

cat > /etc/cinder/cinder.conf << EOF
[DEFAULT]
transport_url = rabbit://openstack:${RABBITMQ_PASS}@controller
auth_strategy = keystone
my_ip = ${STORAGE_IP}
enabled_backends = lvm
glance_api_servers = http://controller:9292

[database]
connection = mysql+pymysql://cinder:cinder_dbpass@controller/cinder

[keystone_authtoken]
www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = cinder
password = ${CINDER_PASS}

[lvm]
volume_driver = cinder.volume.drivers.lvm.LVMVolumeDriver
volume_group = cinder-volumes
target_protocol = iscsi
target_helper = tgtadm

[oslo_concurrency]
lock_path = /var/lib/cinder/tmp
EOF

# =============================================================================
# 4. DEMARRAGE DES SERVICES
# =============================================================================
echo "[4/4] Demarrage des services..."

# Installer tgt pour iSCSI
apt install -y tgt

systemctl restart tgt
systemctl restart cinder-volume

systemctl enable tgt cinder-volume

echo "=========================================="
echo "Cinder Volume installe avec succes!"
echo ""
echo "Verification sur le CONTROLLER:"
echo "  source /root/admin-openrc"
echo "  openstack volume service list"
echo "=========================================="
