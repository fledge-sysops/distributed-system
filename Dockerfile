from ubuntu:20.04

MAINTAINER Fledge Digital <sysops@fledgedigital.com>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y sudo vim \
    && apt-get install -y software-properties-common \
    && apt-get install -y apt-transport-https \
    && apt-get install -y build-essential \
    && apt-get install -y libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev \
    && apt-get install -y wget \
    && apt-get install -y cron \
    && apt-get install -y curl \
    && apt-get install -y rsync \
    && apt-get install -y git \
    && apt-get install -y supervisor \
    && apt-get install -y psmisc \
    && apt-get install -y tree \
    && apt-get install -y rsyslog \ 
    && apt-get install -y lsb \
    && apt-get install -y openssh-server \
    && mkdir /var/run/sshd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && /etc/init.d/ssh restart \
    && apt-get install -y language-pack-en-base \
    && apt-get update \
    && locale-gen en_US.UTF-8 \
    && export LANG=en_US.UTF-8 \
    && LC_ALL=en_US.UTF-8 \
    && apt-get update \
    && cd /tmp/ \
    && wget http://nginx.org/keys/nginx_signing.key \
    && apt-key add nginx_signing.key \
    && echo "deb http://nginx.org/packages/ubuntu/ bionic nginx" >> /etc/apt/sources.list \
    && echo "deb-src http://nginx.org/packages/ubuntu/ bionic nginx" >> /etc/apt/sources.list \
    && apt-get -y update \
    && apt-get install -y nginx \
    && apt-get install -y apache2-utils \
    && apt-get install -y debconf-utils \
    && apt-get install -y mysql-client \
    && LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php \
    && apt-get update \
    && apt-get install -y php7.3-fpm php7.3-mysql \
    && apt-get install -y php7.3-cli php7.3-common php7.3-json php7.3-opcache php7.3-gd php7.3-intl php7.3-gd php7.3-curl \
    && apt-get install -y  php7.3-mbstring php7.3-zip php7.3-xml php7.3-soap php7.3-bcmath php7.3-xmlrpc \
    && mkdir /var/run/php \
    && cd / \
    && wget https://files.phpmyadmin.net/phpMyAdmin/4.6.4/phpMyAdmin-4.6.4-english.tar.gz \
    && tar xvzf phpMyAdmin-4.6.4-english.tar.gz \
    && mv phpMyAdmin-4.6.4-english /phpmyadmin \
    && rm -rf phpMyAdmin-4.6.4-english.tar.gz \
    && cp /phpmyadmin/config.sample.inc.php /phpmyadmin/config.inc.php \
    && apt-get update \
    && wget https://getcomposer.org/download/1.10.10/composer.phar \
    && mv /composer.phar /usr/local/bin/composer \
    && chmod +x /usr/local/bin/composer
    
    
ADD tools/docker/nginx/nginx.conf /etc/nginx/nginx.conf
ADD tools/docker/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
ADD tools/docker/nginx/conf.d/pma.conf /etc/nginx/conf.d/pma.conf
ADD tools/docker/php73fpm/cli/php.ini /etc/php/7.3/cli/php.ini
ADD tools/docker/php73fpm/fpm/php.ini /etc/php/7.3/fpm/php.ini
ADD tools/docker/php73fpm/fpm/php-fpm.conf /etc/php/7.3/fpm/php-fpm.conf
ADD tools/docker/php73fpm/fpm/pool.d/www.conf /etc/php/7.3/fpm/pool.d/www.conf
ADD tools/docker/php73fpm/fpm/pool.d/pma.conf /etc/php/7.3/fpm/pool.d/pma.conf
ADD tools/docker/supervisor/supervisord.conf /etc/supervisor/supervisord.conf
ADD tools/docker/supervisor/conf.d/apps.conf /etc/supervisor/conf.d/apps.conf
ADD tools/docker/scripts/start.sh /start.sh
ADD tools/docker/scripts/entrypoint.sh /entrypoint.sh
ADD tools/docker/scripts/user.sh /user.sh

RUN chmod +x /*.sh

EXPOSE 22 80 443

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
CMD ["/bin/bash", "/start.sh"]
