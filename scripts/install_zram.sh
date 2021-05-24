#!/bin/bash
wget -O /usr/bin/zram.sh https://raw.githubusercontent.com/novaspirit/rpi_zram/master/zram.sh

chmod +x /usr/bin/zram.sh

cat <<EOF > /etc/systemd/system/zram.service
[Unit]
Description=Zram

[Service]
ExecStart=/usr/bin/zram.sh

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable zram
systemctl start zram
