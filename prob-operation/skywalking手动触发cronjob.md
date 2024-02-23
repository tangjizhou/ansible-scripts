### skywalking手动触发cronjob
skywalking 部署和重启之后，需要手动触发一次cronjob

操作如下：
1. 查询cronjob
```shell
# kubectl -n skywalking get cronjobs.batch
NAME           SCHEDULE       SUSPEND   ACTIVE   LAST SCHEDULE   AGE
oap-init-job   0 0,16 * * *   False     0        128m            31d
```

2. 创建job
```shell
# kubectl -n skywalking create job sky-job --from=cronjob/oap-init-job
```