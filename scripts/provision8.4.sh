#!/usr/bin/env bash

##
#--------------------------------------------------------------------------
# BEFORE RUN THE SCRIPT, YOU MUST DO THE FOLLOWING.
#--------------------------------------------------------------------------
#
#   WITHOUT FOLLOWING CONFIGURATION CHANGE, YOU MAY ENCOUNTER:
#   "sudo: no tty present and no askpass program specified ...",
#
#   RUN THIS COMMAND TO EDIT /etc/sudoers.
#   user@server:~$ sudo -s
#   root@server:~# visudo
#
#   ADD THE FOLLOWING LINES TO THE FILE AND SAVE.
#   (We assume username you are going to use is 'deployer')
#
#   deployer ALL=(ALL:ALL) NOPASSWD: ALL
#   %www-data ALL=(ALL:ALL) NOPASSWD:/usr/sbin/service php7.3-fpm restart,/usr/sbin/service nginx restart
##

##
#--------------------------------------------------------------------------
# How to run
#--------------------------------------------------------------------------
#
#   user@server:~$ sudo -s
#   root@server:~# wget https://raw.githubusercontent.com/appkr/envoy/master/scripts/provision.sh
#   root@server:~# bash provision.sh deployer | tee log.txt
##

##
# House keeping: makes script not running without proper arguments.
##

if [[ -z "$1" ]]
then
  echo "Error: missing required parameters."
  echo "Usage: "
  echo "  bash provision.sh username"
  echo "    username    : OS and mysql username"
  exit
fi

##
# Set variables and makes the job not be interrupted by interactive questions.
##

export DEBIAN_FRONTEND=noninteractive
USERNAME=$1


##
# Update package list & update system packages.
##

apt-get update
apt-get -y upgrade

##
# Force Locale.
##

echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
locale-gen en_US.UTF-8

##
# Install apt-add-repository extension.
# Install some PPAs(Personal Package Archive).
##

sudo LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php # Press enter to confirm.
sudo apt update

sudo apt install php8.4-cli php8.4-fpm unzip nginx

sudo apt install php8.4-common php8.4-{bcmath,bz2,curl,gd,gmp,intl,mbstring,opcache,readline,xml,zip}


##
# Set timezone.
# Set server timezone to UTC is the BEST PRACTICE.
##

ln -sf /usr/share/zoneinfo/UTC /etc/localtime

##
# Install composer.
# Composer is a PHP's standard (library) dependency manager.
# @see https://getcomposer.org
##


curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer


##
# Set PHP CLI configuration.
##

sed -i "s/expose_php = .*/expose_php = Off/" /etc/php/8.4/cli/php.ini
# Commented out because out-of-box value is already confitured for production.
# sed -i "s/error_reporting = .*/error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT/" /etc/php/8.4/cli/php.ini
sed -i "s/display_errors = .*/display_errors = Off/" /etc/php/8.4/cli/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/8.4/cli/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php/8.4/fpm/php.ini
sed -i "s/post_max_size = .*/post_max_size = 100M/" /etc/php/8.4/fpm/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/8.4/cli/php.ini

# upload_max_filesize = 32M 
# post_max_size = 48M 
# memory_limit = 256M 
# max_execution_time = 600 
# max_input_vars = 3000 
# max_input_time = 1000

# Install Nginx & PHP-FPM.

rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
service nginx restart

##
# Setup PHP-FPM configurations
##

sed -i "s/expose_php = .*/expose_php = Off/" /etc/php/8.4/fpm/php.ini
# Commented out because out-of-box value is already confitured for production.
# sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/8.4/fpm/php.ini
sed -i "s/display_errors = .*/display_errors = Off/" /etc/php/8.4/fpm/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/8.4/fpm/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php/8.4/fpm/php.ini
sed -i "s/post_max_size = .*/post_max_size = 100M/" /etc/php/8.4/fpm/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/8.4/fpm/php.ini
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/8.4/fpm/php.ini

##
# Disable xdebug on the CLI.
##

sudo phpdismod -s cli xdebug

# Copy fastcgi_params to Nginx because they broke it on the PPA

