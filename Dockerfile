FROM davask/d-http:a2.4-d9.x

MAINTAINER davask <docker@davaskweblimited.com>
USER root
# Apache conf
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_RUN_DIR /var/run/apache2

ENV DWL_HTTP_SERVERADMIN docker@davaskweblimited.com
ENV DWL_HTTP_DOCUMENTROOT /var/www/html
ENV DWL_HTTP_SHIELD false

# declare openssl
ENV APACHE_SSL_DIR ${CONF_HTTP_SSL_DIR}
ENV DWL_SSLKEY_C "EU"
ENV DWL_SSLKEY_ST "France"
ENV DWL_SSLKEY_L "Vannes"
ENV DWL_SSLKEY_O "davask web limited - docker container"
ENV DWL_SSLKEY_CN "davaskweblimited.com"

# Update packages
RUN apt-get update && \
apt-get install -y apache2 apache2-utils
RUN apt-get upgrade -y && \
apt-get autoremove -y && \
apt-get clean && \
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configure apache
RUN a2enmod \
rewrite \
expires \
headers

COPY ./build/dwl/etc/apache2/apache2.conf /dwl/etc/apache2/apache2.conf
RUN cp -rdf /dwl/etc/apache2/apache2.conf /etc/apache2/apache2.conf
RUN a2enmod cgi

# proxy protection
RUN a2enmod remoteip

RUN a2dissite 000-default && rm -f /etc/apache2/sites-available/000-default.conf
RUN a2dissite default-ssl && rm -f /etc/apache2/sites-available/default-ssl.conf

# Configure apache virtualhost.conf
COPY ./build/dwl/etc/apache2/sites-available /dwl/etc/apache2/
COPY ./build/dwl/shield/var/www/html/.htaccess /dwl/shield/var/www/html/.htaccess

EXPOSE 80

HEALTHCHECK --interval=5m --timeout=3s \
CMD curl -f http://localhost/ || exit 1

COPY ./build/dwl/var/www/html /dwl/var/www/html
RUN rm -rdf /var/www/html && cp -rdf /dwl/var/www/html /var/www

WORKDIR /var/www

COPY ./build/dwl/vhost-env.sh \
./build/dwl/activateconf.sh \
./build/dwl/virtualhost.sh \
./build/dwl/apache2.sh \
./build/dwl/init.sh \
/dwl/

CMD ["/bin/bash /dwl/init.sh"]

# create apache2 ssl directories
RUN mkdir -p ${APACHE_SSL_DIR}
RUN chmod 700 ${APACHE_SSL_DIR}

RUN rm -f /etc/apache2/sites-enabled/default-ssl.conf &>> null
RUN rm -f /etc/apache2/sites-available/default-ssl.conf &>> null

COPY ./build/dwl/etc/apache2/mods-available/ssl.conf /etc/apache2/mods-available/ssl.conf
RUN a2enmod ssl

# Configure apache virtualhost.conf
COPY ./build/dwl/etc/apache2/sites-available/0000_docker.davaskweblimited.com_443.conf.dwl /dwl/etc/apache2/sites-available/0000_docker.davaskweblimited.com_443.conf.dwl

EXPOSE 443

COPY ./build/dwl/openssl.sh \
./build/dwl/virtualhost-ssl.sh \
./build/dwl/init.sh \
/dwl/
RUN chmod +x /dwl/init.sh && chown root:sudo -R /dwl
USER admin
