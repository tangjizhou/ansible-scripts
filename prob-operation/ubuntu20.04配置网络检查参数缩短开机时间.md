### Ubuntu20.04缩短开机启动时间
1. 文件`/lib/systemd/system/systemd-networkd-wait-online.service`中添加启动配置参数：
```shell
# cat /lib/systemd/system/systemd-networkd-wait-online.service

#  SPDX-License-Identifier: LGPL-2.1+
#
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.

[Unit]
Description=Wait for Network to be Configured
Documentation=man:systemd-networkd-wait-online.service(8)
DefaultDependencies=no
Conflicts=shutdown.target
Requires=systemd-networkd.service
After=systemd-networkd.service
Before=network-online.target shutdown.target

[Service]
Type=oneshot
ExecStart=/lib/systemd/systemd-networkd-wait-online
RemainAfterExit=yes
TimeoutStartSec=2sec    # 此处添加如此配置，开机检查网络超时设置为2s，默认超时时间为4min

[Install]
WantedBy=network-online.target

```
2. 另一种修改方式：关闭ipv6
```yaml
# cat /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp4s1:
      dhcp4: no
      addresses: [192.168.1.100/23]
      gateway4: 192.168.0.1
      dhcp6: false       #关闭ipv6的配置，添加如下两行配置
      accept-ra: no
      link-local: []

```