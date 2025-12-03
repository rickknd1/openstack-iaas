# Deploiement OpenStack - IaaS Multi-Tenant

Ce projet deploie une infrastructure OpenStack complete sur 3 machines virtuelles Ubuntu 22.04.

## Architecture

```
+-------------------+     +-------------------+     +-------------------+
|    CONTROLLER     |     |      COMPUTE      |     |      STORAGE      |
|   10.0.0.11       |     |    10.0.0.31      |     |    10.0.0.1       |
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
                    |                         |
              ens33 (Management)        ens34 (Provider)
              10.0.0.0/24              192.168.43.0/24
```

## Configuration Reseau

| Node       | ens33 (Management) | ens34 (Provider)   |
|------------|--------------------|--------------------|
| Controller | 10.0.0.11/24       | 192.168.43.11/24   |
| Compute    | 10.0.0.31/24       | 10.0.1.31/24       |
| Storage    | 10.0.0.1/24        | -                  |

## Prerequis

- 3 VMs Ubuntu 22.04 Server
- Minimum 4 Go RAM par VM (8 Go recommande pour controller)
- 2 interfaces reseau sur controller et compute
- Acces root sur toutes les VMs
- Connectivite reseau entre les VMs

## Ordre d'Execution des Scripts

### Phase 1: Prerequis (sur TOUTES les VMs)
```bash
# Sur controller, compute ET storage
./01-prerequisites-all-nodes.sh
```

### Phase 2: Services de Base (sur CONTROLLER uniquement)
```bash
# Sur controller
./02-base-services-controller.sh
```

### Phase 3: Services OpenStack Core

```bash
# Sur controller
./03-keystone-controller.sh
./04-glance-controller.sh
./05-placement-controller.sh
./06-nova-controller.sh

# Sur compute
./07-nova-compute.sh

# Sur controller
./08-neutron-controller.sh

# Sur compute
./09-neutron-compute.sh

# Sur controller
./10-horizon-controller.sh
```

### Phase 4: Storage Services

```bash
# Sur controller
./11-cinder-controller.sh

# Sur storage
./12-cinder-storage.sh

# Sur controller
./13-swift-controller.sh

# Sur storage
./14-swift-storage.sh

# Sur controller
./15-swift-finalize.sh
```

### Phase 5: Orchestration

```bash
# Sur controller
./16-heat-controller.sh
```

### Phase 6: Monitoring

```bash
# Sur controller
./17-monitoring-controller.sh

# Sur compute ET storage
./18-node-exporter-nodes.sh
```

### Phase 7: Configuration Finale

```bash
# Sur controller
./19-create-networks.sh
./20-test-instance.sh
```

## Acces aux Interfaces

| Service    | URL                           | Credentials         |
|------------|-------------------------------|---------------------|
| Horizon    | http://10.0.0.11/horizon      | admin / admin_secret_pwd |
| Prometheus | http://10.0.0.11:9090         | -                   |
| Grafana    | http://10.0.0.11:3000         | admin / admin       |

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
openstack/
├── README.md
├── inventory.ini
├── group_vars/
│   └── all.yml
└── scripts/
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
