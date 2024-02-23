#!/usr/bin/env python2.7.5
# -*- coding:utf-8 -*-
# @author Rainy
# 此脚本是创建namespce和对应的imagePullSecret: harbor
# 运行脚本之前，需要先获取普通用户的登录密码，配置app_name的value值


import shutil
import subprocess


def execute_command(command):
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    output, error = process.communicate()
    return output, error


app_name = {"ams": "amsFab@1033.com",
            "apc": "apcFab@4936.com",
            "eap": "eapFab@7008.com",
            "mes": "mesFab@3726.com",
            "mes-gray": "mes-grayFab@2664.com",
            "notice": "noticeFab@7241.com",
            "skywalking": "skywalkingFab@1256.com",
            "rms": "rmsFab@7749.com",
            "rtd": "rtdFab@2784.com",
            "spc": "spcFab@2949.com",
            "sdr": "sdrFab@6875.com",
            "uac": "uacFab@7415.com",
            "adc": "adcFab@1494.com",
            "fdc": "fdcFab@9363.com",
            "noticeservice": "noticeserviceFab@8365.com",
            "dms": "dmsFab@5589.com",
            "report": "reportFab@4362.com",
            "yms": "ymsFab@4810.com",
            "oee": "oeeFab@9546.com"}

for ns_key, ns_value in app_name.items():
    app_namespace = "fabc-{}-prod".format(ns_key)

    # 文件复制
    src_file = "template-namespace.yaml"
    dest_file = "{}-namespace.yaml".format(app_namespace)
    shutil.copy(src_file, dest_file)

    # 字符串替换
    temp_str = "template-ns"
    with open(dest_file, mode='r') as file:
        content = file.read()
        new_content = content.replace(temp_str, app_namespace)
    with open(dest_file, mode='w') as file2:
        file2.write(new_content)

    # 创建namespace
    create_ns = "kubectl apply -f {}".format(dest_file)
    result_out, result_err = execute_command(create_ns)
    print(result_out)
    print(result_err)

    # 创建harbor-secret
    secret_name = "harbor"
    docker_username = ns_key
    docker_password = ns_value
    docker_server = "10.21.0.100:80"
    create_secret = "kubectl -n {} create secret docker-registry {} --docker-username={} --docker-password={} --docker-server={}".format(
        app_namespace, secret_name, docker_username, docker_password, docker_server)
    kube_out, kube_err = execute_command(create_secret)
    print(kube_out)
    print(kube_err)
