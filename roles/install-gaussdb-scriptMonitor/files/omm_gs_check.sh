#!/bin/bash

#执行命令gs_check -e, 数据库定期自动巡检
source ~/.bashrc
for check_item in cluster dbInst dbStatus instStatus os period
do
        gs_check -e ${check_item} > /home/omm/check_dir/${check_item}
done

#grep -v -E "NG:\S*" --排除统计NG数量的行
cd /home/omm/check_dir/ && grep "NG" * | grep -v -E "NG:\S*" > /tmp/all_NG_check.txt
grep -E "^\S*NG" /tmp/all_NG_check.txt | awk -F: '{print $1}' | sort -u > /tmp/gs-test.txt
grep -E "^\S*NG" /tmp/all_NG_check.txt | awk -F: '{print $2}' | awk -F. '{print $1}' | sort -u > /tmp/gs-check.txt

for i in $(cat /tmp/gs-test.txt)
do
        echo $i
        sed -i 's#'$i':#<span style="color:red;font-weight:bold;">'$i'<\/span> #g' /tmp/all_NG_check.txt
done

for j in $(cat /tmp/gs-check.txt)
do
        echo $j
        sed -i 's#'$j'#<b>'$j'</b>#g' /tmp/all_NG_check.txt
done

sed -i 's/"/\\"/g' /tmp/all_NG_check.txt
sed -i "2,$ s/^/<br\/>/g" /tmp/all_NG_check.txt
echo "gs_check_e{description=\"$(cat /tmp/all_NG_check.txt)\"} 0" > /data01/node-exporter/logs/all_NG_check

#prometheus 不识别的特殊字符
sed -i ':t;N;s/\n//;b t' /data01/node-exporter/logs/all_NG_check
sed -i 's/\\r/\\n/g' /data01/node-exporter/logs/all_NG_check
sed -i 's/\\t/\\\\t/g' /data01/node-exporter/logs/all_NG_check
sed -i "1i \# HELP gs_check_e 1 is ok" /data01/node-exporter/logs/all_NG_check
sed -i "2i \# TYPE gs_check_e gauge" /data01/node-exporter/logs/all_NG_check
mv /data01/node-exporter/logs/all_NG_check /data01/node-exporter/logs/all_NG_check.prom
