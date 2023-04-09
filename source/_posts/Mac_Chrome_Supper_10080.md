---
layout: post
cid: 58
title: Mac修改Chrome的启动参数，取消chrome对端口号的限制
slug: su-she
date: 2021/11/12 19:12:00
updated: 2022/03/20 23:05:01
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

公司内部Gitlab的端口是10080，Chrome访问这个端口会报错：ERR_UNSAFE_PORT
![](https://oss.itan90.cn/2021/11/13/16367446004919.jpg)

<!--more-->

这种情况下就比较恶心了，为了解决这个问题，我找了两种方法来解决：

## 修改启动参数

通过修改启动Chrome的参数，在启动时增加允许不安全端口的访问

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

但是通过这种方法修改后，重启mac，chrome则会有打不开的情况，至今未找到解决方法，为此，可参考第二种方法来解决

## 使用反向代理

可以尝试在mac中安装一个nginx来返代访问gitlab,具体配置如下：

```shell
server{
    listen 80;
    listen 10080;
    server_name Gitlab访问域名;
    location / {
        proxy_pass http://Gitlab的服务器IP:10080/;
        proxy_http_version 1.1;
        proxy_buffering off;
        proxy_request_buffering off;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $host;
	    # 如果被引导到了10080端口就重新引导到80端口
	    proxy_redirect http://Gitlab访问域名:10080 http://Gitlab访问域名;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```