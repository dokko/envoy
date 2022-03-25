e "GRANT ALL ON *.* TO 'root'@'0.0.0.0' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
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

# apt-get install -y \
#     redis-server \
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
