# Deploiement OpenStack - IaaS Multi-Tenant

Ce projet deploie une infrastructure OpenStack complete sur 3 machines virtuelles Ubuntu 22.04.

## Architecture

```
+-------------------+     +-------------------+     +-------------------+
|    CONTROLLER     |     |      COMPUTE      |     |      STORAGE      |
|  192.168.10.11    |     |   192.168.10.31   |     |   192.168.10.41   |
+-------------------+     +-------------------+     +-------------------+
|                   |     |                   |     |                   |
| - Keystone        |     | - Nova Compute    |     | - Cinder Volume   |
| - Glance          |     | - Neutron Agent   |     | - Swift Storage   |
| - Nova API        |     | - KVM/QEMU        |     |                   |
| - Neutron Server  |     |                   |     |                   |
| - Horizon         |     |                   |     |                   |
| - Cinder API      |     |                   |     |                   |
| - Heat            |     |                   |     |                   |
| - Prometheus      |     |                   |     |                   |
| - Grafana         |     |                   |     |                   |
+-------------------+     +-------------------+     +-------------------+
        |                         |                         |
        +-----------+-------------+-----------+-------------+
                    |
              VMnet8 (NAT)
           192.168.10.0/24
```

## Configuration Reseau

### Reseau actuel (NAT - pour travail solo)

| Node       | ens33 (NAT)        | Hostname   |
|------------|--------------------|------------|
| Controller | 192.168.10.11/24   | controller |
| Compute    | 192.168.10.31/24   | compute    |
| Storage    | 192.168.10.41/24   | storage    |

Gateway: 192.168.10.2 (VMware NAT)

### Reseau classe (Bridged - pour travail en equipe)

| Membre      | Role       | IP               |
|-------------|------------|------------------|
| Ameni       | Controller | 192.168.100.136  |
| Mme Fandouli| Compute1   | 192.168.100.172  |
| Mme Hedyene | Compute2   | 192.168.100.154  |
| Mme Cherni  | Storage1   | 192.168.100.113  |
| Lmallekh    | Compute3   | 192.168.100.200  |
| **Toi**     | Storage2   | 192.168.100.155  |

## Prerequis

- 3 VMs Ubuntu 22.04 Server
- Minimum 4 Go RAM par VM (8 Go recommande pour controller)
- VMware avec VMnet8 (NAT) configure
- Acces root sur toutes les VMs
- Connectivite reseau entre les VMs

## Ordre d'Execution des Scripts

### Phase 0: Configuration Reseau (sur CHAQUE VM)
```bash
# Sur controller
sudo bash 00-setup-network-controller.sh

# Sur compute
sudo bash 00-setup-network-compute.sh

# Sur storage
sudo bash 00-setup-network-storage.sh
```

### Phase 1: Prerequis (sur TOUTES les VMs)
```bash
# Sur controller, compute ET storage
sudo bash 01-prerequisites-all-nodes.sh
# Puis redemarrer: sudo reboot
```

### Phase 2: Services de Base (sur CONTROLLER uniquement)
```bash
# Sur controller
sudo bash 02-base-services-controller.sh
```

### Phase 3: Services OpenStack Core

```bash
# Sur controller
sudo bash 03-keystone-controller.sh
sudo bash 04-glance-controller.sh
sudo bash 05-placement-controller.sh
sudo bash 06-nova-controller.sh

# Sur compute
sudo bash 07-nova-compute.sh

# Sur controller (decouvrir le compute)
source /root/admin-openrc
su -s /bin/sh -c 'nova-manage cell_v2 discover_hosts --verbose' nova

# Sur controller
sudo bash 08-neutron-controller.sh

# Sur compute
sudo bash 09-neutron-compute.sh

# Sur controller
sudo bash 10-horizon-controller.sh
```

### Phase 4: Storage Services

```bash
# Sur controller
sudo bash 11-cinder-controller.sh

# Sur storage
sudo bash 12-cinder-storage.sh

# Sur controller
sudo bash 13-swift-controller.sh

# Sur storage
sudo bash 14-swift-storage.sh

# Sur controller
sudo bash 15-swift-finalize.sh
```

