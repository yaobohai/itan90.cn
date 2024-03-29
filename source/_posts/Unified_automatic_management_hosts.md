---
layout: post
cid: 120
title: 统一自动管理系统hosts文件方案
slug: 120
date: 2022/04/23 13:20:00
updated: 2022/04/23 19:33:58
status: publish
author: sunday
categories: 
  - 技术分享
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

多设备、跨平台的场景下，我们可能需要将这些设备统一主机名方式访问，而又没有维护私有的dns服务器。这个时候我们就可以通过订阅自己维护的hosts文件来解决。下面简单介绍几个跨平台的解决方法。<!--more-->

## 维护文件

相对于维护一个私有化的dns服务器来说，hosts文件更容易维护，可以只是一个文本，托管到Git或web服务器中。而我的hosts订阅文件就通过Github托管并自动更新到web服务器中。客户端只需统一订阅这个hosts文件。每次通过Git提交或手动修改即可。例如：http://mirrors.itan90.cn/scripts/other/update_hosts/default_hosts

## 基于Unix

对于Linux来说，我们可以通过简单的一个Shell脚本来完成，例如下面这个脚本：

```bash
#!/bin/bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

default_local_hostsfile='/etc/hosts'
bak_default_local_hostsfile='/opt/hosts.bak'

# 订阅的hosts文件地址
remote_hostsfile='http://mirrors.itan90.cn/scripts/other/update_hosts/default_hosts'

function main(){
        export DATA_TIME=$(date '+%Y-%m-%d %H:%M:%S')
	cat ${bak_default_local_hostsfile} > ${default_local_hostsfile}
	echo '' >> ${default_local_hostsfile}
	echo "# [$DATA_TIME] update" >> ${default_local_hostsfile}
	curl -s -k ${remote_hostsfile} >> ${default_local_hostsfile}
}

if [[ -f ${bak_default_local_hostsfile} ]];then 
	main
else
	cat ${default_local_hostsfile} > ${bak_default_local_hostsfile}
	main
fi

```

通过运行上面这个脚本文件就会将原有的hosts文件`(/etc/hosts)`备份至`(/opt/hosts.bak)` 而后将新获取的地址以追加的方式写入/etc/hosts。结合crontab即可完成自动更新。

## 基于Win/Mac

这里介绍一个软件：`switchHosts` 一个修改、管理、切换多个 hosts 方案的开源工具。通过这个工具，我们可以通过URL的方式订阅远端hosts文件并自动更新写入系统的hosts文件内。

![hosts.jpeg][1]

至此，我们就通过简单的方法来统一了多设备、跨系统的hosts文件更新方法。这里建议是通过将文件托管至Gitee或Github的方式来管理，之后的每次修改更新客户端只要订阅了文件的Git地址即可完成更新，快速且方便。

参考文章：

SwitchHosts官网：https://github.com/oldj/SwitchHosts
switchHosts应用时，没有写入 Hosts 文件的权限：https://www.cfanz.cn/resource/detail/GWqmjAglGEyZK

  [1]: https://oss.itan90.cn/out_pic/2022-07-12/irkRcR.jpg