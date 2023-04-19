---
layout: post
cid: 67
title: 远程下载工具的部署与使用
date: 2021/12/19 15:35:00
categories:
  - 实验室
---
  
部署在服务器上的下载工具，利用海外高带宽的优势做跳板加速本地下载，主要用于加速国内下载缓慢的国外资源。

其优势如下：

- 使用容器部署
- 资源占用较少
- 部署效率飞快

![](https://oss.itan90.cn/out_pic/2022-07-11/tTEM6V.png)

<!--more-->

# 部署

## 基础环境

```bash
// 安装Docker
yum -y install docker \
&& systemctl start docker \
&& systemctl enable docker
```

## 安装程序

```bash
export USE_HTTPS='false'
export SERVER_PORT='80'
export SERVER_ADDR=$(curl -4s ip.sb)
docker rm -f remote_download
docker run -itd \
-p $SERVER_PORT:80 \
--restart=always \
--name=remote_download \
-e PASSWORD=123456 \
-e USE_HTTPS=$USE_HTTPS \
-e SERVER_NAME=$SERVER_ADDR:$SERVER_PORT \
-v /data/remote_download/data:/app/remote_download/files \
registry.cn-hangzhou.aliyuncs.com/bohai_repo/remote_download:v1.2
docker logs -f --tail=200 remote_download
```

## 访问使用

1、打开浏览器访问本机IP地址 `SERVER_ADDR的值` 加 端口 `SERVER_PORT的值` 。打开后界面如下：

![][2]

在上框中输入登陆密码 `PASSWORD的值` 并回车

2、将文件地址复制到上面的框中,即可完成文件缓存操作

![][3]

## 运行参数解释

```bash
// 是否启用https
export USE_HTTPS='true'
// 服务访问端口
export SERVER_PORT='18889'
// 服务访问地址 (VPS的公网IP)
export SERVER_ADDR=$(curl -4s ip.sb)
```

上述参数片段表示使用https的18889端口进行访问和进行下载文件。

## 一键安装

支持：RedHat 7.X 系列

```bash
首选地址：curl -s https://oss.itan90.cn/files/remote_download/init.sh|bash
```

# 高阶用法

## 使用tips

1、当 `USE_HTTPS` 为 `true` 且证书有效时,可双击文件链接拦自动完成文件链接填入。

2、远端存储

从 `v1.3` 版本开始，程序支持使用远端存储来启动程序

也就是在启动时指定一个远端存储，从而为程序提供一个数据落地的方法。

例如以下启动参数:

```shell
docker rm -f remote_download
docker run -itd \
-p 8999:80 \
--restart=always \
--name=remote_download \
# 开启特权模式[必须添加]
--privileged \
-e PASSWORD=123456 \
-e USE_HTTPS=false \
-e SERVER_NAME=2.2.2.2:8999 \
-e REMOTE_STORAGE=minio \
-e MINIO_ACCESS_KEY_ID=<you_minio_access_keyid> \
-e MINIO_SECRET_ACCESS_KEY=<you_minio_accesskey> \
-e MINIO_SERVER_URL=<you_minio_url> \
-e MINIO_BUCKET_NAME=<you_minio_bucket_name> \
registry.cn-hangzhou.aliyuncs.com/bohai_repo/remote_download:v1.3
```

启动后，则会使用minio作为数据存储的方式，数据的存储则会最终落入minio存储中不占用运行容器的主机空间 

注意：上传/下载文件时，则会使用主机存储作为临时缓存

具体参数解释

```shell
远端存储类型          REMOTE_STORAGE
minio的ACCESSiD     MINIO_ACCESS_KEY_ID
minio的ACCESSKEY    MINIO_SECRET_ACCESS_KEY 
minio的服务地址      MINIO_SERVER_URL
minio的Bucket名称   MINIO_BUCKET_NAME
```

目前已支持的存储类型：

- minio
- 使用s3协议的对象存储

待更新更多存储类型

## 在k8s中运行

### 新建编排文件

```shell
$ kubectl create ns bohai-app
$ mkdir remote-download && cd $_
$ vim deploy.yaml
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: remote-download
  labels:
    app: remote-download
spec:
  selector:
    app: remote-download
  type: NodePort
  ports:
    # 使用nodeport主机30006端口发布服务
    - name: web
      port: 80
      targetPort: 80
      nodePort: 30006
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: remote-download
  labels:
    app: remote-download
spec:
  selector:
    matchLabels:
      app: remote-download
  template:
    metadata:
      labels:
        app: remote-download
    spec:
      nodeSelector:
        # k8s任意一节点名称
        kubernetes.io/hostname: kube-node01
      # 生成一个50M大小的文件进行下载测试(可选)
      initContainers:
      - name: generate-files
        image: busybox:1.28
        command: ['sh', '-c', 'dd if=/dev/zero of=/app/remote_download/files/demo.file bs=1M count=50 &>/dev/null']
        volumeMounts:
        - name: remote-download-data
          mountPath: /app/remote_download/files
      containers:
      - image: registry.cn-hangzhou.aliyuncs.com/bohai_repo/remote_download:v1.2
        imagePullPolicy: Always
        name: remote-download
        env:
        # 是否启用https访问
        - name: USE_HTTPS
          value: "false"
        # 程序的访问密码
        - name: PASSWORD
          value: "admin123"
        # 程序的访问地址
        - name: SERVER_NAME
          value: "146.56.108.154:30006"
        ports:
        - containerPort: 80
          name: http
        livenessProbe:
          httpGet:
            path: /api/files
            port: 80
            scheme: HTTP
          failureThreshold: 3
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 1
        startupProbe:
          httpGet:
            path: /api/files
            port: 80
            scheme: HTTP
          failureThreshold: 60
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 1
        readinessProbe:
          httpGet:
            path: /api/files
            port: 80
            scheme: HTTP
          failureThreshold: 2
          periodSeconds: 6
          successThreshold: 3
          timeoutSeconds: 1
        volumeMounts:
        - mountPath: "/app/remote_download/files"
          name: remote-download-data
        resources:
          # 启动所需资源
          requests:
            cpu: 1m
            memory: 10Mi
          limits:
            cpu: 10m
            memory: 40Mi
      securityContext:
        runAsUser: 0
      volumes:
      # 存储使用主机存储
      - name: remote-download-data
        hostPath:
          path: /data/remote-download/
```

### 启动

```shell
$ kubectl apply -f deploy.yaml -n bohai-app

// 当Pod状态为Running时即可
$ kubectl get po -n bohai-app -l app=remote-download
NAME                               READY   STATUS    RESTARTS   AGE
remote-download-7c8d5b4dbf-c5fc9   1/1     Running   0          2m6s
```

### 访问

```shell
http://K8S节点IP:30006  密码: admin123
```

### 监控

```shell
// 资源使用
$ kubectl top po -n bohai-app -l app=remote-download
NAME                               CPU(cores)   MEMORY(bytes)
remote-download-7c8d5b4dbf-c5fc9   1m           27Mi

// 服务状态
协议：HTTP 
方法：GET 
地址：127.0.0.1:80 
路径：/api/files

返回状态码：200

// 服务日志
$ kubectl logs -f --tail=200 -n bohai-app -l app=remote-download
```
# 其他帮助

## 公开节点

| 节点名称 | 节点地址 | 节点物理位置 | 备注       |
|------|------|--------|----------|
| 预演环境 |http://146.56.108.154:30006/ |  韩国 春川 | k8s环境中运行  |

  [2]: https://resource.static.tencent.itan90.cn/mac_pic/2023-04-08/WaNWXe.png
  [3]: https://resource.static.tencent.itan90.cn/mac_pic/2023-04-08/EJhrHd.png