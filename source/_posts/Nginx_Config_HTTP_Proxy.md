---
layout: post
cid: 41
title: NGINX配置HTTP/HTTPS代理
slug: 41
date: 2021/08/05 13:43:00
updated: 2021/08/05 13:50:47
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

在局域网中有些服务器可能无法上网，但同局域网中的有些认证服务器可以联网，那么我们就可以在可以联网的服务器中配置该服务，让不能上网的服务器也实现网络通讯 <!--more-->

## 配置

在http区域加入两个server段,一个为http代理服务，一个为https；详细配置段如下：

HTTP段落：

    server {
        # 指定DNS服务器IP地址
        resolver 114.114.114.114;
        # 监听端口
        listen 880;
        location / {
            # 设定代理服务器的协议和地址
            proxy_pass http://$http_host$request_uri;
                    proxy_set_header HOST $http_host;
                    proxy_buffers 256 4k;
                    proxy_max_temp_file_size 0k;
                    proxy_connect_timeout 30;
                    proxy_send_timeout 60;
                    proxy_read_timeout 60;
                    proxy_next_upstream error timeout invalid_header http_502;
           }
      }

HTTPS段落：

    server {
        resolver 114.114.114.114;
        listen 8881;
        location / {
           proxy_pass https://$host$request_uri;    #设定代理服务器的协议和地址
           proxy_buffers 256 4k;
           proxy_max_temp_file_size 0k;
           proxy_connect_timeout 30;
           proxy_send_timeout 60;
           proxy_read_timeout 60;
           proxy_next_upstream error timeout invalid_header http_502;
            }
    }

## 使用

### Linux

临时配置：

    [root@localhost ~]# export http_proxy='http://代理服务器IP:端口号 
    [root@localhost ~]# export https_proxy='http://代理服务器IP:端口号'

永久配置：

    [root@localhost ~]# vim /etc/profile
    export http_proxy='http://代理服务器IP:端口号'
    export https_proxy='http://代理服务器IP:端口号'
    
    [root@localhost ~]# source /etc/profile


### Windows
![Windows10][1]

### Linux for yum

    [root@localhost ~]# vim /etc/yum.conf
    proxy=http://代理服务器IP:端口号


### Python for pip

看这个链接：https://my.oschina.net/tangshi/blog/699190


  [1]: https://www.itan90.cn/usr/uploads/2021/08/938219213.png