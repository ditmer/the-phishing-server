#!/bin/bash

service rsyslog start
service postfix start
service dovecot start
chown opendkim:opendkim -R /etc/postfix/dkim/
service opendkim start
#service rsyslog restart

tail -f /var/log/syslog
