# LEMP Production Server Build
Ubuntu Server 16.04 LTS (Xenial Xerus) - LEMP Full Stack Server Build
Build with most secure web server nginx, trusted database server percona mysql server with run dynamic php script php7.3-fpm.
Also enhance application performnace with most trusted cache servr as varnish and data key value store as redis server.
Application configured with built in Mail service with Postfix.

# Commnad to Launch Container.
docker run -itd --name=web-server --hostname=magento -e project_name=latest -e pma_user=pma -e dev_user=magento -e dev_password=magento123 -e root_password=root123  -e dev_user_dir=/var/www/html --restart=always ktpl00/lemp-php7.3
