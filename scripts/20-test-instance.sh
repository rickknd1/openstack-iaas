#!/bin/bash
# =============================================================================
# Script: 20-test-instance.sh
# Description: Lance une instance de test pour valider l'installation
# A executer sur: controller UNIQUEMENT
# Prerequis: Tous les services OpenStack installes
# =============================================================================

set -e

echo "=========================================="
echo "Test de l'installation OpenStack"
echo "=========================================="

# Charger les credentials admin
source /root/admin-openrc

# =============================================================================
# 1. TELECHARGER UNE IMAGE CIRROS
# =============================================================================
echo "[1/5] Telechargement de l'image CirrOS..."

if ! openstack image show cirros &>/dev/null; then
    wget -q http://download.cirros-cloud.net/0.6.2/cirros-0.6.2-x86_64-disk.img -O /tmp/cirros.img
    openstack image create "cirros" \
        --file /tmp/cirros.img \
        --disk-format qcow2 \
        --container-format bare \
        --public
    rm /tmp/cirros.img
    echo "Image CirrOS telechargee."
else
    echo "Image CirrOS deja presente."
fi

# =============================================================================
# 2. CREER LES FLAVORS
# =============================================================================
echo "[2/5] Creation des flavors..."

openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano 2>/dev/null || true
openstack flavor create --id 1 --vcpus 1 --ram 512 --disk 1 m1.tiny 2>/dev/null || true
openstack flavor create --id 2 --vcpus 1 --ram 1024 --disk 10 m1.small 2>/dev/null || true
openstack flavor create --id 3 --vcpus 2 --ram 2048 --disk 20 m1.medium 2>/dev/null || true
openstack flavor create --id 4 --vcpus 4 --ram 4096 --disk 40 m1.large 2>/dev/null || true

echo "Flavors crees."

# =============================================================================
# 3. CREER UNE PAIRE DE CLES SSH
# =============================================================================
echo "[3/5] Creation de la keypair..."

if ! openstack keypair show mykey &>/dev/null; then
    ssh-keygen -q -N "" -f ~/.ssh/mykey 2>/dev/null || true
    openstack keypair create --public-key ~/.ssh/mykey.pub mykey
    echo "Keypair 'mykey' creee."
else
    echo "Keypair 'mykey' deja presente."
fi

# =============================================================================
# 4. LANCER UNE INSTANCE DE TEST
# =============================================================================
echo "[4/5] Lancement de l'instance de test..."

# Verifier si le reseau selfservice existe
if openstack network show selfservice &>/dev/null; then
    NETWORK="selfservice"
else
    NETWORK="provider"
fi

if ! openstack server show test-instance &>/dev/null; then
    openstack server create --flavor m1.tiny \
        --image cirros \
        --key-name mykey \
        --network ${NETWORK} \
        test-instance

    echo "Instance 'test-instance' en cours de creation..."

    # Attendre que l'instance soit active
    echo "Attente du demarrage (60 secondes max)..."
    for i in {1..12}; do
        STATUS=$(openstack server show test-instance -f value -c status)
        if [ "$STATUS" == "ACTIVE" ]; then
            echo "Instance active!"
            break
        elif [ "$STATUS" == "ERROR" ]; then
            echo "ERREUR: L'instance est en erreur!"
            openstack server show test-instance
            exit 1
        fi
        sleep 5
    done
else
    echo "Instance 'test-instance' deja existante."
fi

# =============================================================================
# 5. ATTACHER UNE IP FLOTTANTE
# =============================================================================
echo "[5/5] Attribution d'une IP flottante..."

if openstack network show provider &>/dev/null; then
    FLOATING_IP=$(openstack floating ip create provider -f value -c floating_ip_address 2>/dev/null || true)
    if [ -n "$FLOATING_IP" ]; then
        openstack server add floating ip test-instance $FLOATING_IP 2>/dev/null || true
        echo "IP flottante attribuee: $FLOATING_IP"
    fi
fi

echo "=========================================="
echo "Test termine!"
echo ""
echo "Status de l'instance:"
openstack server show test-instance -c name -c status -c addresses -c flavor
echo ""
echo "Pour vous connecter:"
echo "  ssh -i ~/.ssh/mykey cirros@<IP_ADDRESS>"
echo "  Password: gocubsgo (si demande)"
echo ""
echo "Pour voir la console:"
echo "  openstack console url show test-instance"
echo "=========================================="
