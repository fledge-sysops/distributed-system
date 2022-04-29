#!/bin/bash
set -e

#create deployment user and set password
if [ ! -f docker_initialized ]; then
        mkdir -p /var/www/html/$project_name
        useradd -s /bin/bash -d /var/www/html/$project_name -m $dev_user
        chown -R $dev_user: /var/www/html/$project_name
        useradd -d /phpmyadmin -s /bin/false $pma_user
        chown -R $pma_user: /phpmyadmin
        usermod -p $(echo $dev_password | openssl passwd -1 -stdin) $dev_user
        usermod -p $(echo $root_password | openssl passwd -1 -stdin) root
        cp -r /etc/skel/. /var/www/html/$project_name
        usermod -a -G $pma_user,$dev_user nginx
        touch docker_initialized
fi
exec "$@"
