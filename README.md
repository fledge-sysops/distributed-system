# LEMP Production Server Build

# Commnad to Launch Container.
docker run -itd --name=web-server --hostname=magento -e project_name=latest -e pma_user=pma -e dev_user=magento -e dev_password=magento123 -e root_password=root123  -e dev_user_dir=/var/www/html --restart=always fledgedigital/lemp-php7.3
