---
layout: post
cid: 127
title: 一个比较简单的DNSPOD DDNS脚本
slug: 127
date: 2022/06/04 22:53:08
updated: 2022/06/04 23:05:30
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

DDNS（Dynamic Domain Name Server）是动态域名服务的缩写。 DDNS是将用户的动态IP地址映射到一个固定的域名解析服务上，用户每次连接网络的时候客户端程序就会通过信息传递把该主机的动态IP地址传送给位于服务商主机上的服务器程序，服务器程序负责提供DNS服务并实现动态域名解析

假设当前你的家庭IP地址为`1.1.1.1`；那么简单的就可理解为 `脚本更新解析记录 --> ddns.xxx.com--> 用户访问--> ddns.xxx.com--> 1.1.1.1--> 脚本更新解析记录`；这么形成一个回环的过程，再结合`crontab`即可完成自动更新:[crontab表达式生成在线参考][1] <!--more-->

## 安装依赖包

```
$ yum -y install net-tools wget jq
```
## 编写脚本
```
$ cat route_ddns.sh

#!/usr/bin/env bash
# 密钥ID(通过DNSPOD控制台获取)
LOGIN_ID=''
# 密钥TOken(通过DNSPOD控制台获取)
LOGIN_TOKEN=''

# 主域名
SELECT_DOMAIN='itan90.cn'
# 解析二级域名
SELECT_HAND='home01'

# 获取当前主机公网IP地址
function GET_CURRENT_PUBLIC_IP() {
    local lanIps="^$"
    lanIps="$lanIps|(^10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$)"
    lanIps="$lanIps|(^127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$)"
    lanIps="$lanIps|(^169\.254\.[0-9]{1,3}\.[0-9]{1,3}$)"
    lanIps="$lanIps|(^172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3}$)"
    lanIps="$lanIps|(^192\.168\.[0-9]{1,3}\.[0-9]{1,3}$)"

    case $(uname) in
        'Linux')
        CURRENT_IP=$(wget --quiet --output-document=- http://ip.sb) ;;
        'Darwin')
        CURRENT_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | grep -Ev "$lanIps") ;; esac
    if [ -z "$CURRENT_IP" ]; then
      if type wget >/dev/null 2>&1; then
          CURRENT_IP=$(wget --quiet --output-document=- http://ip.sb)
      else
          CURRENT_IP=$(curl -s http://ip.sb)
      fi
    fi
}

# 检测当前是否存在域名记录

# 获取当前域名解析IP
function GET_RECORD_IP() {
  GET_RECORD_IP=$(curl -s  -X POST https://dnsapi.cn/Record.List -d "login_token=${LOGIN_ID},${LOGIN_TOKEN}&format=json&domain=${SELECT_DOMAIN}&sub_domain=${SELECT_HAND}&record_type=A&offset=0&length=3"|jq .records[].value|cut -d'"' -f2)
}

function GET_RECORD_ID() {
  GET_RECIRD_ID=$(curl -s  -X POST https://dnsapi.cn/Record.List -d "login_token=${LOGIN_ID},${LOGIN_TOKEN}&format=json&domain=${SELECT_DOMAIN}&sub_domain=${SELECT_HAND}&record_type=A&offset=0&length=3"|jq .records[].id|cut -d'"' -f2)
}

# 判断是否域名已解析IP与当前主机公网IP是否一致
function MONITOR_API() {
  if [[ $GET_RECORD_IP == ${CURRENT_IP} ]]; then
      echo 'IP解析无变化...'
      exit 1
  fi
}

# 修改域名解析IP
function ALTER_DOMAIN_IP() {
  GET_RECORD_ID
  curl -X POST https://dnsapi.cn/Record.Modify -d "login_token=${LOGIN_ID},${LOGIN_TOKEN}&format=json&domain=${SELECT_DOMAIN}&record_id=$GET_RECIRD_ID&sub_domain=${SELECT_HAND}&value=${CURRENT_IP}&record_type=A&record_line_id=10%3D0" &>/dev/null
  if [[ $? == 0 ]]; then
    echo 'alter domain record successfly...'
  fi

}

# IP变更提醒
# 可自行添加IP变动发送提醒脚本
#function UPDATE_SEND() {
#  if [[ $GET_RECORD_IP != ${CURRENT_IP} ]];then
#          MESSAGE=$(printf "(*>﹏<*)宿舍公网IP变更提醒(*>﹏<*)\\n获取IP: ${CURRENT_IP}\\n解析域名: ${SELECT_HAND}.${SELECT_DOMAIN}\\n解析结果: successfly...")
#          python /opt/qq.py "$MESSAGE"
#  fi
# }

GET_CURRENT_PUBLIC_IP
GET_RECORD_IP
MONITOR_API
#UPDATE_SEND
ALTER_DOMAIN_IP
```

## 使用

```
sh route_ddns.sh
```

## 消息通知(可选配置)

这里给出几个推荐的消息通知推送平台:

- [Qmsg酱][2]
- [Server酱][3]
- [Bark][4]
- 企业微信&钉钉通知钩子


  [1]: https://tooltt.com/crontab/c/34.html
  [2]: https://qmsg.zendee.cn/
  [3]: https://sct.ftqq.com/
  [4]: https://github.com/Finb/Bark