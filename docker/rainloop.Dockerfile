FROM debian

ENV DEBIAN_FRONTEND noninteractive
ARG ini_domain

# Install apache, PHP, and supplimentary programs. openssh-server, curl, and lynx-cur are for debugging the container.
RUN apt-get update && apt-get -y upgrade && apt-get -y install \
    apache2 php php-mysql libapache2-mod-php wget unzip php-xml php-curl curl

# Enable apache mods.
#RUN a2enmod php7.0
RUN a2enmod rewrite
RUN a2enmod ssl

# Update the PHP.ini file, enable <? ?> tags and quieten logging.
#RUN sed -i "s/short_open_tag = Off/short_open_tag = On/" /etc/php/7.0/apache2/php.ini
#RUN sed -i "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" /etc/php/7.0/apache2/php.ini

RUN cd /tmp && wget -q https://www.rainloop.net/repository/webmail/rainloop-community-latest.zip && \
 mkdir /var/www/rainloop && unzip -q /tmp/rainloop-community-latest.zip -d /var/www/rainloop

ADD config/rainloop/domain.ini /var/www/rainloop/data/_data_/_default_/domains/$ini_domain.ini

RUN find /var/www/rainloop -type d -exec chmod 755 {} \; \
 && find /var/www/rainloop -type f -exec chmod 644 {} \; \
 && chown -R www-data:www-data /var/www/rainloop


# Manually set up the apache environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

# Expose apache.
EXPOSE 80

# Copy this repo into place.
#ADD www /var/www/site

# Update the default apache site with the config we created.
ADD config/apache/apache-config.conf /etc/apache2/sites-enabled/000-default.conf

# By default start up apache in the foreground, override with /bin/bash for interative.
CMD /usr/sbin/apache2ctl -D FOREGROUND

