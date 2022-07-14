---
layout: post
cid: 128
title: 部署一个简单的监控系统
slug: 128
date: 2022/06/05 00:06:00
updated: 2022/06/05 00:08:58
status: publish
author: sunday
categories:
  - 运维笔记
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

部署挺简单的 服务端通过Go编写 开箱即用 少有的好监控 成品： [https://monitor.itan90.cn/][1]  <!--more-->

## 基本环境

基础环境

```
yum -y install git docker \
&& systemctl start docker \
&& systemctl enable docker
```

克隆仓库

```
mkdir /app/;cd $_
git clone -b develop https://github.com/yaobohai/serverstatus.git monitor
```

## 启动服务端

```
sh /app/monitor/startup.sh
```

### 访问前端

```
http://IP:9400
```

....未完

  [1]: https://monitor.itan90.cn/