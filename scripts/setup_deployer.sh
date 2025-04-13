#!/bin/bash

# 배포할 사용자 계정명
USER=deployer

# 비밀번호 입력받기 (입력시 안 보임)
read -sp "Enter password for ${USER} user: " PASSWORD
echo
read -sp "Confirm password: " PASSWORD2
echo

# 비밀번호 확인
if [ "$PASSWORD" != "$PASSWORD2" ]; then
  echo "Error: Passwords do not match."
  exit 1
fi

# 계정 생성
echo "Creating user: $USER"
adduser --disabled-password --gecos "" $USER

# 비밀번호 설정
echo "${USER}:${PASSWORD}" | chpasswd

# www-data 그룹 추가
usermod -aG www-data $USER

# sudo 권한 설정 (비밀번호 없이 가능)
echo "Configuring sudoers for $USER..."

cat <<EOF | sudo tee -a /etc/sudoers

# deployer 계정에 대한 권한 부여
${USER} ALL=(ALL:ALL) NOPASSWD: ALL

# www-data 그룹에 대한 권한 부여
%www-data ALL=(ALL:ALL) NOPASSWD:/usr/sbin/service php8.4-fpm restart, /usr/sbin/service nginx restart
EOF

echo "User $USER created and added to www-data group."
echo "Login with: ssh $USER@your-server-ip"
