#!/bin/bash
#==========================================
# Ajouter la clé SSH du Controller sur Storage
#==========================================

echo "=== Ajout de la clé SSH du Controller ==="

# Créer le dossier .ssh si nécessaire
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Ajouter la clé publique du controller
cat >> ~/.ssh/authorized_keys << 'EOF'
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDd/R/Qxu6m0EM2SbmJWr6n8pFj1s61MxmwT02K7m13njmqFo9PXKPWXVBSxp0iTzdm1mRwjpDE23fBROTCkMyA/sKqUxQttqGMnpS67g1Yue00C0rjbbEekWK/DZaT14TCJNCjtvTjuM0xVaXIybOGMLkrhVKqGy2JJyBkc23rzpa+4ThsODHJu/M198I1OqYxGLYIa0GCWKTiQdh77r2A1YFYIiMDyFm47fVZ5Y0rNX3FtFukXI+jse6p5xIK9tDCpr2C7hfZqyx3yqsBa7X0Z214Xn3Hwu/UtXhUAIKtjZ7DoUsVoOBHaDJ0iI9ju7EE1wLpvY0KxW5DKfdkbcVV2PIpQSVvzC708cReLI6cuPSNpkjBpeBgPKwu0pTP1zX650yNDJgc4LT0jEDqzb60GPn7zQ9PV7BzgI21UZ9aSA6hwv1kD1SLutlcnIu3zRE8OXtUx7SMAWaeaHv96A5exggNu1/gkIhhLXIv6Na9+xWh4tztXLYCf10KCQvx0= root@controller
EOF

chmod 600 ~/.ssh/authorized_keys

echo "=== Clé SSH du Controller ajoutée avec succès! ==="
echo "Le Controller peut maintenant se connecter sans mot de passe."
