---
layout: post
cid: 109
title: MacOS隐藏Dock栏图标分享
slug: 109
date: 2022/03/20 23:08:00
updated: 2022/03/26 17:03:12
status: publish
author: sunday
categories: 
  - MacOS
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

主要是为了解决部分软件比如 iTerm、迅雷 ，我们只想放在后台运行不去管他；如果一直长在Dock中显得十分碍眼的解决办法。<!--more-->

---------


第一步: 打开访达 --> 应用程序 --> 找到碍眼的程序 --> 右键 --> 显示包内容

第二步: 展开文件夹 `Contents`

第三步: 随意编辑器编辑 `Contents` 下的 `Info.plist` 在 `dict` 标签下新增一段代码；如下所示

```
<key>LSUIElement</key>
<true/>
```
![][1]


第四步: 重启软件；图标消失

  [1]: https://s3.oss.oracle.itan90.cn/i/2022/03/20/12bn9z7.png

---------

2022年03月26日 

系统重启后出现无法打开程序问题，例如iTerm2 覆盖安装可解决（配置不会丢失）暂未有解决的方法。

可参考：https://segmentfault.com/q/1010000008680231