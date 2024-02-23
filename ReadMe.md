# 使用介绍

一， 关键字介绍

1. `inventory` 是关于host的关键字，包含服务器信息的host文件；
2. `group_vars` 是关键字，包含变量文件和hosts文件；
3. `all` 是关键字，放在此目录下的变量文件，所有roles和playbook运行时，都能自动引用此目录下的所有变量文件；
4. `hosts.ini` 是hosts文件的关键字，包含所有的服务器IP信息；



二，使用介绍

1. 所有的变量文件，放在`group_vars` 目录下，以`.yaml` 结尾；
2. 对应变量文件的名称，与`hosts.ini` 文件中分组的名称相同，则ansible运行时会自动引用同名的变量文件中；