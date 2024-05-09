sudo -s
adduser deployer
usermod -G www-data deployer
visudo


# deployer 계정에 대한 권한 부여
deployer ALL=(ALL:ALL) NOPASSWD: ALL

# www-data 그룹에 대한 권한 부여
%www-data ALL=(ALL:ALL) NOPASSWD:/usr/sbin/service php8.2-fpm restart,/usr/sbin/service nginx restart


cd ~
wget https://raw.githubusercontent.com/dokko/envoy/master/scripts/provision8.2.sh
wget https://raw.githubusercontent.com/dokko/envoy/master/scripts/serve8.2.sh
bash provision8.2.sh deployer secret
bash serve8.2.sh ec2-18-141-246-109.ap-southeast-1.compute.amazonaws.com /home/deployer/www/dari/main/public
mkdir /home/deployer/.ssh
chown deployer:deployer /home/deployer/.ssh
cp /home/ubuntu/.ssh/authorized_keys /home/deployer/.ssh/
chown deployer:deployer -R /home/deployer/.ssh




ssh-keygen -t rsa -b 4096 -C "jw.lee@linppl.com"
cat .ssh/id_rsa.pub
ssh -T git@github.com
