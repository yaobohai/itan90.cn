---
layout: post_draft
cid: 112
title: 收集常用镜像源
slug: @112
date: 2021/11/13 00:06:00
updated: 2022/03/25 10:11:16
status: publish
author: sunday
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
categories:
  - 技术分享
---

一些经常用到的镜像源(Linux、npm、docker、等等)<!--more-->


## Linux 镜像源

 - 清华大学开源软件镜像站 https://mirrors.tuna.tsinghua.edu.cn/

 - 网易云开源软件镜像源 https://mirrors.163.com/.help/centos.html
   
 - 中国科学技术大学开源软件镜像 https://mirrors.ustc.edu.cn/

## ArchLinux 源

`/etc/pacman.d/mirrorlist`

```
Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch
Server = https://mirror.sjtu.edu.cn/archlinux/$repo/os/$arch
```

ArchLinux CN 源 编辑 /etc/pacman.conf 在最后加上：
```
[archlinuxcn]
Server = https://mirrors.ustc.edu.cn/archlinuxcn/$repo/os/$arch
Server = https://mirrors.sjtug.sjtu.edu.cn/archlinux-cn/$arch
```
注意：sjtug 中间有一个`-`, 而 ustc 则没有，直接是 archlinuxcn

## Docker

docker 配置

编辑 `/etc/docker/daemon.json`， 增加registry-mirrors配置：

```
{
  "registry-mirrors": [
    "https://docker.mirrors.sjtug.sjtu.edu.cn",
    "https://dockerhub.mirrors.nwafu.edu.cn",
    "https://hub-mirror.c.163.com"
  ]
}
```
podman 配置

备份原配置 `/etc/containers/registries.conf`， 修改内容为：

```
unqualified-search-registries = [
    'docker.io',
    'registry.access.redhat.com',
    'quay.io',
    'registry.fedoraproject.org',
    'registry.centos.org'
]

[[registry]]
prefix = "docker.io"
insecure = false
blocked = false
location = "docker.mirrors.sjtug.sjtu.edu.cn"

[[registry]]
prefix = "docker.io"
location = "dockerhub.mirrors.nwafu.edu.cn"
```

## GOPROXY

Go 1.13 或以上版本 (推荐)

打开终端执行一次以下命令即搞定：

```
go env -w GO111MODULE=on
go env -w GOPROXY=https://goproxy.cn,direct
```

或者使用老方式:
```
export GO111MODULE=on
export GOPROXY=https://goproxy.cn
```

官方文档： https://goproxy.cn/

## NPM


临时使用
```
npm --registry https://registry.npmmirror.com install express
```
永久使用
```
npm config set registry https://registry.npmmirror.com
```

配置CNPM

这样的话，你用npm走的还是官方的，cnpm走的代理
```
npm install -g cnpm --registry=https://registry.npm.taobao.org
```

验证是否设置成功

```
npm info express
or
npm config get registry

```

## PiP
 - 阿里云 http://mirrors.aliyun.com/pypi/simple/

 - 中国科技大学 https://pypi.mirrors.ustc.edu.cn/simple/

 - 豆瓣(douban) http://pypi.douban.com/simple/

 - 清华大学 https://pypi.tuna.tsinghua.edu.cn/simple/

 - 中国科学技术大学 http://pypi.mirrors.ustc.edu.cn/simple/

使用方法很简单，直接 -i 加 url 即可！如下：
```
＃　pip install web.py -i http://pypi.douban.com/simple
```

如果有如下报错：
```
root@kali:~# pip install virtualenvwrapper -i http://pypi.douban.com/simple
Collecting virtualenvwrapper
  The repository located at pypi.douban.com is not a trusted or secure host and is being ignored. If this repository is available via HTTPS it is recommended to use HTTPS instead, otherwise you may silence this warning and allow it anyways with '--trusted-host pypi.douban.com'.
  Could not find a version that satisfies the requirement virtualenvwrapper (from versions: )
No matching distribution found for virtualenvwrapper
```

请使用命令：
```
# pip install virtualenvwrapper -i http://pypi.douban.com/simple --trusted-host pypi.douban.com
```

如果想配置成默认的源，方法如下：

需要创建或修改配置文件（一般都是创建），linux的文件在~/.pip/pip.conf，windows在%HOMEPATH%\pip\pip.ini），修改内容为：
```
[global]
index-url = http://pypi.douban.com/simple
[install]
trusted-host=pypi.douban.com
```

这样在使用pip来安装时，会默认调用该镜像。

临时使用其他源安装软件包的python脚本如下：

```
#!/usr/bin/python

import os

package = raw_input("Please input the package which you want to install!\n")
command = "pip install %s -i http://pypi.mirrors.ustc.edu.cn/simple --trusted-host pypi.mirrors.ustc.edu.cn" % package
os.system(command)
```
 
