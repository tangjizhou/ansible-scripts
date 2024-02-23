#!/bin/bash

#新增告警日志处理方法: alarm日志id筛选； 替换日志特殊符号
gauss_alert_Fun(){
	sed -i 's/"/\\"/g' ${trans_file}
	sed -i "2,$ s/^/<br\/>/g" ${trans_file}
	file=`head -n 201 ${trans_file}`
	if [ ${alarm_dir} == "alarm" ];then    #alarm 类型需要输出alarmID
		cat ${trans_file} | awk -F\| '{print $2}' | sort -u > /tmp/alarmid.txt
		cat /tmp/alarmid.txt
		for alarm_id in $(cat /tmp/alarmid.txt)
		do
			grep ${alarm_id} ${modul_alarmid} >> /tmp/type_alarmid.txt
		done
		sed -i "2,$ s/^/<br\/>/g" /tmp/type_alarmid.txt
		alarm_id_file=`cat /tmp/type_alarmid.txt`
		echo "gauss_${alarm_dir}{alarm_id=\"${alarm_id_file}\",alert_type=\"${alarm_dir}-${trans_name}\",description=\"${file}\"} 0" > ${trans_alert_file}
	else
		echo "gauss_${alarm_dir}{alert_type=\"${alarm_dir}-${trans_name}\",description=\"${file}\"} 0" > ${trans_alert_file}
	fi
	sed -i ':t;N;s/\n//;b t' ${trans_alert_file}
	sed -i 's/\\r/\\n/g' ${trans_alert_file}
	sed -i "1i \# HELP gauss_${alarm_dir} 1 is ok" ${trans_alert_file}
	sed -i "2i \# TYPE gauss_${alarm_dir} gauge" ${trans_alert_file}
	mv ${trans_alert_file} /data01/node-exporter/logs/gauss_${alarm_dir}_${trans_name}.prom
	rm -f ${trans_file}
	true > /tmp/type_alarmid.txt
}

## fixme 第一次需要初始化promb文件 --- 如果一直没有告警，查不到指标
#无告警日志新增，处理方法，返回正常值1
gauss_nomal_Fun(){
	prom_log=/data01/node-exporter/logs
	ls ${prom_log} | grep -E "gauss_${alarm_dir}.*prom" > /tmp/prom_file
	cat /tmp/prom_file
	for prom in $(cat /tmp/prom_file)
	do
		echo ${prom} > /tmp/haha_cut.txt
        	echo "# HELP gauss_${alarm_dir} 1 is ok" > ${prom_log}/${prom}
        	echo "# TYPE gauss_${alarm_dir} gauge" >> ${prom_log}/${prom}
		alert_type=`cut -d '_' -f 2- /tmp/haha_cut.txt | awk -F\. '{print $1}'`
		echo "gauss_${alarm_dir}{alert_type=\"${alert_type}\"} 1" >> ${prom_log}/${prom}
	done
}

#返回告警日志前200行
judge_Fun(){
	mv ${alarm_total_dir}/${alarm_dir}/${alarm_file}  /tmp/judge_${alarm_file}

	total_line=`wc -l /tmp/judge_${alarm_file} | awk '{print $1}'`
	if [ ${total_line} -gt 200 ];then
		echo "新增日志太多仅显示前200行"
		sed -i "1i  <b>新增告警日志\"${total_line}\"行仅显示前200行</b>"  /tmp/judge_${alarm_file}
		head -n 201 /tmp/judge_${alarm_file}  > ${trans_file}
		rm -f /tmp/judge_${alarm_file}
		gauss_alert_Fun
	else
		mv /tmp/judge_${alarm_file} ${trans_file}
		gauss_alert_Fun
	fi
}

#gauss alarm ID 说明文件
modul_alarmid=/data01/node-exporter/modul_alarmid.txt

#logstash新增日志输出总目录
alarm_total_dir=/data01/node-exporter/gauss_logs
ls ${alarm_total_dir} > /tmp/haha.txt

for alarm_dir in $(cat /tmp/haha.txt)
do
	echo ${alarm_dir}
	gauss_nomal_Fun

	ls ${alarm_total_dir}/${alarm_dir} > /tmp/${alarm_dir}.txt
	file_number=`ls ${alarm_total_dir}/${alarm_dir} | wc -l`
	if [ ${file_number} -gt 0 ];then
		for alarm_file in $(cat /tmp/${alarm_dir}.txt)
		do
			echo ${alarm_file}
			trans_name=`echo ${alarm_file} | awk -F. '{print $1}'`
			trans_file=/data01/node-exporter/logs/${trans_name}.txt
			trans_alert_file=/data01/node-exporter/${alarm_dir}-${trans_name}
			judge_Fun
		done
	fi
done
