---
layout: post
cid: 39
title: (转)Linux VPS 上一键全自动dd安装Windows
slug: 39
date: 2021/07/22 16:32:00
updated: 2021/10/02 02:17:50
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

为什么国外的小鸡同配下windows比linux贵那么多，与国内不同，歪果仁版权意识非常高，windows软件及windows本身都是收费的，再加上歪果的程序员大多数都是基于linux开发，windows服务器维护技术人员少，物以稀为贵。 <!--more--> 


## 前言

<h2>适用范围</h2>

非**OVZ**架构，KVM、独立服务器均可使用
服务器IP需要DHCP获取的
linux下需为grub引导

## 特点
能够支持在无救援模式，无VNC模式下 DD windows（aws的lightsail DD windows 测试成功）
系统支持定制后再DD

## 脚本

Windows server 2003 for Kimsufi

    wget --no-check-certificate -qO DebianNET.sh 'https://moeclub.org/attachment/LinuxShell/DebianNET.sh' && bash DebianNET.sh -dd 'http://down.80host.com/iso/dd/Kimsufi2003.gz'

远程登录账号: Administrator
远程登录密码: password!yxz.me

Windows 7

    wget --no-check-certificate -qO DebianNET.sh 'https://moeclub.org/attachment/LinuxShell/DebianNET.sh' && bash DebianNET.sh -dd 'http://down.80host.com/iso/dd/Windows7-Joodle-Template.gz'

远程登录账号: Administrator
远程登录密码: Password147

Windows 8.1

    wget --no-check-certificate -qO DebianNET.sh 'https://moeclub.org/attachment/LinuxShell/DebianNET.sh' && bash DebianNET.sh -dd 'http://down.80host.com/iso/dd/Windows8.1-Joodle-Template.gz'

远程登录账号: Administrator
远程登录密码: Password147

Windows 10

    wget --no-check-certificate -qO DebianNET.sh 'https://moeclub.org/attachment/LinuxShell/DebianNET.sh' && bash DebianNET.sh -dd 'https://drive.google.com/file/d/1TmErU8F4SDePUfXixyGJyPDCj4EfTqat/view?usp=sharing'

远程登录账号: Administrator
远程登录密码: Password147

Windows server 2008 R2

    wget --no-check-certificate -qO DebianNET.sh 'https://moeclub.org/attachment/LinuxShell/DebianNET.sh' && bash DebianNET.sh -dd 'http://down.80host.com/iso/dd/WS2008R2Enterprise-Joodle-Template.gz'

远程登录账号: Administrator
远程登录密码: Password147
Windows server 2012 R2

    wget --no-check-certificate -qO DebianNET.sh 'https://moeclub.org/attachment/LinuxShell/DebianNET.sh' && bash DebianNET.sh -dd 'http://down.80host.com/iso/dd/Windows2012R2-Joodle-Template.gz'

远程登录账号: Administrator
远程登录密码: Password147

Leaseweb / Linode 专用

    wget --no-check-certificate -qO DebianNET.sh 'https://moeclub.org/attachment/LinuxShell/DebianNET.sh' && bash DebianNET.sh -dd 'http://down.80host.com/iso/dd/cn2003-virtio-pass-Linode.gz'

远程登录账号:Administrator
远程登录密码:Linode

## 关于磁盘空间
在磁盘管理中,点击’C‘盘,右键选择’扩展卷‘,可以直接’增加‘C盘的空间.

脚本来源: 萌咖