# Configuration Swift - Storage2

## Infrastructure du groupe

| Personne | Rôle | IP |
|----------|------|-----|
| Ameni | Controller | 192.168.100.136 |
| Mme Fandouli | Compute1 | 192.168.100.172 |
| Mme Hedyene | Compute2 | 192.168.100.154 |
| Mme Cherni | Storage1 | 192.168.100.113 |
| Lmallekh | Compute3 | 192.168.100.200 |
| **TOI** | **Storage2** | **192.168.100.155** |

---

## Étapes à suivre

### Étape 1 - Configurer /etc/hosts
```bash
bash 00-configure-hosts.sh
```

### Étape 2 - Installer Chrony (synchronisation temps)
```bash
bash 01-chrony-storage2.sh
```

### Étape 3 - Installer Swift Storage
```bash
bash 02-swift-storage2.sh
```

### Étape 4 - AMENI (Controller)
Dis à Ameni d'exécuter sur le Controller:
```bash
bash 03-controller-add-storage2.sh
```
Elle t'enverra ensuite les fichiers ring.

### Étape 5 - Démarrer Swift
Après avoir reçu les fichiers d'Ameni, place-les dans `/etc/swift/` puis:
```bash
bash 04-start-swift-storage2.sh
```

---

## Vérification

Depuis le controller (Ameni):
```bash
source /root/admin-openrc
swift stat
openstack container create test-container
echo 'Hello Swift' > test.txt
openstack object create test-container test.txt
openstack object list test-container
```

---

## Ports utilisés

| Port | Service |
|------|---------|
| 6200 | Object Server |
| 6201 | Container Server |
| 6202 | Account Server |
