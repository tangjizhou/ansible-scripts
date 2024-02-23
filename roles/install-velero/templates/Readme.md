## velero version: 1.10, support k8s version: 1.18 and 1.24
1. images: 
   - '{{ image_repository }}/public/velero:v1.10.0'
   - '{{ image_repository }}/public/velero-plugin-for-aws:v1.5.2'
2. create k8s backup for all namespaces, ttl: 240h
3. vars:
   - velero_root_dir
   - velero_package_dir