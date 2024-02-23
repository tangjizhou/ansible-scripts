#!/bin/bash
#禁用uid为0的非root账号
for user in $(awk -F: '($3==0)' /etc/passwd | grep -v root)
do
echo $user
/usr/sbin/usermod -L $user > /dev/null 2>&1
done

#禁用空口令账号
for user in $(awk -F: '$2=="!!" {print $1}' /etc/shadow)
do
echo $user
passwd -l $user
done

#禁用非交互式账户
for NAME in `cut -d: -f1 /etc/passwd`
do
    MyUID=`id -u $NAME`
    value=`/usr/bin/passwd -S "$NAME" 2>/dev/null | grep "in use"`
    ulock=$?
    if [ $MyUID -lt 1000 -a $NAME != 'root' -a $ulock -eq 0 ];then
      usermod -L -s /dev/null $NAME
    fi
done
/usr/sbin/usermod -L -s /dev/null nfsnobody > /dev/null 2>&1
exit 0
