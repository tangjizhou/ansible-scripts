# 使用介绍

一， 关键字介绍

1. `inventory` 是关于host的关键字，包含服务器信息的host文件；
2. `group_vars` 是关键字，包含变量文件和hosts文件；
3. `all` 是关键字，放在此目录下的变量文件，所有roles和playbook运行时，都能自动引用此目录下的所有变量文件；
4. `hosts.ini` 是hosts文件的关键字，包含所有的服务器IP信息；



二，使用介绍

1. 所有的变量文件，放在`group_vars` 目录下，以`.yaml` 结尾；
2. 对应变量文件的名称，与`hosts.ini` 文件中分组的名称相同，则ansible运行时会自动引用同名的变量文件中；



三，注意事项

1. 安装harbor之前，修改对应需要创建的项目名称，默认创建如下的项目

```yaml
app_project: '["ams", "apc", "eap", "mes", "mes-gray", "notice", "skywalking", "rms", "rtd", "spc", "sdr", "uac", "adc", "fdc", "noticeservice", "dms", "report", "yms", "oee"]'
```

2. CIM使用的中间件，通过`dc1-prod-online` 目录下文件部署，包括：

```yaml
harbor， online-nginx, online-k8s-cluster, redis, elasticsearch, kafka, zookeeper, rocketmq
```

3. 应用单独使用的中间件，通过`dc1-prod-offline` 目录下文件部署，包括：

```yaml
offline-nginx, offline-k8s-cluster, yes-kafka, app-kafka, sdr-zk, rtd-zk, fdc-rocketmq
```

4. 部署流程，可以参考脚本`ansible-install-infra-modules.sh`