cat > /etc/nginx/fastcgi_params << EOF
fastcgi_param   QUERY_STRING        \$query_string;
fastcgi_param   REQUEST_METHOD      \$request_method;
fastcgi_param   CONTENT_TYPE        \$content_type;
fastcgi_param   CONTENT_LENGTH      \$content_length;
fastcgi_param   SCRIPT_FILENAME     \$request_filename;
fastcgi_param   SCRIPT_NAME         \$fastcgi_script_name;
fastcgi_param   REQUEST_URI         \$request_uri;
fastcgi_param   DOCUMENT_URI        \$document_uri;
fastcgi_param   DOCUMENT_ROOT       \$document_root;
fastcgi_param   SERVER_PROTOCOL     \$server_protocol;
fastcgi_param   GATEWAY_INTERFACE   CGI/1.1;
fastcgi_param   SERVER_SOFTWARE     nginx/\$nginx_version;
fastcgi_param   REMOTE_ADDR         \$remote_addr;
fastcgi_param   REMOTE_PORT         \$remote_port;
fastcgi_param   SERVER_ADDR         \$server_addr;
fastcgi_param   SERVER_PORT         \$server_port;
fastcgi_param   SERVER_NAME         \$server_name;
fastcgi_param   HTTPS               \$https if_not_empty;
fastcgi_param   REDIRECT_STATUS     200;
EOF

##
# Set Nginx & PHP-FPM user
##

sed -i "s/user www-data;/user ${USERNAME};/" /etc/nginx/nginx.conf
sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf

sed -i "s/user = www-data/user = ${USERNAME}/" /etc/php/8.4/fpm/pool.d/www.conf
sed -i "s/group = www-data/group = ${USERNAME}/" /etc/php/8.4/fpm/pool.d/www.conf

sed -i "s/listen\.owner.*/listen.owner = ${USERNAME}/" /etc/php/8.4/fpm/pool.d/www.conf
sed -i "s/listen\.group.*/listen.group = ${USERNAME}/" /etc/php/8.4/fpm/pool.d/www.conf
sed -i "s/;listen\.mode.*/listen.mode = 0666/" /etc/php/8.4/fpm/pool.d/www.conf

service nginx restart
service php8.4-fpm restart

##
# Install MySQL.
##

wget https://dev.mysql.com/get/mysql-apt-config_0.8.22-1_all.deb
dpkg -i mysql-apt-config_0.8.22-1_all.deb
apt update

debconf-set-selections <<< "mysql-community-server mysql-community-server/data-dir select ''"
debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password secret"
debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password secret"
apt install -y mysql-server

##
# Configure MySQL password lifetime.
##

# Comment out to avoid error.
# echo "default_password_lifetime = 0" >> /etc/mysql/my.cnf

##
# Configure MySQL to be accessible from a remote computer.
##

sed -i '/^bind-address/s/bind-address.*=.*/bind-address = 0.0.0.0/' /etc/mysql/my.cnf

##
# Grant root user's privilege against MySql
##

mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO 'root'@'localhost' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO 'root'@'0.0.0.0' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
service mysql restart

##
# Create MySql user account provided by you.
# Grant root user's privilege against MySql.
##

mysql --user="root" --password="secret" -e "CREATE USER '${USERNAME}'@'localhost' IDENTIFIED BY 'secret';"
mysql --user="root" --password="secret" -e "CREATE USER '${USERNAME}'@'0.0.0.0' IDENTIFIED BY 'secret';"

mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO '${USERNAME}'@'0.0.0.0' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO '${USERNAME}'@'%' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
mysql --user="root" --password="secret" -e "FLUSH PRIVILEGES;"

service mysql restart

##
# Add timezone support to MySQL
##

mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql --user=root --password=secret mysql

##
# Install Postgres.
##

# apt-get install -y postgresql

##
# Configure Postgres's remote access.
##

# Configure Postgres Remote Access

# sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/9.5/main/postgresql.conf
# echo "host all all 10.0.2.2/32 md5" | tee -a /etc/postgresql/9.5/main/pg_hba.conf
# sudo -u postgres psql -c "CREATE ROLE ${USERNAME} LOGIN UNENCRYPTED PASSWORD 'secret' SUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;"

# service postgresql restart

##
# Install Redis, Memche, Beanstalk
##

 apt-get install -y \
     redis-server
#     memcached \
#     beanstalkd;

##
# Configure Beanstalk & start it.
##

# sed -i "s/#START=yes/START=yes/" /etc/default/beanstalkd
# /etc/init.d/beanstalkd start

##
# Configure Supervisor & start it.
##

systemctl enable supervisor.service
service supervisor start

# Enable Swap Memory

# /bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=1024
# /sbin/mkswap /var/swap.1
# /sbin/swapon /var/swap.1
