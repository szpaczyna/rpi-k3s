#!/bin/bash
certbot certonly --manual \
	--preferred-challenges=dns \
    --email shpaq[at]shpaq[dot]org \
	--server https://acme-v02.api.letsencrypt.org/directory \
	--agree-tos \
	--manual-public-ip-logging-ok \
	-d "*.shpaq.org"
