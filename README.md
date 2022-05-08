#### Docker Installation and Application Image creation
Install Docker on the host machine.
```
sudo apt-get update

sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
    
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
```
Reference Link:
https://docs.docker.com/engine/install/ubuntu/
```
#### Create Application Image
Create custom image for web-application server using the dockerfile.
```
cd /home/root

Cloen the repository https://github.com/fledge-sysops/distributed-system.git
or
Download zip and extract to the /root/home

Repository or extracted files will be found on new direcoy - distributed-system under /root/home.
cd  /root/home/distributed-system

Apply below command to create application server container to host magento application.  
$ docker build -t magento-app-server . 

The above coommand will start create an application docker image locally.
You can found image with below command after sucessfuly processed.

$ docker images

```
-------------------------------------------------------------------------------------------------------------------------------------------
### Create Directory on Host machine where docker install.
```
mkdir -p cd /var/www/html
cd /var/www/html
mkdir webroot
mkdir backup
mkdir config
````
```Copy file form additional directory - app.conf to the path /var/www/html/config```

Directory linking path between host machine and containers.

| Directory  | Host Machine Path | Container Path  | Contaiiner
|---|---|---|---|
|MySQL Data|/var/www/mysql|/var/lib/mysql|Database Container
|Project Webroot|/var/www/html/webroot|/var/www/html/magento/webroot|Application Container
|Backup Directory|/var/www/html/backup|/var/www/html/magento/backup|Application Container
|Config Directory|/var/www/html/config|/var/www/html/magento/config|Application Container

Magento code should be host inside the web container - ***/var/www/html/magento/webroot***

-------------------------------------------------------------------------------------------------------------------------------------------

# Manual Container Creation Process
### Step 1: Create mysql container
You can choess any of the mysql image suitable to your application.
```
percona:5.7
$ docker run -itd --name=magento.db --hostname=database --restart=always -e MYSQL_ROOT_PASSWORD=root@123 -p 3905:3306 -v /local/datadir:/var/lib/mysql percona:5.7

or

mariadb:10.2
$ docker run -itd --name=magento.db -p 3905:3306 -e MARIADB_USER=magento -e MARIADB_PASSWORD=magento@123 -e MARIADB_DATABASE=magento -e MARIADB_ROOT_PASSWORD=root@123  mariadb:10.2
```
-------------------------------------------------------------------------------------------------------------------------------------------
### Step 2: Create elasticsearch container
```
$ docker run -itd --restart=always --name elsearch790 -p 4305:9200 -p 4306:9300 -e "discovery.type=single-node" elasticsearch:7.9.0
```
-------------------------------------------------------------------------------------------------------------------------------------------
### Step 3: Create redis container
```
$ docker run -itd --restart=always --name magento.redis -p 4405:6379 redis:5.0
```
-------------------------------------------------------------------------------------------------------------------------------------------
### Step 4: Command to launch application container
```
$ docker run -itd --name=magento.app --hostname=magento -e dev_user=magento -e dev_password=magento@123 -e pma_user=pma -e project_name=magento -e root_password=root@123 -p 4505:80 -p 4506:22 --link magento.db:dbs --link elsearch790:els --link magento.redis:redis -v /var/www/html:/var/www/html/magento --restart=always magento-app-server
```
-------------------------------------------------------------------------------------------------------------------------------------------
# Docker Compose Container Creation

Staging Environmnet:
```
$ docker compose up -d
```
With the file ```depends_on:``` as the note point, Compose have specified condition in the file. Before launching the app/web container, it will create a dependency container with ```links:``` that connects the dependency container service.



Staging Configuration file path:  ```additional-files/staging/docker-compose.yml```
Production Configuration file path:  ```additional-files/production/docker-compose.yml```

```Note: Production docker-compose.yml file has only application container creation configuration. We can use other standalone and distributed hosted servcers or managed services as solution.```

-------------------------------------------------------------------------------------------------------------------------------------------
# Nginx Installation and Reverse Proxy Configuration
### Install nginx on the host machine
```
wget http://nginx.org/keys/nginx_signing.key
apt-key add nginx_signing.key
echo "deb http://nginx.org/packages/ubuntu/ focal nginx" >> /etc/apt/sources.list
echo "deb-src http://nginx.org/packages/ubuntu/ focal nginx" >> /etc/apt/sources.list
apt-get -y update
apt-get install -y nginx
```

### Configure Nginx
Update optimize nginx.conf on Host machine.
vim /etc/nginx/nginx.conf
```
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
```



### Nginx Reverse Proxy Virtual host configuration on host machine.
Add proxy configuration to conf.d/example.conf
```
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
```

-------------------------------------------------------------------------------------------------------------------------------------------
### Command to connect the service from application container

Access to the application/web-server container.(magento application hosted container)
```
$ docker exec -it magento.app bash
```

Get the details for the linked containers to the application.
```
$ docker exec -it magento.app bash
cat /etc/hosts
```

You can have access to the containers from the application server using below commnads:
Database 
```
Root User:  mysql -h dbs -u root -proot@123
DB User:  mysql -h dbs -u magento -pmagento@123
```
```For any of the Database serveice user hostname as "dbs"```

Redis
```
redis-cli -h redis
```
```For any of the redis serveice user hostname as "redis"```

Elasticsearch
```
curl els:9200
```
```For any of the Elasticsearch serveice user hostname as "els"```

-------------------------------------------------------------------------------------------------------------------------------------------

Note: Server Name inside the container should be change on nginx configuration and if you manage to proxy on host machine mentaion in step 6.

```
Inside the Web Container
$ docker exec -it magento.app bash

vim /etc/nginx/conf.d/default.conf
Line no 11
server_name example.com  default_server; #servername should be the change

You have to change example.com to your website URL.
```


