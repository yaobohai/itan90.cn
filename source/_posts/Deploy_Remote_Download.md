---
layout: post
cid: 67
title: 远程下载工具的部署与使用
slug: 67
date: 2021/12/19 15:35:00
updated: 2022/04/17 13:39:37
status: publish
author: sunday
categories:
  - 实验室
tags: 
customSummary: 
mathjax: auto
noThumbInfoStyle: default
outdatedNotice: no
reprint: standard
thumb: 
thumbChoice: default
thumbDesc: 
thumbSmall: 
thumbStyle: default
---
  
部署在服务器上的下载工具，利用海外高带宽的优势做跳板加速本地下载，主要用于加速国内下载缓慢的国外资源。

![](https://oss.itan90.cn/out_pic/2022-07-11/tTEM6V.png)

<!--more-->

## 部署

### 安装Docker

```bash
yum -y install docker \
&& systemctl start docker \
&& systemctl enable docker
```

### 安装远程下载工具程序

```bash
docker rm -f remote_download
export SERVER_PORT='80'
export USE_HTTPS='false'
docker run -itd \
-p $SERVER_PORT:80 \
--restart=always \
--name=remote_download \
-e PASSWORD=123456 \
-e USE_HTTPS=$USE_HTTPS \
-e SERVER_NAME=$(curl -4s ip.sb):$SERVER_PORT \
-v /data:/app/remote_download/files \
registry.cn-hangzhou.aliyuncs.com/bohai_repo/remote_download:v1.2
docker logs -f --tail=200 remote_download
```

## 使用

打开浏览器访问本机公网IPV4地址。默认通过 `curl -4s ip.sb` 获取。打开后界面如下：

![][2]

在上框中输入登陆密码 `默认登陆密码 123456` 第一个框中输入粘贴文件链接进去即可

![][3]

## 帮助

### 运行参数解释

若需使用非80端口部署程序 只需修改`SERVER_PORT`的值即可；需要如下配置即可（例如端口18889）

若需使用https协议进行下载文件，则为变量`USE_HTTPS` 配置为 `true` 

```bash
docker rm -f remote_download
export SERVER_PORT='18889'
export USE_HTTPS='true'
docker run -itd \
-p $SERVER_PORT:80 \
--restart=always \
--name=remote_download \
-e PASSWORD=123456 \
-e USE_HTTPS=$USE_HTTPS \
-e SERVER_NAME=$(curl -4s ip.sb):$SERVER_PORT \
-v /data:/app/remote_download/files \
registry.cn-hangzhou.aliyuncs.com/bohai_repo/remote_download:v1.2
docker logs -f --tail=200 remote_download
```

上述代码片段表示使用https的18889端口进行访问和进行下载文件。


## 一键安装脚本

```bash
首选地址：curl -s https://oss.itan90.cn/files/remote_download/init.sh|bash

备用地址：curl -s https://oss-1251604004.cos.ap-shanghai.myqcloud.com/files/remote_download/init.sh|bash
```

## 在K8S中运行

1、新建 `deploy_remote_download.yaml` 编排文件

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
    - name: http
      port: 80
      nodePort: 30006
      targetPort: http
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
        kubernetes.io/hostname: k8s-ingress-node
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
            cpu: 10m
            memory: 30Mi
          limits:
            cpu: 20m
            memory: 50Mi
      securityContext:
        runAsUser: 0
      volumes:
      # 存储使用主机存储
      - name: remote-download-data
        hostPath:
          path: /data/remote-download/
```

2、启动

```shell
kubectl create ns bohai-app
kubectl apply -f deploy_remote_download.yaml -n bohai-app
```

3、访问

```shell
http://K8S节点IP:30006  密码: 123456
```