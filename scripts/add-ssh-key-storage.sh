#!/bin/bash
# =============================================================================
# Script: add-ssh-key-storage.sh
# Description: Ajoute la cle SSH du controller sur le storage
# A executer sur: STORAGE
# =============================================================================

mkdir -p ~/.ssh
chmod 700 ~/.ssh

cat >> ~/.ssh/authorized_keys << 'EOF'
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDd/R/Qxu6m0EM2SbmJWr6n8pFj1s61MxmwT02K7m13njmqFo9PXKPW7XVBSxp0iTzdm1mRwjpDE23fBROTCkMyA/sKqUxQttqGMnpS67g1Yue0OCOrjbbEekWK/0ZaTI4TCJNCjtVTjuM0xVaXIyb0G6MLkrhVXKqGy2ZjyBkcz3rzpa+4ThsOoHJu/M198iIoqYxGLYIaOGCWkT1Qdh77r2A1YFYIiMDyFm47fVZX7OrNX3FtFukXI+jse6p5xIK9tDCprZC7hfZqyx3ygsBa7X0Z214Xn3Hwu/UtXhUAIktjz7DoUsVoOBHaDJoiI9ju7EE1uWLpvYOKxW5DKfdKbcVVZPIpQSVvzC708cReLI6cuPSNpkjBpeBgPKwu0pTP1zX650yNDJgc4LTOJEDqzb60GPn7zQ9PV7BzgIZ1UZ9aSA6hwv1kD1SLut1cnIu3zRE8OXtUx7SMAWaeaHv96A5exggNul/gKIhhLXIv6Na9+xWh4tztXLYCf10KCQvxU= root@controller
EOF

chmod 600 ~/.ssh/authorized_keys

echo "Cle SSH ajoutee avec succes!"
