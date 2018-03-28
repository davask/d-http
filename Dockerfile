FROM davask/d-base:d8.x
MAINTAINER davask <docker@davaskweblimited.com>
USER root
LABEL dwl.server.http="apache 2.4-d8.x"

# Apache conf
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_RUN_DIR /var/run/apache2

ENV DWL_HTTP_SERVERADMIN admin@localhost
ENV DWL_HTTP_DOCUMENTROOT /var/www/html
ENV DWL_HTTP_SHIELD false
ENV DWL_APACHEGUI false

# Update packages
RUN apt-get update && \
apt-get install -y apache2 apache2-utils
RUN apt-get install -y default-jre
RUN apt-get clean && \
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configure apache
RUN a2enmod \
rewrite \
expires \
headers

COPY ./build/etc/apache2/apache2.conf /etc/apache2/apache2.conf
RUN a2enmod cgi

# proxy protection
RUN a2enmod remoteip

# Configure apache virtualhost.conf
COPY ./build/dwl/etc/apache2/sites-available /dwl/etc/apache2/sites-available
RUN a2dissite 000-default default-ssl && \
mv /etc/apache2/sites-available/000-default.conf /dwl/etc/apache2/sites-available/0000X_default_80.conf && \
mv /etc/apache2/sites-available/default-ssl.conf /dwl/etc/apache2/sites-available/0000X_default-ssl_443.conf
COPY ./build/dwl/var/www/html /dwl/var/www/html

EXPOSE 80

RUN wget https://github.com/jrossi227/ApacheGUI/releases/download/v1.12.0/ApacheGUI-1.12.0.tar.gz -P /tmp && \
tar -xvf /tmp/ApacheGUI-1.12.0.tar.gz -C /opt/ && \
rm -rdf /tmp/ApacheGUI-1.12.0.tar.gz

HEALTHCHECK --interval=5m --timeout=3s --retries=3 \
CMD curl -f http://localhost:80 || exit 1

WORKDIR /var/www

COPY ./build/dwl/apache2.sh \
./build/dwl/init.sh \
/dwl/

CMD ["/bin/bash /dwl/init.sh"]

RUN chmod +x /dwl/init.sh && chown root:sudo -R /dwl
USER admin
