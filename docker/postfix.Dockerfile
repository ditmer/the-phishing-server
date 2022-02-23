FROM debian

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y postfix postfix-pcre postfix-mysql dovecot-core dovecot-imapd dovecot-mysql dovecot-lmtpd rsyslog opendkim opendkim-tools procps

RUN mkdir -p /config/postfix /config/dovecot

COPY config/postfix/* /config/postfix/
COPY config/dovecot/dovecot-sql.conf.ext /config/dovecot/dovecot-sql.conf.ext
COPY config/dkim/* /config/dkim/

#Link postfix config files - this is done so we can update configs in real time
RUN ln -sf /config/postfix/main.cf /etc/postfix/main.cf && \
 ln -sf /config/postfix/master.cf /etc/postfix/master.cf && \
 ln -sf /config/postfix/mysql-virtual-alias-maps.cf /etc/postfix/mysql-virtual-alias-maps.cf && \
 ln -sf /config/postfix/mysql-virtual-mailbox-domains.cf /etc/postfix/mysql-virtual-mailbox-domains.cf && \
 ln -sf /config/postfix/mysql-virtual-mailbox-maps.cf /etc/postfix/mysql-virtual-mailbox-maps.cf && \
 ln -sf /config/postfix/relay_transport /etc/postfix/relay_transport && \
 ln -sf /config/postfix/transport /etc/postfix/transport && \
 ln -sf /config/postfix/virtual /etc/postfix/virtual && \
 ln -sf /config/postfix/header_checks /etc/postfix/header_checks
#ADD config/postfix/* /etc/postfix/

#Add dovecot config files, don't need to link these...I think?
ADD config/dovecot/10-* /etc/dovecot/conf.d/ 
ADD config/dovecot/auth-sql.conf.ext /etc/dovecot/conf.d/
RUN ln -sf /config/dovecot/dovecot-sql.conf.ext /etc/dovecot/dovecot-sql.conf.ext

#Link dkim configs
RUN ln -sf /config/dkim/opendkim.conf /etc/opendkim.conf && \
 ln -sf /config/dkim/keyfile /etc/postfix/keyfile && \
 ln -sf /config/dkim/sigfile /etc/postfix/sigfile && \
 ln -sf /config/dkim/TrustedHosts /etc/postfix/TrustedHosts && \
 ln -sf /config/dkim/default-opendkim /etc/default/opendkim && \
 ln -sf /config/dkim/keys /etc/postfix/dkim

#Add service file for starting all the things
ADD lib/service.sh /etc/postfix/

#Postmap specific files
RUN postmap /etc/postfix/virtual

#Do that permissions thing
