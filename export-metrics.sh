#!/bin/bash
set -euo pipefail


systemDpath="/etc/systemd/system/node-exporter-metrics.service"
version="1.11.1"
monitorIP="your mama"

if ! id -u node_exporter; then 
	sudo useradd --system --no-create-home --shell /usr/sbin/nologin node_exporter 
fi

cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v$version/node_exporter-$version.linux-amd64.tar.gz
tar xvf node_exporter-$version.linux-amd64.tar.gz
sudo cp node_exporter-$version.linux-amd64/node_exporter /usr/local/bin/
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
sudo tee "$systemDpath" << 'EOF'
[Unit]
Description=Prometheus Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter \
  --web.listen-address=0.0.0.0:9100

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable node-exporter-metrics
sudo systemctl start node-exporter-metrics

sudo ufw allow from $monitorIP to any port 9100 proto tcp
