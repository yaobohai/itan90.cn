---
layout: post
cid: 58
title: Mac修改Chrome的启动参数，取消chrome对端口号的限制
slug: su-she
date: 2021/11/12 19:12:00
updated: 2022/03/20 23:05:01
status: publish
author: sunday
categories: 
  - 技术分享
  - MacOS
  - 技巧分享
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

来看看吧 <!--more-->

公司内部Gitlab的端口是10080，Chrome访问这个端口会报错：ERR_UNSAFE_PORT
![](https://oss.itan90.cn/2021/11/13/16367446004919.jpg)

这种情况下就比较恶心了，为了解决这个问题，我们是可以直接修改启动Chrome的参数来解决，可参考以下方式：

打开Mac的终端执行

```
cd "/Applications/Google Chrome.app/Contents/MacOS/"
sudo mv "Google Chrome" Google.real
```

```
sudo printf '#!/bin/bash\ncd "/Applications/Google Chrome.app/Contents/MacOS"\n"/Applications/Google Chrome.app/Contents/MacOS/Google.real" --explicitly-allowed-ports=10080,6000 "$@"\n' > Google\ Chrome

sudo chmod u+x "Google Chrome"
```

执行后，重启浏览器重新访问会惊奇的发现已经可以访问～