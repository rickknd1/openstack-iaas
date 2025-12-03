#!/bin/bash
# =============================================================================
# Script: 17-monitoring-controller.sh
# Description: Installe Prometheus et Grafana sur le Controller
# A executer sur: controller UNIQUEMENT
# =============================================================================

set -e

echo "=========================================="
echo "Installation de Prometheus et Grafana"
echo "=========================================="

# Variables
CONTROLLER_IP="10.0.0.11"
COMPUTE_IP="10.0.0.31"
STORAGE_IP="10.0.0.1"

# =============================================================================
# 1. INSTALLATION DE PROMETHEUS
# =============================================================================
echo "[1/5] Installation de Prometheus..."

# Creer l'utilisateur prometheus
useradd --no-create-home --shell /bin/false prometheus || true

# Telecharger Prometheus
cd /tmp
PROM_VERSION="2.47.0"
wget https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.linux-amd64.tar.gz
tar xzf prometheus-${PROM_VERSION}.linux-amd64.tar.gz
cd prometheus-${PROM_VERSION}.linux-amd64

# Installer les binaires
cp prometheus promtool /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool

# Creer les repertoires
mkdir -p /etc/prometheus /var/lib/prometheus
cp -r consoles console_libraries /etc/prometheus/
chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus

# =============================================================================
# 2. CONFIGURATION DE PROMETHEUS
# =============================================================================
echo "[2/5] Configuration de Prometheus..."

cat > /etc/prometheus/prometheus.yml << EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: []

rule_files: []

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_controller'
    static_configs:
      - targets: ['${CONTROLLER_IP}:9100']
        labels:
          instance: 'controller'

  - job_name: 'node_compute'
    static_configs:
      - targets: ['${COMPUTE_IP}:9100']
        labels:
          instance: 'compute'

  - job_name: 'node_storage'
    static_configs:
      - targets: ['${STORAGE_IP}:9100']
        labels:
          instance: 'storage'

  - job_name: 'openstack_exporter'
    static_configs:
      - targets: ['${CONTROLLER_IP}:9180']
EOF

chown prometheus:prometheus /etc/prometheus/prometheus.yml

# Creer le service systemd
cat > /etc/systemd/system/prometheus.service << EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \\
    --config.file=/etc/prometheus/prometheus.yml \\
    --storage.tsdb.path=/var/lib/prometheus/ \\
    --web.console.templates=/etc/prometheus/consoles \\
    --web.console.libraries=/etc/prometheus/console_libraries \\
    --web.enable-lifecycle

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start prometheus
systemctl enable prometheus

# =============================================================================
# 3. INSTALLATION DE NODE EXPORTER (sur controller)
# =============================================================================
echo "[3/5] Installation de Node Exporter..."

useradd --no-create-home --shell /bin/false node_exporter || true

cd /tmp
NODE_VERSION="1.6.1"
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_VERSION}/node_exporter-${NODE_VERSION}.linux-amd64.tar.gz
tar xzf node_exporter-${NODE_VERSION}.linux-amd64.tar.gz
cp node_exporter-${NODE_VERSION}.linux-amd64/node_exporter /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter

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

# =============================================================================
# 4. INSTALLATION DE GRAFANA
# =============================================================================
echo "[4/5] Installation de Grafana..."

apt install -y apt-transport-https software-properties-common
wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key
echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list
apt update
apt install -y grafana

systemctl start grafana-server
systemctl enable grafana-server

# =============================================================================
# 5. CONFIGURATION DE LA DATASOURCE PROMETHEUS DANS GRAFANA
# =============================================================================
echo "[5/5] Configuration de Grafana..."

# Attendre que Grafana soit pret
sleep 10

# Ajouter Prometheus comme datasource
cat > /etc/grafana/provisioning/datasources/prometheus.yml << EOF
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://localhost:9090
    isDefault: true
    editable: false
EOF

# Creer un dashboard basique pour OpenStack
mkdir -p /etc/grafana/provisioning/dashboards

cat > /etc/grafana/provisioning/dashboards/dashboard.yml << EOF
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    options:
      path: /var/lib/grafana/dashboards
EOF

mkdir -p /var/lib/grafana/dashboards

cat > /var/lib/grafana/dashboards/openstack-nodes.json << 'EOF'
{
  "annotations": {
    "list": []
  },
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 0,
  "id": null,
  "links": [],
  "liveNow": false,
  "panels": [
    {
      "datasource": {
        "type": "prometheus",
        "uid": "prometheus"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "percent"
        }
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 0
      },
      "id": 1,
      "options": {
        "orientation": "auto",
        "reduceOptions": {
          "calcs": ["lastNotNull"],
          "fields": "",
          "values": false
        },
        "showThresholdLabels": false,
        "showThresholdMarkers": true
      },
      "pluginVersion": "10.0.0",
      "targets": [
        {
          "expr": "100 - (avg by(instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
          "legendFormat": "{{instance}}",
          "refId": "A"
        }
      ],
      "title": "CPU Usage par Node",
      "type": "gauge"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "prometheus"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "percent"
        }
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 0
      },
      "id": 2,
      "options": {
        "orientation": "auto",
        "reduceOptions": {
          "calcs": ["lastNotNull"],
          "fields": "",
          "values": false
        },
        "showThresholdLabels": false,
        "showThresholdMarkers": true
      },
      "pluginVersion": "10.0.0",
      "targets": [
        {
          "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
          "legendFormat": "{{instance}}",
          "refId": "A"
        }
      ],
      "title": "Memory Usage par Node",
      "type": "gauge"
    }
  ],
  "refresh": "5s",
  "schemaVersion": 38,
  "style": "dark",
  "tags": ["openstack"],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-1h",
    "to": "now"
  },
  "timepicker": {},
  "timezone": "",
  "title": "OpenStack Nodes Overview",
  "uid": "openstack-nodes",
  "version": 1,
  "weekStart": ""
}
EOF

chown -R grafana:grafana /var/lib/grafana/dashboards

systemctl restart grafana-server

echo "=========================================="
echo "Prometheus et Grafana installes!"
echo ""
echo "Acces:"
echo "  Prometheus: http://${CONTROLLER_IP}:9090"
echo "  Grafana:    http://${CONTROLLER_IP}:3000"
echo "              User: admin / Password: admin"
echo ""
echo "IMPORTANT: Executez le script"
echo "18-node-exporter-nodes.sh sur compute et storage"
echo "=========================================="
