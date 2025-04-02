#!/bin/bash
#
NPM_PROXY_HOST_DIR="/z/docker/nginx-proxy-manager/data/nginx/proxy_host"
NPM_CERTS_DIR="/z/docker/nginx-proxy-manager/letsencrypt/live"


for dir in "$NPM_CERTS_DIR"/*/; do
    # Check if it's a directory
    if [ -d "$dir" ]; then
        # Print the directory name without the full path
        SSL_NAME="$(basename "$dir")"
        NPM_NAME=$(find "${NPM_PROXY_HOST_DIR}" -type f -exec grep -wl "${SSL_NAME}" {} \; | xargs -I {} basename {})
        DOMAIN_NAME=$(find "${NPM_PROXY_HOST_DIR}" -type f -exec grep -wl "${SSL_NAME}" {} \; | xargs grep -wh "server_name" | head -n1 | sed -E 's/server_name [^.]+\.(.*);/\1/' | sed -E 's/^[ \t]+//'| awk '{print $1}' )
        echo "${SSL_NAME} -> ${DOMAIN_NAME} -> ${NPM_NAME}"
   fi
done
