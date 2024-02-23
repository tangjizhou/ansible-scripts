#!/bin/bash

check_sub_item_10m="CheckPing
CheckCpuUsage
CheckDiskUsage
CheckHandleUsage
CheckMemUsage
CheckTime
CheckRuntime
CheckWaitQueue
CheckClusterState
CheckLogFiles
CheckAlarmLog
CheckRedoStatus
CheckConnCount
CheckUncommXacts
CheckBufferUsage
CheckDBStatus
CheckDBFile
CheckTablespaceUsage
CheckTablespaceStatus
CheckTransSession
CheckTransWaitTime
CheckLongTranc"

#判断FloatIP是否在当前节点，本脚本只在master执行
float_ip=`gs_om -t status | grep -w 'FloatIP' | awk '{print $3}' | awk -F: '{print $2}'`
ip a s | grep ${float_ip}
if [ $? == 0 ];then
  gs_check_Fun
else
  echo "当前服务器是备节点，不执行任何操作"
fi

#执行gs_check检查
gs_check_Fun(){
    alarm_prom_file=/data01/node-exporter/logs/gs-check-item-10m.prom
    #check_item_new=/data01/node-exporter/scripts/check-item-new-10m.txt
    check_dir=/home/omm/check_dir_10m

    if [ ! -d ${check_dir} ]; then
        mkdir -p ${check_dir}
    fi

    #执行命令gs_check -i, 数据库定期自动巡检
    source ~/.bashrc
    for check_item in ${check_sub_item_10m[@]}
    do
            gs_check -i ${check_item} -L > ${check_dir}/${check_item}
    done

    #获取NG状态的检查项目name
    alarm_check_item=`cd ${check_dir} &&  grep "\[RST\]" * | grep -v "OK" |  awk -F: '{print $1}'`
    cd /data01/node-exporter/scripts/

    echo "# HELP gs_check_item_10m 0 is ok" > ${alarm_prom_file}
    echo "# TYPE gs_check_item_10m gauge" >> ${alarm_prom_file}

    if [ ! -n "$alarm_check_item" ]
    then
        echo "gs_check_item_10m 0" >> ${alarm_prom_file}
    else
        for alarm_check_item_sub in ${alarm_check_item[@]}
        do
          alarm_file=${check_dir}/${alarm_check_item_sub}
          #告警主题=${alarm_check_item_sub}
          #去除结尾的^M
          yum -y install dos2unix
          dos2unix ${alarm_file}
          #去除空行和空格组成的行
          sed -i '/^[ ]*$/d' ${alarm_file}
          #去除时间戳
          sed -i '/^\[TIME/d' ${alarm_file}
          sed -i '/^[0-9]/d' ${alarm_file}
          #替换'为空
          sed -i "s/'//g" ${alarm_file}
          #替换"为空
          sed -i 's/"//g' ${alarm_file}
          #替换\为空
          sed -i 's/\\//g' ${alarm_file}
          #去除换行符\n
          sed -i ':a;N;$!ba;s/\n/ /g' ${alarm_file}
          description=$(cat ${alarm_file})
          echo "gs_check_item_10m{alert_title=\"${alarm_check_item_sub}\", description=\"${description}\"} 1" >> ${alarm_prom_file}
        done
    fi
}