#!/bin/bash

if [ ! -d /home/${DWL_USER_NAME}/files ]; then
    sudo mkdir -p /home/${DWL_USER_NAME}/files;
fi
if [ -d /var/www/html ]; then
    sudo rm -rdf /var/www/html;
fi
if [ -d /home/${DWL_USER_NAME}/files ] && [ ! -d /var/www/html ]; then
    sudo ln -sf /home/${DWL_USER_NAME}/files /var/www/html;
}
if [ ! -d ${DWL_HTTP_DOCUMENTROOT} ]; then
    mkdir ${DWL_HTTP_DOCUMENTROOT};
fi
if [ ! -f ${DWL_HTTP_DOCUMENTROOT}/index.html ]; then
    sudo cp /dwl/var/www/html/index.html ${DWL_HTTP_DOCUMENTROOT}/index.html
fi

if [ "${DWL_SHIELD_HTTP}" == "true" ]; then
    DWL_APACHE2_SHIELD="/dwl/shield";
    echo "Generate htpasswd with htpasswd -b -c '${DWL_APACHE2_SHIELD}/.htpasswd $DWL_USER_NAME $DWL_USER_PASSWD'";
    if [ ! -d ${DWL_APACHE2_SHIELD} ]; then
        sudo mkdir -p ${DWL_APACHE2_SHIELD};
    fi
    sudo htpasswd -b -c ${DWL_APACHE2_SHIELD}/.htpasswd $DWL_USER_NAME $DWL_USER_PASSWD;
    if [ ! -f /etc/apache2/sites-available/0000X_override.rules_0.conf ]; then
        sudo cp /dwl/etc/apache2/sites-available/0000X_override.rules_0.conf /etc/apache2/sites-available/0000X_override.rules_0.conf;
    fi
    if [ -f ${DWL_HTTP_DOCUMENTROOT}/.htaccess ]; then
        if [ "$(cat ${DWL_HTTP_DOCUMENTROOT}/.htaccess | grep "AuthType" | wc -l)" == "0" ]; then
            echo -e "
AuthType Basic
AuthName \"[dwl] protected\"
AuthUserFile /dwl/shield/.htpasswd
Require valid-user
" >> ${DWL_HTTP_DOCUMENTROOT}/.htaccess;
        fi
    else
        sudo cp /dwl/var/www/html/.htaccess ${DWL_HTTP_DOCUMENTROOT}/.htaccess;
    fi
    fi
fi

for conf in `sudo find /etc/apache2/sites-available -type f -name "*.conf"`; do

    DWL_USER_DNS_CONF=${conf};

    DWL_USER_DNS_DATA=`echo ${DWL_USER_DNS_CONF} | awk -F '[/]' '{print $5}' | sed "s|\.conf||g"`;

    echo "a2ensite ${DWL_USER_DNS_DATA}";

    sudo a2ensite ${DWL_USER_DNS_DATA};

done;

if [ "`sudo service apache2 status | grep 'apache2 is running' | wc -l`" == "0" ]; then
    sudo service apache2 start;
else
    sudo service apache2 reload;
fi
if [ "`sudo service apache2 status | grep 'apache2 is running' | wc -l`" == "0" ]; then
    sudo apachectl configtest;
fi
