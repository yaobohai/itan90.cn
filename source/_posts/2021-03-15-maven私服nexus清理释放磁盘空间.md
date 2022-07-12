---
layout: post
cid: 9
title: maven私服nexus清理释放磁盘空间
slug: 9
date: 2021/03/15 10:49:10
updated: 2021/03/15 10:49:10
status: publish
author: sunday
categories: 
  - 默认分类
tags: 
  - 运维
customSummary: 
mathjax: auto
noThumbInfoStyle: code
outdatedNotice: no
reprint: trans
thumb: 
thumbChoice: default
thumbDesc: 
thumbSmall: 
thumbStyle: default
---

maven私服nexus清理释放磁盘空间 <!--more-->

## 应用背景

自建的maven私服（或者叫私仓）nexus在使用过程中，因很多服务不断迭代更新上传jar包至nexus中，底层存放在一个叫Blob Stores的存储中，开发通知maven只能下载依赖不能上传依赖了，登录nexus服务器发现该存储已增大至好几百G。

浏览器页面上传依赖报错：

    Error occurred while executing a write operation to database 'component' due to limited free space on the disk (4058 MB). The database is now working in read-only mode. Please close the database (or stop OrientDB), make room on your hard drive and then reopen the database. The minimal required space is 4096 MB. Required space is now set to 4096MB (you can change it by setting parameter storage.diskCache.diskFreeSpaceLimit) . DB name="component"


意思的nexus要求最少有4096MB的磁盘空间，现在剩余的不够了。

同时上面的错误也指出了有俩种解决办法

解决方案一
设置storage.diskCache.diskFreeSpaceLimit变量


```bash
    ]$ vim $nexus_home/bin/nexus.vmoptions
    -Xms2703m
    -Xmx2703m
    -XX:MaxDirectMemorySize=2703m
    -XX:+UnlockDiagnosticVMOptions
    -XX:+LogVMOutput
    -XX:LogFile=../sonatype-work/nexus3/log/jvm.log
    -XX:-OmitStackTraceInFastThrow
    -Djava.net.preferIPv4Stack=true
    -Dkaraf.home=.
    -Dkaraf.base=.
    -Dkaraf.etc=etc/karaf
    -Djava.util.logging.config.file=etc/karaf/java.util.logging.properties
    -Dkaraf.data=../sonatype-work/nexus3
    -Dkaraf.log=../sonatype-work/nexus3/log
    -Djava.io.tmpdir=../sonatype-work/nexus3/tmp
    -Dkaraf.startLocalConsole=false
    -Dstorage.diskCache.diskFreeSpaceLimit=2048                    # 新添加的参数，设置为2g
```
重启nexus服务即可上传服务，不过不能解决根本问题，根本问题就是删没用的包，或者扩容磁盘。

解决方案二
1.在nexus界面清理对应的旧版本或者想要清理的应用包，如图示：

![][1]

注意：在删除多个目标后，你会发现，实际物理磁盘并没有释放出来，是因为在后台只是被标记为deletion，就好比你用delete语句删除mysql中的条目时，磁盘空间不会释放出来一样，因此，还需要第二步操作。

2.创建一个定时任务，任务类型为Compact Blobstore，然后填写定时任务详情，如下

![][2]

3.手动运行一次定时任务，然后重新去服务器查看磁盘空间变小了。


  [1]: https://oss.nnv5.cn/admin/20201203170328.png
  [2]: https://oss.nnv5.cn/admin/20201203170829.png