#!/bin/bash
##创建索引，需要提前安装dpkg-dev
#cd /data01/source/
#dpkg-scanpackages packages  /dev/null  | gzip > packages/Packages.gz
set -e

package_dir=/data01/package

##此目录是创建索引时使用，不能修改
deb_package_dir=/data01/source/packages

mkdir -p ${deb_package_dir}
chmod 0777 ${deb_package_dir}
mv ${package_dir}/source/*  ${deb_package_dir}/

##配置自定义源
mv /etc/apt/sources.list /etc/apt/sources.list.bak
cat >> /etc/apt/sources.list <<EOF
deb [trusted=yes] file://${deb_package_dir%/*} ${deb_package_dir##*/}/
EOF

[ $? -eq 0 ] && apt-get update || exit 1

##安装ansible
apt-get install -y ansible > /dev/null
[ -d /etc/ansible ] && echo "ansible 安装完成" || echo "ansible 安装出错，请检查自定义安装源"

##安装sshpass
apt-get install -y sshpass > /dev/null
sshpass > /dev/null
[ $? -eq 0 ] && echo "sshpass 安装完成" || echo "sshpass 安装出错，请检查自定义安装源"


##安装Apache，默认使用80端口，与harbor使用80端口冲突
apt-get install -y apache2  > /dev/null
[ -d /var/www/html ] && echo "apache 安装完成" || echo "apache 安装出错，请检查自定义安装源"

##创建软连接，便于局域网内其他服务器使用本机源
ln -s ${deb_package_dir%/*} /var/www/html/ubuntu-local

##创建秘钥，ansible机器免密连接所有的服务器，需要在放开，默认关闭
ssh-keygen -t rsa -f ~/.ssh/id_rsa -P '' > /dev/null
[ $? -eq 0 ] && echo "秘钥创建成功" || echo "秘钥创建失败，请手动创建秘钥"
