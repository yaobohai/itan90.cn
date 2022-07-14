---
layout: post
cid: 53
title: MACOS上安装Ansible
slug: 53
date: 2021/11/06 12:23:00
updated: 2022/03/20 23:05:09
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
---

安装ansible主程序

```shell
brew install ansible
```
<!--more-->

安装sshpass

```shell
cd ~/Downloads

curl -O -L http://downloads.sourceforge.net/project/sshpass/sshpass/1.05/sshpass-1.05.tar.gz

tar xvzf sshpass-1.05.tar.gz

cd sshpass-1.05
Configure, make, and install the sshpass binary:

./configure

make

sudo make install

```

验证是否安装成功
```
ansible --version
```
![](https://s3.oss.oracle.itan90.cn/i/2021/11/06/k9n0d6.png)

配置主机组
```
vim ~/.ansible.cfg

[defaults]
inventory      = /hosts主机组配置路径/hosts
```