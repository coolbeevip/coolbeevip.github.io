---
title: "Kubectl Commands"
date: 2021-12-19T13:24:14+08:00
tags: [kubectl]
categories: [kubernetes]
draft: false
---

常用 Kubectl 命令

## 创建命名空间

新建一个名为 nc-namespace.yaml 的 YAML 文件

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: nc-namespace
```

然后运行以下命令创建命名空间

```shell
$ kubectl create -f nc-namespace.yaml
namespace/nc-namespace created
```

## 创建命名空间资源配额文件

新建一个名为 nc-quota.yaml 的 YAML 文件

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: nc-quota
  namespace: nc-namespace

spec:
  hard:
    pods: "10"
    requests.cpu: "2"
    requests.memory: 2Gi
    limits.cpu: "4"
    limits.memory: 4Gi
```    

然后运行以下命令创建资源配额

```shell
$ kubectl create -f nc-quota.yaml
resourcequota/nc-quota created
```

## 创建 PV 卷和 PVC

新建一个名为 nc-pv.yaml 的 YAML 文件

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nc-pv-volume
  namespace: nc-namespace
spec:
  storageClassName: manual
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nc-pv-claim
  namespace: nc-namespace
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

然后运行以下命令创建卷

```shell
$ kubectl apply -f nc-pv.yaml
persistentvolume/nc-pv-volume created
persistentvolumeclaim/nc-pv-claim created
```

## 创建部署脚本

新建一个名为 nc-deployment-mysql.yaml 的 YAML 文件

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql
  namespace: nc-namespace
spec:
  ports:
  - port: 3306
  selector:
    app: mysql
  clusterIP: None
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  namespace: nc-namespace
spec:
  selector:
    matchLabels:
      app: mysql
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - image: mysql:8.0.21
        name: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: password
        ports:
        - containerPort: 3306
          name: mysql
        volumeMounts:
        - name: mysql-persistent-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mysql-persistent-storage
        persistentVolumeClaim:
          claimName: nc-pv-claim
```     

然后运行一下命令部署

```shell
$ kubectl apply -f nc-deployment-mysql.yaml
service/mysql created
deployment.apps/mysql created
```     

## 其他

列出集群中的所有命名空间

```shell
$ kubectl get namespaces --show-labels
```

删除 deployment

```shell
$ kubectl delete deployment mysql -n nc-namespace
```

删除 pod

```shell
$ kubectl delete pod mysql -n nc-namespace
```

删除 service

```shell
$ kubectl delete svc mysql -n nc-namespace
```

删除 PV 卷

```shell
$ kubectl delete pvc nc-pv-claim -n nc-namespace
$ kubectl delete pv nc-pv-volume -n nc-namespace
```

删除命名空间

```shell
$ kubectl delete -f nc-namespace.yaml
```
