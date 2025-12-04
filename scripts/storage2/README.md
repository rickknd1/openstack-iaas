# Configuration Swift - Storage2

## Ton infrastructure

| Personne | Rôle | IP |
|----------|------|-----|
| Ameni | Controller | 192.168.100.136 |
| Mme Fandouli | Compute1 | 192.168.100.162 |
| Mme Hedyene | Compute2 | 192.168.100.154 |
| Mme Cherni | Storage1 | 192.168.100.113 |
| Lmallekh | Compute3 | 192.168.100.200 |
| **TOI** | **Storage2** | **192.168.100.150** |

---

## Étapes à suivre

### Étape 1 - TOI (Storage2)
```bash
bash 01-configure-hosts.sh
```
Configure ton fichier `/etc/hosts` avec tous les nodes du groupe.

### Étape 2 - TOI (Storage2)
```bash
bash 02-swift-storage2.sh
```
Installe et configure Swift Storage sur ta machine.

### Étape 3 - AMENI (Controller)
Donne ce script à Ameni pour qu'elle l'exécute sur le controller:
```bash
bash 03-add-storage2-to-rings.sh
```
Ajoute ton node aux rings Swift et te copie les fichiers.

### Étape 4 - TOI (Storage2)
```bash
bash 04-start-swift-services.sh
```
Démarre tous les services Swift sur ta machine.

---

## Vérification
Depuis le controller (Ameni):
```bash
source /root/admin-openrc
swift stat
```

---

## Ports utilisés
- 6200 : Object Server
- 6201 : Container Server
- 6202 : Account Server
