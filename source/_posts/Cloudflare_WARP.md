---
layout: post
cid: 49
title: 通过 Cloudflare WARP 隐藏真实IP解锁Google验证码
slug: 49
date: 2021/10/02 01:29:00
updated: 2021/10/02 02:17:32
status: publish
author: sunday
customSummary: 
mathjax: auto
noThumbInfoStyle: default
outdatedNotice: no
reprint: internet
thumb: https://img.paulzzh.com/touhou/random
thumbChoice: default
thumbDesc: 
thumbSmall: https://img.paulzzh.com/touhou/random
thumbStyle: default
categories:
  - 技术分享
---

WARP是Cloudflare提供的一项基于WireGuard的网络流量安全及加速服务，能够让你通过连接到Cloudflare的边缘节点实现隐私保护及链路优化。它可以帮我们解决以下常见问题：

 - WARP 网络出入口均为双栈 (IPv4/IPv6)，因此单栈服务器可以连接到 WARP 来获取额外的网络连通性支持。
 - 只有IPv6的VPS可获得 IPv4 网络的访问能，不再局限于 DNS64 的束缚，能自定义任意 DNS 解析服务器。对使用某科学的上网工具有奇效。
 - 只有IPv4的VPS可获得 IPv6 网络的访问能力，可作为 IPv6 Only VPS 的 SSH 跳板。
 - 此外 WARP 的IPv6 网络的质量比HE IPv6 Tunnel Broker 甚至自带的都要好，很少绕路。

WARP 对外访问网络的 IP 被很多网站视为真实用户，即所谓的 `原生` IP，可以解除某些网站基于 IP 的封锁限制：

 - 解锁Netflix非自制剧；
 - 跳过Google验证码；
 - 解除Google学术访问限制；
 - 解除YouTube Premium定位漂移和地区限制；

比如下面这个糟糕的验证：

![Google验证.png][1]

<!--more-->

## 使用

注意：均需在 `root` 用户下执行

### 获取脚本

    $ wget http://mirrors.itan90.cn/CFWarp-Pro/multi.sh && bash multi.sh

原作者脚本地址如下 (因升级内核版本脚本404；所以我Fork了一份)

    # $ wget https://raw.githubusercontent.com/aitlp/CFWarp-Pro/main/multi.sh


### 升级内核

因为WARP需要内核版本 `>=5.6` 以上，所以如果系统版本达不到要求，就需要根据系统版本，更新内核

![升级内核.png][2]

运行后等待VPS重启后重连，重新执行脚本;并选择你的服务器集成模式
    # 例如我的VPS是只有IPV4的IP；那么我就运行：6
    $ bash multi.sh

![集成IP.png][3]

最后命令执行成功最新下会给出提示。


## 帮助

此后，如果需要查询本机获取的虚拟IP信息,可通过以下命令获取：

    $ curl -s -O http://mirrors.itan90.cn/scripts/ip_query && chmod +x ip_query && ./ip_query
    # 执行后返回一以下信息：
    虚拟 IPV4 地址: 114.0.0.0.0
    虚拟 IPV6 地址: 240e:388...
    真实 IPV4 地址: 114.0.0.0.0
    真实 IPV6 地址: 240e:388...


  [1]: https://oss.itan90.cn/out_pic/2022-07-20/Tpzhyy.jpg
  [2]: https://oss.itan90.cn/out_pic/2022-07-20/jp83mZ.jpg
  [3]: https://oss.itan90.cn/out_pic/2022-07-20/Xaa6ls.jpg