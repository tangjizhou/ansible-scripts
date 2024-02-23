#!/bin/sh

a=$(systemctl status docker | grep "Active" | awk '{print $3}')
b=${a#\(}
process_status=${b%\)}

if [ ${process_status} = "running" ]
then
  exit 0
else
  [ -e /lib/systemd/system/docker.service ] && systemctl restart docker
  [ $? -eq 0 ]  && docker info > /dev/null
  [ $? -eq 0 ]  && exit 0
fi
