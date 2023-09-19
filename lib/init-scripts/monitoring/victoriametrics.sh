#!/bin/bash

mkdir -p /usr/local/bin

apt-get install -y jq net-tools software-properties-common

VM_VER=`curl -s https://api.github.com/repos/VictoriaMetrics/VictoriaMetrics/releases/latest | jq -r '.tag_name'`

curl -L https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/${VM_VER}/victoria-metrics-linux-amd64-${VM_VER}.tar.gz --output victoria-metrics-linux-amd64-${VM_VER}.tar.gz
tar xvf victoria-metrics-linux-amd64-${VM_VER}.tar.gz -C /usr/local/bin/

chmod +x /usr/local/bin/* -R
chown root:root /usr/local/bin/* -R


mkdir -p /var/lib/victoriametrics-data

cat <<EOF > /etc/systemd/system/victoriametrics.service
[Unit]
Description="High-performance, cost-effective and scalable time series database, long-term remote storage for prometheus"
After=network.target

[Service]
Type=simple
StartLimitBurst=5
StartLimitInterval=0
Restart=on-failure
RestartSec=5
ExecStart=/usr/local/bin/victoria-metrics-prod \
-storageDataPath=/var/lib/victoriametrics-data \
-httpListenAddr=0.0.0.0:8428 \
-retentionPeriod=6
ExecStop=/bin/kill -s SIGTERM $MAINPID
LimitNOFILE=65536
LimitNPROC=32000

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

systemctl enable victoriametrics

systemctl start victoriametrics
