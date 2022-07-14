---
layout: post
cid: 7
title: NACOS数据持久化部署
slug: 7
date: 2021/03/10 11:14:00
updated: 2021/03/10 14:05:01
status: publish
author: sunday
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

使用二进制包部署单节点环境，数据持久化到MySQL数据库。因此，需要先部署MySQL、JDK >= 1.8 版本基础环境。<!--more-->

### 下载安装包
```Bash
[root@localhost ~]# wget https://github.com/alibaba/nacos/releases/download/1.3.1/nacos-server-1.3.1.tar.gz
```
### 解压程序包
```Bash
[root@localhost ~]# tar zxvf nacos-server-1.3.1.tar.gz -C /app/
```

### 导入数据库结构
```Bash
[root@localhost ~]# cd /app/nacos/conf
[root@localhost ~]# mysql -u你的MYSQL账户 -p'你的MySQL密码' -h'你的MySQL IP地址'
mysql> create database nacos character set utf8 collate utf8_bin;
mysql> use nacos
mysql> source nacos-mysql.sql  
```

### 修改配置

```
# 改数据存储为MySQL DB 
[root@localhost ~]# vim /app/nacos/conf/application.properties

spring.datasource.platform=mysql

db.num=1

db.url.0=jdbc:mysql://你的MySQLIP:3306/nacos?characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true&useUnicode=true&useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true

# MySQL账户
db.user=root
# MySQL密码
db.password=jkstack123321!!!

```

### 配置服务控制
```
[root@localhost ~]# vim /usr/lib/systemd/system/nacos.service 

[Unit]
Description=nacos
After=network.target

[Service]

# JDK部署环境(修改为你的)
Environment='JAVA_HOME=/app/jdk11'

Type=forking
ExecStart=/app/nacos/bin/startup.sh -m standalone
ExecReload=/app/nacos/bin/shutdown.sh
ExecStop=/app/nacos/bin/shutdown.sh
PrivateTmp=true
User=appuser
Group=appuser

[Install]
WantedBy=multi-user.target
```
### 启动Nacos
```
[root@localhost ~]# systemctl daemon-reload
[root@localhost ~]# systemctl start nacos
[root@localhost ~]# systemctl enable nacos
```
稍等片刻，使用`ss -ntl|grep 8848`命令查询nacos是否监听

访问：`http://nacos_IP:8848/nacos`  帐号:`nacos` 密码：`nacos` 进入nacos 管理后台

