# CertWatch #

This script will monitor and optionally renew certificates in a given directory tree.

Assume the following directory structure where each TLS secured service got it's own directory containing the certificate used for that service as well as a corresponding CSR which can be used for certificate renewal.


	/etc/certs/
	├── mail
	│   ├── .certconf
	│   │   ├── config
	│   │   └── renew.sh
	│   ├── dovecot
	│   │   ├── service.crt
	│   │   └── service.csr
	│   └── postfix
	│       ├── service.crt
	│       └── service.csr
	├── nginx
	│   ├── .certconf
	│   │   ├── config
	│   │   └── renew.sh
	│   ├── service.crt
	│   └── service.csr
	└── slapd
	    ├── .certconf
	    │   ├── config
	    │   └── renew.sh
	    ├── service.crt
	    └── service.csr


## .certconf directories ##

The `.certconf` directories contain two files which control the behavior of `CertWatch`. A `.certconf` directory applies to all certificates within it's root directory and it's subdirectories until it is overwritten by another `.certconf` directory.

That means that configurations in `/etc/certs/.certconf` would be overwritten by `/etc/certs/nginx/.certconf` but still apply to certificates in `/etc/certs/mail/postfix` if no `.certconf` directory exists within `/etc/certs/mail` or `/etc/certs/mail/postfix`.

### config ###

	EXPIRY_WARN=$((60*60*24*7))
	EXPIRY_RENEW=$((60*60*24*3))
	CERTFILE_REGEXP="^service\.crt$"


`CERTFILE_REGEXP` sets a perl regexp to match certificate files and is used to identify certificates to be monitored.

`EXPIRY_WARN` sets the rest time a certificate has to be valid left before a warning is printed.

`EXPIRY_RENEW` sets the rest time a certificate has to be valid left before renew.sh is executed in order to renew the certificate.

### renew.sh ###

This script will be executed by CertWatch if the certificate is valid for less time than set in `EXPIRY_RENEW.` The absolute path to the certificate will be passed to that script.


## Run the script ##

If you pass the `/etc/cert` listed above together with `--status` to `CertWatch`, you will get an overview of the certificates monitored by the script:

	root@host:~# CertWatch /etc/certs --status
	/etc/certs/mail/dovecot/service.crt
	        CONFIG: /etc/certs/mail/.certconf
	                EXPIRY_WARN=1209600 [ 2w 0s ]
	                EXPIRY_RENEW=604800 [ 1w 0s ]
	                CERTFILE_REGEXP=^service\.crt$
	        STATUS:
	                Valid until: Thu Jun 23 13:45:00 CEST 2016 [ 10w 18h 31m 52s ]
	                Warn       : Thu Jun  9 13:45:00 CEST 2016 [ 8w 18h 31m 52s ] 
	                Renew      : Thu Jun 16 13:45:00 CEST 2016 [ 9w 18h 31m 52s ] 

	/etc/certs/mail/postfix/service.crt
	        CONFIG: /etc/certs/mail/.certconf
	                EXPIRY_WARN=1209600 [ 2w 0s ]
	                EXPIRY_RENEW=604800 [ 1w 0s ]
	                CERTFILE_REGEXP=^service\.crt$
	        STATUS:
	                Valid until: Thu Jun 23 13:45:00 CEST 2016 [ 10w 18h 31m 52s ]
	                Warn       : Thu Jun  9 13:45:00 CEST 2016 [ 8w 18h 31m 52s ] 
	                Renew      : Thu Jun 16 13:45:00 CEST 2016 [ 9w 18h 31m 52s ] 

	/etc/certs/nginx/service.crt
	        CONFIG: /etc/certs/nginx/.certconf
	                EXPIRY_WARN=1209600 [ 2w 0s ]
	                EXPIRY_RENEW=604800 [ 1w 0s ]
	                CERTFILE_REGEXP=^service\.crt$
	        STATUS:
	                Valid until: Thu Jun 23 13:45:00 CEST 2016 [ 10w 18h 31m 52s ]
	                Warn       : Thu Jun  9 13:45:00 CEST 2016 [ 8w 18h 31m 52s ] 
	                Renew      : Thu Jun 16 13:45:00 CEST 2016 [ 9w 18h 31m 52s ] 

	/etc/certs/slapd/service.crt
	        CONFIG: /etc/certs/slapd/.certconf
	                EXPIRY_WARN=1209600 [ 2w 0s ]
	                EXPIRY_RENEW=604800 [ 1w 0s ]
	                CERTFILE_REGEXP=^service\.crt$
	        STATUS:
	                Valid until: Thu Jun 23 13:45:00 CEST 2016 [ 10w 18h 31m 52s ]
	                Warn       : Thu Jun  9 13:45:00 CEST 2016 [ 8w 18h 31m 52s ] 
	                Renew      : Thu Jun 16 13:45:00 CEST 2016 [ 9w 18h 31m 52s ]


If the ``--status`` parameter is omitted, only monitored certifcates will be listed that are within the `EXPIRY_WARN` or `EXPIRY_RENEW` rest times.

This allows you to setup a cronjob

	0 14 * * * /usr/local/sbin/CertWatch /etc/certs

which informs you about near expiries of certificates and renews them if `EXPIRY_RENEW` rest time is reached.

## Examples ##

The `config.example` directory contains an example renew.sh script which uses acme-tiny (https://github.com/diafygi/acme-tiny) and a NGINX configuration to renew the certificates, but you are free to setup any procedure you need to renew your certificates.
