#!/bin/bash
# =============================================================================
# Script: 18-node-exporter-nodes.sh
# Description: Installe Node Exporter sur les nodes Compute et Storage
# A executer sur: compute ET storage
# =============================================================================

set -e

echo "=========================================="
echo "Installation de Node Exporter"
echo "=========================================="

# =============================================================================
# 1. INSTALLATION DE NODE EXPORTER
# =============================================================================
echo "[1/2] Installation de Node Exporter..."

useradd --no-create-home --shell /bin/false node_exporter || true

cd /tmp
NODE_VERSION="1.6.1"
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_VERSION}/node_exporter-${NODE_VERSION}.linux-amd64.tar.gz
tar xzf node_exporter-${NODE_VERSION}.linux-amd64.tar.gz
cp node_exporter-${NODE_VERSION}.linux-amd64/node_exporter /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter

# =============================================================================
# 2. CONFIGURATION DU SERVICE
# =============================================================================
echo "[2/2] Configuration du service..."

cat > /etc/systemd/system/node_exporter.service << EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter

# Nettoyer
rm -rf /tmp/node_exporter-*

echo "=========================================="
echo "Node Exporter installe!"
echo ""
echo "Verification:"
echo "  curl http://localhost:9100/metrics"
echo ""
echo "Les metriques sont maintenant accessibles"
echo "depuis Prometheus sur le controller."
echo "=========================================="
