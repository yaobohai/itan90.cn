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
docker run -itd \
-p $SERVER_PORT:80 \
--restart=always \
--name=remote_download \
-e PASSWORD=123456 \
-e SERVER_NAME=$(curl -4s ip.sb):$SERVER_PORT \
-v /data:/app/remote_download/files \
registry.cn-hangzhou.aliyuncs.com/bohai_repo/remote_download:v1.0
docker logs -f --tail=200 remote_download
```

## 使用

打开浏览器访问本机公网IPV4地址。默认通过 `curl -4s ip.sb` 获取。打开后界面如下：

![][2]

在上框中输入登陆密码 `默认登陆密码 123456` 第一个框中输入粘贴文件链接进去即可

![][3]

## 帮助

### 运行参数解释

```bash
# 默认访问端口
SERVER_PORT='80'
# 重启Docker时随Docker一起重启
--restart=always
# 默认登陆密码
-e PASSWORD=123456 
# 服务前端地址（默认获取本机公网IPV4地址。需要域名时填写域名；内网IP请填写内网IP）
-e SERVER_NAME=$(curl -4s ip.sb)
# 默认数据存储目录
-v /data:/app/remote_download/files
```

若需使用非80端口部署程序 只需修改`SERVER_PORT`的值即可；需要如下配置即可（例如端口18889）

```bash
docker rm -f remote_download
export SERVER_PORT='18889'
docker run -itd \
-p $SERVER_PORT:80 \
--restart=always \
--name=remote_download \
-e PASSWORD=123456 \
-e SERVER_NAME=$(curl -4s ip.sb):$SERVER_PORT \
-v /data:/app/remote_download/files \
registry.cn-hangzhou.aliyuncs.com/bohai_repo/remote_download:v1.0
docker logs -f --tail=200 remote_download
```

### 开启SSL

假设你已部署好程序；且通过NGINX反向代理了程序。那么命令行运行以下两条命了即可

```bash
docker exec -it remote_download sed -i "s/USE_HTTPS=false/USE_HTTPS=true/g" /app/remote_download/.env

docker restart remote_download
```

### 修改前端

为了部署时间，打包镜像时未考虑在部署时自动编译前端，那么有需要修改前端的需求则可将原有html文件复制出来单独修改，并将文件映射至容器目录。

```bash
# 1. 复制前端文件
docker cp remote_download:/app/www/index.html ./

# 2. 启动程序时添加参数
-v ./index.html:/app/www/index.html \

# 3. 重启程序
docker restart remote_download

```

### 一键安装脚本

```bash
首选地址：curl -s https://oss.itan90.cn/files/remote_download/init.sh|bash

备用地址：curl -s https://oss-1251604004.cos.ap-shanghai.myqcloud.com/files/remote_download/init.sh|bash
```

### 公开节点

如果你暂时没有线路好的国外节点，可以暂时使用我的节点进行使用。

*开发或演示环境节点、不保证稳定性、文件定时清理*

| 节点访问地址 | 节点物理位置 | 备注  |
| -------- | -------------- |--------|
| http://204.13.155.78:8999/ 	| 美国 洛杉矶 | |
| http://107.172.157.169:8999/	| 美国 水牛城 | |
| http://107.173.85.142:8999/	| 美国 水牛城 | |


  [2]: https://oss.itan90.cn/out_pic/2022-07-20/2QgZgi.jpg
  [3]: https://oss.itan90.cn/out_pic/2022-07-20/L8LlOW.jpg