# Configuration Swift - Storage2 (via NAT)

## Infrastructure du groupe

| Personne | Rôle | IP |
|----------|------|-----|
| Ameni | Controller | 192.168.100.136 |
| Mme Fandouli | Compute1 | 192.168.100.172 |
| Mme Hedyene | Compute2 | 192.168.100.154 |
| Mme Cherni | Storage1 | 192.168.100.113 |
| Lmallekh | Compute3 | 192.168.100.200 |
| **TOI** | **Storage2** | **192.168.100.155** (via NAT Windows) |

## Configuration spéciale (NAT)

Le Wi-Fi ne supporte pas le mode Bridged VMware, donc on utilise NAT + port forwarding.

- **IP locale VM**: 192.168.43.28 (réseau NAT)
- **IP visible par collègues**: 192.168.100.155 (PC Windows, redirigé vers VM)

---

## Étapes à suivre

### Étape 0 - Configuration Windows (PowerShell Admin)

```powershell
netsh interface portproxy add v4tov4 listenport=6200 listenaddress=192.168.100.155 connectport=6200 connectaddress=192.168.43.28
netsh interface portproxy add v4tov4 listenport=6201 listenaddress=192.168.100.155 connectport=6201 connectaddress=192.168.43.28
netsh interface portproxy add v4tov4 listenport=6202 listenaddress=192.168.100.155 connectport=6202 connectaddress=192.168.43.28

netsh advfirewall firewall add rule name="Swift 6200" dir=in action=allow protocol=tcp localport=6200
netsh advfirewall firewall add rule name="Swift 6201" dir=in action=allow protocol=tcp localport=6201
netsh advfirewall firewall add rule name="Swift 6202" dir=in action=allow protocol=tcp localport=6202
```

### Étape 1 - Configurer /etc/hosts et réseau
```bash
bash 00-configure-hosts.sh
```

### Étape 2 - Installer Chrony
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
Elle utilisera l'IP **192.168.100.155** pour t'ajouter aux rings.

### Étape 5 - Démarrer Swift
Après avoir reçu les fichiers ring d'Ameni, place-les dans `/etc/swift/` puis:
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

| Port | Service | Redirection |
|------|---------|-------------|
| 6200 | Object Server | 192.168.100.155 → 192.168.43.28 |
| 6201 | Container Server | 192.168.100.155 → 192.168.43.28 |
| 6202 | Account Server | 192.168.100.155 → 192.168.43.28 |
