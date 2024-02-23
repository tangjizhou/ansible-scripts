#!/bin/bash

set -e
ansible_playbook="authorized.yaml"

for sub_ansible_playbook in ${ansible_playbook[@]}
do
  /usr/bin/ansible-playbook -i inventory/dc1-prod-online/hosts.ini playbook/${sub_ansible_playbook} --list-hosts
  /usr/bin/ansible-playbook -i inventory/dc1-prod-offline/hosts.ini playbook/${sub_ansible_playbook} --list-hosts
done

sleep 200
# 互信
/usr/bin/ansible-playbook -i inventory/dc1-prod-online/hosts.ini playbook/authorized.yaml
/usr/bin/ansible-playbook -i inventory/dc1-prod-offline/hosts.ini playbook/authorized.yaml

# 修改解释器为/bin/bash
/usr/bin/ansible-playbook -i inventory/dc1-prod-online/hosts.ini playbook/install-bash.yaml
/usr/bin/ansible-playbook -i inventory/dc1-prod-offline/hosts.ini playbook/install-bash.yaml

[ $? -ne 0 ] && exit || continue

# 服务器初始化--未单独分离，此步骤不做
#/usr/bin/ansible-playbook -i inventory/dc1/hosts.ini playbook/install-init.yaml


# harbor安装，安装完成获取输出的用户密码，创建namespace下面的imagePullSecret
if [ $? -eq 0 ];then
  /usr/bin/ansible-playbook -i inventory/dc1-prod-online/hosts.ini playbook/install-harbor.yaml
fi
# nginx 安装 --done
/usr/bin/ansible-playbook -i inventory/dc1-prod-online/hosts.ini playbook/install-nginx.yaml
## fixme offline-nginx安装后需要手动修改filebeat的yaml文件中kafka地址，需要修改与online-nginx相同
/usr/bin/ansible-playbook -i inventory/dc1-prod-offline/hosts.ini playbook/install-nginx.yaml

# k8s安装
# online-k8s --done
/usr/bin/ansible-playbook -i inventory/dc1-prod-online/hosts.ini playbook/install-kubernetes-cluster-containerd.yaml
# offline-k8s  --done
/usr/bin/ansible-playbook -i inventory/dc1-prod-offline/hosts.ini playbook/install-kubernetes-cluster-containerd.yaml

### ELK安装 cim-elk --done
# fixme filebeat.yaml文件中的kafka地址，格式可能有误手动检查，对标["10.13.8.31:9092","10.13.8.29:9092","10.13.8.28:9092"]
/usr/bin/ansible-playbook -i inventory/dc1-prod-online/hosts.ini playbook/install-elk.yaml

# zk安装 rtd-zk sdr-zk --done
/usr/bin/ansible-playbook -i inventory/dc1-prod-offline/hosts.ini playbook/install-rtd-sdr-zk.yaml

# kafka安装 rtd-kafka yes-kafka --done
/usr/bin/ansible-playbook -i inventory/dc1-prod-offline/hosts.ini playbook/install-app-yes-kafka.yaml

# redis安装
# cim-redis cluster --done
/usr/bin/ansible-playbook -i inventory/dc1-prod-online/hosts.ini playbook/install-redis.yaml
# fdc-redis cluster --done
/usr/bin/ansible-playbook -i inventory/dc1-prod-offline/hosts.ini playbook/install-redis.yaml

# rocketmq安装
# cim-rocketmq cluster
/usr/bin/ansible-playbook -i inventory/dc1-prod-online/hosts.ini playbook/install-rocketmq.yaml
# fdc-rocketmq cluster
/usr/bin/ansible-playbook -i inventory/dc1-prod-offline/hosts.ini playbook/install-rocketmq.yaml

# prometheus监控安装
# online-Prometheus
/usr/bin/ansible-playbook -i inventory/dc1-prod-online/hosts.ini playbook/install-kubernetes-monitor.yaml
# offline-Prometheus
/usr/bin/ansible-playbook -i inventory/dc1-prod-offline/hosts.ini playbook/install-kubernetes-monitor.yaml
#
## 安装gauss监控
#/usr/bin/ansible-playbook -i nodes/node-gauss playbook/install-gaussdb-scriptMonitor.yml
## 安装gauss日志收集
#/usr/bin/ansible-playbook -i nodes/node-gauss playbook/install-gaussdb-gatherLogs.yml

#fixme 01 部署完成创建应用namespace -- 注意区分k8s集群 online/offline
# 1. 拷贝文件 scripts/namespace-create.py 和 scripts/template-namespace.yaml 两个文件到master01 相同目录（新建一个空目录）下；
# 2. 根据安装harbor获取的密码，手动配置namespace-create.py脚本，添加对应app的harbor登录密码
# 3. 执行命令：python3 namespace-create.py

#fixme 02 创建普通账户执行kubectl命令的kube.config文件 -- 注意区分k8s集群 online/offline
# 1. 根据创建的ns，在master01服务器上，执行命令：for i in ${namespace}[@];do ./generate-kubeconfig.sh $i; done
# 2. 在deploy服务器上，创建app使用的普通账户：for j in ${uaer_app}[@];do useradd $j -m -s /bin/bash; echo "$j:$j@2234" | chpasswd; done
# 3. 复制第1步生成的文件，到普通账户的~/.kube/ 目录下; source ~/.bashrc