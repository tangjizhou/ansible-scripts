#!/bin/bash

##执行命令gs_om -t status 进行实例状态查询，所有状态均为ONLINE为正常，出现任意非online状态为异常。
source ~/.bashrc
trans_file=/data01/node-exporter/scripts/gs_om.txt
mkdir -p /data01/node-exporter/logs/
trans_alert_file=/data01/node-exporter/logs/gs_om_alert

gs_om -t status > $trans_file

#获取非ONLINE行的行号
#grep -v -E ".*logicrep.*ROLE:standby" --排除logicrep，standby
awk '{print NR " " $0}' ${trans_file} | grep "STATUS" | grep -v "ONLINE" | grep -v -E ".*logicrep.*ROLE:standby" | awk '{print $1}' > line_number.txt
for line_number in $(cat line_number.txt)
do
	sed -i ''${line_number}' s/^/<span style="color:red;font-weight:bold;">/g' ${trans_file}
	sed -i ''${line_number}' s/$/<\/span>/g' ${trans_file}
done

cat ${trans_file} | grep STATUS | grep -v ONLINE | grep -v -E ".*logicrep.*ROLE:standby"

if [ $? -eq 0 ];then
        sed -i 's/"/\\"/g' $trans_file
        sed -i "2,$ s/^/<br\/>/g" $trans_file
        file=`cat $trans_file`
        echo "gs_om_alert{description=\"$file\"} 0" > $trans_alert_file
        sed -i ':t;N;s/\n//;b t' $trans_alert_file
        sed -i "1i  \# HELP gs_om_alert 1 is ok" $trans_alert_file
        sed -i "2i  \# TYPE gs_om_alert gauge" $trans_alert_file
        mv $trans_alert_file /data01/node-exporter/logs/gs_om_alert.prom
else
        echo "# HELP gs_om_alert 1 is ok" > $trans_alert_file
        echo "# TYPE gs_om_alert gauge" >> $trans_alert_file
        echo "gs_om_alert 1" >> $trans_alert_file
        mv $trans_alert_file /data01/node-exporter/logs/gs_om_alert.prom
fi