### Phase 5: Orchestration

```bash
# Sur controller
sudo bash 16-heat-controller.sh
```

### Phase 6: Monitoring

```bash
# Sur controller
sudo bash 17-monitoring-controller.sh

# Sur compute ET storage
sudo bash 18-node-exporter-nodes.sh
```

### Phase 7: Configuration Finale

```bash
# Sur controller
sudo bash 19-create-networks.sh
sudo bash 20-test-instance.sh
```

## Acces aux Interfaces

| Service    | URL                              | Credentials              |
|------------|----------------------------------|--------------------------|
| Horizon    | http://192.168.10.11/horizon     | admin / admin_secret_pwd |
| Prometheus | http://192.168.10.11:9090        | -                        |
| Grafana    | http://192.168.10.11:3000        | admin / admin            |

## Commandes de Verification

```bash
# Charger les credentials
source /root/admin-openrc

# Verifier les services
openstack service list
openstack compute service list
openstack network agent list
openstack volume service list

# Verifier les endpoints
openstack endpoint list

# Verifier les images
openstack image list

# Verifier les reseaux
openstack network list
openstack router list

# Verifier les instances
openstack server list
```

## Mots de Passe par Defaut

| Service          | Password             |
|------------------|----------------------|
| MySQL root       | openstack_root_pwd   |
| RabbitMQ         | rabbit_openstack_pwd |
| Keystone admin   | admin_secret_pwd     |
| Service users    | <service>_pass       |
| Database users   | <service>_dbpass     |

**IMPORTANT**: Changez tous les mots de passe en production!

## Depannage

### Verifier les logs
```bash
# Keystone
tail -f /var/log/keystone/keystone.log

# Nova
tail -f /var/log/nova/nova-api.log
tail -f /var/log/nova/nova-compute.log

# Neutron
tail -f /var/log/neutron/neutron-server.log

# Cinder
tail -f /var/log/cinder/cinder-volume.log
```

### Verifier les services
```bash
# Status des services
systemctl status mariadb rabbitmq-server memcached
systemctl status nova-api nova-scheduler nova-conductor
systemctl status neutron-server neutron-openvswitch-agent
systemctl status cinder-scheduler cinder-volume
```

### Problemes courants

1. **Erreur de connexion a la base de donnees**
   - Verifier que MariaDB est en cours d'execution
   - Verifier les credentials dans les fichiers de configuration

2. **Erreur RabbitMQ**
   - Verifier que RabbitMQ est en cours d'execution
   - Verifier le mot de passe de l'utilisateur openstack

3. **Instance ne demarre pas**
   - Verifier les logs nova-compute sur le node compute
   - Verifier que KVM est correctement configure
   - Verifier la connectivite reseau

4. **Pas de connectivite reseau pour les instances**
   - Verifier les agents Neutron: `openstack network agent list`
   - Verifier la configuration OVS: `ovs-vsctl show`

## Structure des Fichiers

```
openstack-iaas/
├── README.md
├── inventory.ini
├── group_vars/
│   └── all.yml
└── scripts/
    ├── 00-setup-network-controller.sh  # NEW
    ├── 00-setup-network-compute.sh     # NEW
    ├── 00-setup-network-storage.sh     # NEW
    ├── 01-prerequisites-all-nodes.sh
    ├── 02-base-services-controller.sh
    ├── 03-keystone-controller.sh
    ├── 04-glance-controller.sh
    ├── 05-placement-controller.sh
    ├── 06-nova-controller.sh
    ├── 07-nova-compute.sh
    ├── 08-neutron-controller.sh
    ├── 09-neutron-compute.sh
    ├── 10-horizon-controller.sh
    ├── 11-cinder-controller.sh
    ├── 12-cinder-storage.sh
    ├── 13-swift-controller.sh
    ├── 14-swift-storage.sh
    ├── 15-swift-finalize.sh
    ├── 16-heat-controller.sh
    ├── 17-monitoring-controller.sh
    ├── 18-node-exporter-nodes.sh
    ├── 19-create-networks.sh
    └── 20-test-instance.sh
```
