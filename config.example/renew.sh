#!/bin/bash
#
# Script to renew certificate with Let's Encrypt.
# It's assumed that a service.csr file is available in
# the same directory as the certificate.
#
# NGINX will be used to pass the ACME challenges. The
# configuration $NGINX_CONF will be enabled before calling
# $ACME_TINY to request the new certificate.
#
# The name of the certificate containing directory will be
# used as service name and reloaded after renewal.
#
# Arguments passed to this script:
#
#   $1: Contains the absolute path to the expiring certificate

# Path to acme_tiny.py (https://github.com/diafygi/acme-tiny)
ACME_TINY="/usr/share/acme-tiny/acme_tiny.py"    
# Path to Let's Encrypt account key
ACME_KEY="/etc/letsencrypt/account.key"
# Path to the ACME challenge directory
ACME_DIR="/etc/letsencrypt/acme-challenge"
# Path to the Let's Encrypt intermediate certificate for chaining
INTERMEDIATE="/etc/letsencrypt/intermediate.pem"
# Path to the NGINX configuration to serve ACME_DIR 
NGINX_CONF="/etc/nginx/conf.d/nginx_acme.conf"

DIR="`dirname \"$1\"`"
SERVICE="`basename \"$DIR\"`"

# Check if CSR is available
CSR="${DIR}/service.csr"
! [ -r "${CSR}" ] && echo "ERROR: CSR ${CSR} missing." && exit 1

# Check if intermediate certificate is available
! [ -r "${INTERMEDIATE}" ] && echo "INTERMEDIATE ${INTERMEDIATE} missing." && exit 1

# Activate NGINX configuration for ACME challenge
! [ -f "${NGINX_CONF}" ] && ! [ -f "${NGINX_CONF}.disabled" ] && echo "ERROR: NGINX_CONF ${NGINX_CONF} missing." && exit 1
! [ -f "${NGINX_CONF}" ] && mv "${NGINX_CONF}.disabled" "${NGINX_CONF}"
! [ -f "${NGINX_CONF}" ] && echo "ERROR: Could not activate NGINX_CONF." && exit 1
! systemctl reload nginx && echo "ERROR: Could not reload NGINX" && exit 1

# Request and chain certificate
success=false
${ACME_TINY} --account-key "${ACME_KEY}" --csr "${CSR}" --acme-dir "${ACME_DIR}" > "${DIR}/service.crt.new" && \
cat "${INTERMEDIATE}" >> "${DIR}/service.crt.new" && \
chown --reference "$1" "${DIR}/service.crt.new" && \
chmod --reference "$1" "${DIR}/service.crt.new" && \
success=true

if ! $success; then
	echo "ERROR: Could not create new certificate. Leaving anything as is."
else
	# Replace the certificate
	mv "${DIR}/service.crt" "${DIR}/service.crt.`date +%s`"
	mv "${DIR}/service.crt.new" "${DIR}/service.crt"
	
	# Reload service
	echo "Reload service \"$SERVICE\""
	! systemctl restart "$SERVICE" && echo "ERROR: Could not reload service \"$SERVICE\""
fi

# Deactivate NGINX configuration for ACME challenge
mv "${NGINX_CONF}" "${NGINX_CONF}.disabled"
! [ -f "${NGINX_CONF}.disabled" ] && echo "ERROR: Could not deactivate NGINX_CONF." && exit 1
! systemctl reload nginx && echo "ERROR: Could not reload NGINX" && exit 1