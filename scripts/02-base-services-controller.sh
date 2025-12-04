#!/bin/bash
# =============================================================================
# Script: 02-base-services-controller.sh
# Description: Installe MariaDB, RabbitMQ et Memcached sur le Controller
# A executer sur: controller UNIQUEMENT
# =============================================================================

set -e

echo "=========================================="
echo "Installation des services de base"
echo "Controller Node"
echo "=========================================="

# Variables
MYSQL_ROOT_PASS="openstack_root_pwd"
RABBITMQ_USER="openstack"
RABBITMQ_PASS="rabbit_openstack_pwd"

# =============================================================================
# 1. INSTALLATION ET CONFIGURATION DE MARIADB
# =============================================================================
echo "[1/3] Installation de MariaDB..."
apt install -y mariadb-server python3-pymysql

# Configuration de MariaDB pour OpenStack
cat > /etc/mysql/mariadb.conf.d/99-openstack.cnf << EOF
[mysqld]
bind-address = 10.0.0.11

default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
EOF

systemctl restart mariadb
systemctl enable mariadb

# Securisation de MariaDB (compatible MariaDB 10.4+)
echo "Securisation de MariaDB..."
mysql -u root << EOF
-- Definir le mot de passe root (methode compatible 10.4+)
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASS}';

-- Supprimer les utilisateurs anonymes
DELETE FROM mysql.global_priv WHERE User='';

-- Supprimer root distant
DELETE FROM mysql.global_priv WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Supprimer la base test
DROP DATABASE IF EXISTS test;

FLUSH PRIVILEGES;
EOF

echo "MariaDB installe et configure."

# =============================================================================
# 2. INSTALLATION ET CONFIGURATION DE RABBITMQ
# =============================================================================
echo "[2/3] Installation de RabbitMQ..."
apt install -y rabbitmq-server

systemctl enable rabbitmq-server
systemctl start rabbitmq-server

# Ajout de l'utilisateur OpenStack
rabbitmqctl add_user ${RABBITMQ_USER} ${RABBITMQ_PASS} || true
rabbitmqctl set_permissions ${RABBITMQ_USER} ".*" ".*" ".*"

echo "RabbitMQ installe et configure."

# =============================================================================
# 3. INSTALLATION ET CONFIGURATION DE MEMCACHED
# =============================================================================
echo "[3/3] Installation de Memcached..."
apt install -y memcached python3-memcache

# Configuration de Memcached
sed -i 's/-l 127.0.0.1/-l 10.0.0.11/' /etc/memcached.conf

systemctl restart memcached
systemctl enable memcached

echo "Memcached installe et configure."

echo "=========================================="
echo "Services de base installes avec succes!"
echo "=========================================="

# Verification des services
echo ""
echo "Verification des services:"
echo "MariaDB: $(systemctl is-active mariadb)"
echo "RabbitMQ: $(systemctl is-active rabbitmq-server)"
echo "Memcached: $(systemctl is-active memcached)"
