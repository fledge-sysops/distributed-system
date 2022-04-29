Docker Installation 
Install Docker on the host machine.
```
sudo apt-get update

sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

```
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

```
```
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

```
```
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

```
Reference Link:
https://docs.docker.com/engine/install/ubuntu/
-------------------------------------------------------------------------------------------------------------------------------------------


Create Application Image
```
Cloen the repository https://github.com/fledge-sysops/distributed-system.git
```
or

Download zip and extartc to the /root/home
```
cd  /root/home/distributed-system
docker build -t magento-app-server .

-------------------------------------------------------------------------------------------------------------------------------------------
Step 1: Create Directory on Host machine where docker install.
mkdir -p cd /var/www/html
cd /var/www/html
mkdir webroot
mkdir backup
mkdir config

-------------------------------------------------------------------------------------------------------------------------------------------
Step 2: Create mysql container
percona:5.7
docker run -itd --name=magento.db --hostname=database --restart=always -e MYSQL_ROOT_PASSWORD=root@123 -p 3905:3306 -v /local/datadir:/var/lib/mysql percona:5.7

mariadb:10.2
docker run -itd --name=magento.db -p 3905:3306 -e MARIADB_USER=magento -e MARIADB_PASSWORD=magento@123 -e MARIADB_DATABASE=magento -e MARIADB_ROOT_PASSWORD=root@123  mariadb:10.2

-------------------------------------------------------------------------------------------------------------------------------------------
Step 3: Create elasticsearch container
FROM elasticsearch:7.9.0
docker run -itd --restart=always --name elsearch790 -p 4305:9200 -p 4306:9300 -e "discovery.type=single-node" elasticsearch:7.9.0

-------------------------------------------------------------------------------------------------------------------------------------------
step 4: create redis container
FROM redis
docker run -itd --restart=always --name magento.redis -p 4405:6379 elasticsearch:7.9.0

-------------------------------------------------------------------------------------------------------------------------------------------
Step 5: command to launch application container
docker run -itd --name=magento.app --hostname=magento -e dev_user=magento -e dev_password=magento@123 -e pma_user=pma -e project_name=magento -e root_password=root@123 -p 4505:80 -p 4506:22 --link magento.db:dbs --link elsearch790:els --link magento.redis:redis -v /var/www/html:/var/www/html/magento --restart=always magento-app-server

-------------------------------------------------------------------------------------------------------------------------------------------
step 6: Install nginx on the host machine
wget http://nginx.org/keys/nginx_signing.key
apt-key add nginx_signing.key
echo "deb http://nginx.org/packages/ubuntu/ focal nginx" >> /etc/apt/sources.list
echo "deb-src http://nginx.org/packages/ubuntu/ focal nginx" >> /etc/apt/sources.list
apt-get -y update
apt-get install -y nginx
-------------------------------------------------------------------------------------------------------------------------------------------
step 7: Configure Nginx.
Update optimize nginx.conf
vim /etc/nginx/nginx.conf

user  nginx;
worker_processes auto;
worker_rlimit_nofile 100000;
pid /var/run/nginx.pid;

events {
        worker_connections 1024;
        use epoll;
        multi_accept on;
}

http {
        include /etc/nginx/mime.types;
        default_type  application/octet-stream;
        access_log off;
        error_log /var/log/nginx/error.log notice;
        rewrite_log on;
        log_format  main  '$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent" "$http_x_forwarded_for"';

        keepalive_timeout 65;
        keepalive_requests 100000;
        sendfile on;
        tcp_nopush on;
        tcp_nodelay on;

        autoindex off;
        server_tokens off;
        port_in_redirect off;

        client_body_buffer_size      512k;
        client_header_buffer_size    8k;
        large_client_header_buffers  4 32k;
        output_buffers               1 32k;
        postpone_output              1460;

        client_header_timeout  3m;
        client_body_timeout    3m;
        send_timeout           3m;
#        fastcgi_read_timeout 500;		# 

        open_file_cache max=10000 inactive=100s;
        open_file_cache_valid 7200s;
        open_file_cache_min_uses 5;
        open_file_cache_errors off;

        types_hash_max_size 4096;
        client_max_body_size 200m;
        server_names_hash_bucket_size 128;

#       real_ip_header X-Forwarded-For;
        real_ip_recursive on;
        set_real_ip_from 0.0.0.0/0;
#       set_real_ip_from 127.0.0.1;

        gzip on;
        gzip_comp_level 2;
        gzip_http_version 1.0;
        gzip_proxied expired no-cache no-store private auth;
        gzip_min_length 1100;
        gzip_buffers 16 8k;
        gzip_types text/plain text/css application/octet-stream  application/json application/x-javascript application/javascript text/xml application/xml application/xml+rss text/javascript font/ttf application/font-woff font/opentype application/vnd.ms-fontobject image/svg+xml;
        gzip_disable "MSIE [1-6].(?!.*SV1)";
        gzip_vary on;

#Cloudflare

        include /etc/nginx/cloudflare.conf;

        include /etc/nginx/conf.d/*.conf;
}

-------------------------------------------------------------------------------------------------------------------------------------------
step 8: Nginx magento Virtual host
Add proxy.conf to conf.d/example.conf

server {
        listen 80;
        server_name example.com;
        return 301 https://example.com/;
}

server {
        listen 443 ssl;
        server_name example.com;

        ssl_certificate /etc/nginx/ssl/star.example.net.crt;
        ssl_certificate_key /etc/nginx/ssl/star.example.net.key;

        ssl_session_timeout 1m;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;


        access_log /var/log/nginx/magento-access.log;
        error_log /var/log/nginx/magento-error.log debug;

client_max_body_size 20M;

location / {
        proxy_pass            http://127.0.0.1:4505;	#Container web port for magento,
        proxy_read_timeout    90;
        proxy_connect_timeout 90;
        proxy_redirect        off;
        proxy_set_header      X-Real-IP $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header      X-Forwarded-Proto https;
        proxy_set_header      X-Forwarded-Port 443;
        proxy_set_header      Host $host;
    }

location /dbs {
        proxy_pass            http://127.0.0.1:4505/dbs; 	#Container web port for phpmyadmin access,
        proxy_read_timeout    90;
        proxy_connect_timeout 90;
        proxy_redirect        off;
        proxy_set_header      X-Real-IP $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header      X-Forwarded-Proto https;
        proxy_set_header      X-Forwarded-Port 443;
        proxy_set_header      Host $host;
    }

}
-------------------------------------------------------------------------------------------------------------------------------------------
