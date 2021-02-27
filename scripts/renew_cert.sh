#!/bin/bash

/usr/bin/certbot renew \
#		--preferred-challenges=dns \
		--email shpaq[at]shpaq[dot]org \
		--server https://acme-v02.api.letsencrypt.org/directory \
		--agree-tos

cat /etc/letsencrypt/live/pihole.shpaq.org/privkey.pem /etc/letsencrypt/live/pihole.shpaq.org/cert.pem > /etc/letsencrypt/live/pihole.shpaq.org/merged.pem
chown www-data:www-data -R /etc/letsencrypt/live/pihole.shpaq.org/
#systemctl status lighttpd.service
