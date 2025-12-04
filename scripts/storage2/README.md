# Configuration Swift - Storage2 (via NAT)

## Ton infrastructure

| Personne | Rôle | IP |
|----------|------|-----|
| Ameni | Controller | 192.168.100.136 |
| Mme Fandouli | Compute1 | 192.168.100.162 |
| Mme Hedyene | Compute2 | 192.168.100.154 |
| Mme Cherni | Storage1 | 192.168.100.113 |
| Lmallekh | Compute3 | 192.168.100.200 |
| **TOI** | **Storage2** | **192.168.100.155** (via NAT) |

## Configuration spéciale (NAT)

Ton compute utilise NAT car le Wi-Fi ne supporte pas le Bridged VMware.

- **IP locale VM**: 192.168.43.28 (réseau NAT)
- **IP visible**: 192.168.100.155 (ton PC Windows via port forwarding)

---

## Étapes à suivre

### Étape 0 - Configuration Windows (Port Forwarding)

Sur ton PC Windows (PowerShell Admin):
```powershell
netsh interface portproxy add v4tov4 listenport=6200 listenaddress=192.168.100.155 connectport=6200 connectaddress=192.168.43.28
netsh interface portproxy add v4tov4 listenport=6201 listenaddress=192.168.100.155 connectport=6201 connectaddress=192.168.43.28
netsh interface portproxy add v4tov4 listenport=6202 listenaddress=192.168.100.155 connectport=6202 connectaddress=192.168.43.28

netsh advfirewall firewall add rule name="Swift 6200" dir=in action=allow protocol=tcp localport=6200
netsh advfirewall firewall add rule name="Swift 6201" dir=in action=allow protocol=tcp localport=6201
netsh advfirewall firewall add rule name="Swift 6202" dir=in action=allow protocol=tcp localport=6202
```

### Étape 1 - TOI (Storage2)
```bash
bash 00-setup-network-nat.sh
```
Configure le réseau et la route vers le controller.

### Étape 2 - TOI (Storage2)
```bash
bash 01-chrony-storage2.sh
```
Installe et configure la synchronisation temps.

### Étape 3 - TOI (Storage2)
```bash
bash 02-swift-storage2.sh
```
Installe et configure Swift Storage.

### Étape 4 - AMENI (Controller)
```bash
bash 03-controller-add-storage2.sh
```
Ajoute ton node aux rings Swift et t'envoie les fichiers.

### Étape 5 - TOI (Storage2)

Après avoir reçu les fichiers d'Ameni:
```bash
# Copie les fichiers reçus dans /etc/swift/
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
| 6200 | Object Server | 192.168.100.155:6200 → 192.168.43.28:6200 |
| 6201 | Container Server | 192.168.100.155:6201 → 192.168.43.28:6201 |
| 6202 | Account Server | 192.168.100.155:6202 → 192.168.43.28:6202 |
