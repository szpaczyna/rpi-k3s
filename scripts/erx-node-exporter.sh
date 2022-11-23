#!/bin/sh

VER=1.1.2

curl https://github.com/prometheus/node_exporter/releases/download/v${VER}/node_exporter-${VER}.linux-mipsle.tar.gz -L --output node_exporter-${VER}.linux-mipsle.tar.gz

tar -xf node_exporter-${VER}.linux-mipsle.tar.gz

sudo mkdir /usr/bin/node-exporter
sudo cp node_exporter-${VER}.linux-mipsle/node_exporter /usr/bin/node-exporter/node_exporter

# clean up the mess
rm node* -R

## create systemd service
sudo cat << EOF > /lib/systemd/system/node_exporter.service
[Unit]
Description=NodeExporter
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/node-exporter/node_exporter --collector.systemd --collector.logind --no-collector.bonding --no-collector.hwmon --no-collector.infiniband --no-collector.ipvs --no-collector.mdadm --no-collector.nfs --no-collector.nfsd --no-collector.powersupplyclass --no-collector.zfs --no-collector.xfs --no-collector.thermal_zone --no-collector.schedstat --no-collector.rapl --no-collector.btrfs --no-collector.bcache --no-collector.cpufreq --no-collector.edac

Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl unmask node_exporter
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
