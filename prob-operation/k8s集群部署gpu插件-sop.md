# k8s集群部署GPU插件-NVIDIA

__目的：infra在K8S集群部署adc依赖的gpu插件-nvidia驱动__

### 一，环境信息：
1. Ubuntu 20.04.5
2. containerd v1.6.6

### 二，准备文件
1. nvidia驱动文件：[NVIDIA-Linux-x86_64-510.47.03.run](https://www.nvidia.com/content/DriverDownloads/confirmation.php?url=/Windows/Quadro_Certified/512.15/512.15-quadro-rtx-desktop-notebook-win10-win11-64bit-international-dch-whql.exe&lang=us&type=Quadro)

2. nvidia容器组件：
   1. [libnvidia-container1_1.9.0-1_amd64.deb](https://github.com/NVIDIA/libnvidia-container/tree/gh-pages/stable/ubuntu18.04/amd64)
   2. [libnvidia-container-tools_1.9.0-1_amd64.deb](https://github.com/NVIDIA/libnvidia-container/tree/gh-pages/stable/ubuntu18.04/amd64)
   3. [nvidia-container-toolkit_1.9.0-1_amd64.deb](https://github.com/NVIDIA/libnvidia-container/tree/gh-pages/stable/ubuntu18.04/amd64)

`注：容器组件的下载地址链接到Ubuntu18.04，为正常情况，能够兼容nvidia驱动`
3. 拷贝以上文件到已安装GPU设备的worker节点`/data01/gpu`

### 三，操作步骤
1. 安装nVidia驱动程序
```shell
cd /data01/gpu
/bin/bash ./NVIDIA-Linux-x86_64-510.108.03.run

# 安装完成后输入如下验证命令，有相关gpu信息输出，则安装成功
nvidia-smi
```

2. 按顺序安装nVidia容器组件
```shell
dpkg -i ./libnvidia-container1_1.9.0-1_amd64.deb
dpkg -i ./libnvidia-container-tools_1.9.0-1_amd64.deb
dpkg -i ./nvidia-container-toolkit_1.9.0-1_amd64.deb
```

3. 修改`containerd`配置文件`/etc/containerd/config.toml`
```yaml
···
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]

        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          base_runtime_spec = ""
          cni_conf_dir = ""
          cni_max_conf_num = 0
          container_annotations = []
          pod_annotations = []
          privileged_without_host_devices = false
          runtime_engine = ""
          runtime_path = ""
          runtime_root = ""
          runtime_type = "io.containerd.runtime.v1.linux"    #修改此处的原始值“io.containerd.runc.v2” 为 “io.containerd.runtime.v1.linux”
···
      [plugins."io.containerd.runtime.v1.linux"]
      no_shim = false
      runtime = "nvidia-container-runtime"    #修改此处的原始值“runc” 为 “nvidia-container-runtime”
      runtime_root = ""
      shim = "containerd-shim"
      shim_debug = false
```
4. 重启`containerd`进程
```shell
systemctl restart containerd.service
```
5. k8s集群部署`k8s-device-plugin`插件
[官方介绍文档](https://github.com/NVIDIA/k8s-device-plugin)
```yaml
# cat k8s-device-plugin.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
   name: nvidia-device-plugin-daemonset
   namespace: kube-system
spec:
   selector:
      matchLabels:
         name: nvidia-device-plugin-ds
   updateStrategy:
      type: RollingUpdate
   template:
      metadata:
         labels:
            name: nvidia-device-plugin-ds
      spec:
         tolerations:
            - key: nvidia.com/gpu
              operator: Exists
              effect: NoSchedule
         priorityClassName: "system-node-critical"
         containers:
            - image: nvcr.io/nvidia/k8s-device-plugin:v0.14.4    #官方镜像下载地址，部署之前修改
              name: nvidia-device-plugin-ctr
              env:
                 - name: FAIL_ON_INIT_ERROR
                   value: "false"
              securityContext:
                 allowPrivilegeEscalation: false
                 capabilities:
                    drop: ["ALL"]
              volumeMounts:
                 - name: device-plugin
                   mountPath: /var/lib/kubelet/device-plugins
         volumes:
            - name: device-plugin
              hostPath:
                 path: /var/lib/kubelet/device-plugins
```
```shell
kubectl apply -f k8s-device-plugin.yaml
```
pod启动成功后，没有安装GPU的worker上的pod，日志显示‘No devices found. Waiting indefinitely’，属于正常情况。

6. 部署GPU测试工具`gpu-pod`
```yaml
# cat gpu-pod.yaml
apiVersion: v1
kind: Pod
metadata:
   name: gpu-pod
spec:
   nodeName: cim-p-offline-k8sworker13      # 指定部署在有gpu的worker上
   restartPolicy: Never
   containers:
      - name: cuda-container
        image: nvcr.io/nvidia/k8s/cuda-sample:vectoradd-cuda10.2    #官方镜像下载地址，部署之前修改
        resources:
           limits:
              nvidia.com/gpu: 1 # requesting 1 GPU
   tolerations:
      - key: nvidia.com/gpu
        operator: Exists
        effect: NoSchedule
```
```shell
kubectl apply -f gpu-pod.yaml
```
此pod默认在default下：
```shell
$ kubectl logs gpu-pod
[Vector addition of 50000 elements]
Copy input data from the host memory to the CUDA device
CUDA kernel launch with 196 blocks of 256 threads
Copy output data from the CUDA device to the host memory
Test PASSED
Done
```