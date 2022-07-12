---
layout: post
cid: 102
title: 解决一次V2ray无法连接问题
slug: 102
date: 2022/03/17 01:11:00
updated: 2022/03/17 09:19:19
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


某种情况下重启了一次持续运行长达半年的代理服务器；重启后v2ray炸了(实际上我也炸了) ; 什么配置都没有改的情况下竟不能使用了。连续两天都没时间看这个问题，今晚抽空解决了下；在此分享下  <!--more-->

客户端通过代理访问网站浏览器报错：ERR_CONNECTION_TIMED_OUT

服务端报错：
```
rejected  common/drain: common/drain: drained connection > proxy/vmess/encoding: invalid user: VMessAEAD is enforced and a non VMessAEAD connection is received. You can still disable this security feature with environment variable v2ray.vmess.aead.forced = false . You will not be able to enable legacy header workaround in the futur

译文：无效用户：强制执行VMessAEAD并收到非VMessAEAD连接。 您仍然可以使用环境变量 v2ray.vmess.aead.forced = false 禁用此安全功能。 您将无法在未来启用旧版标头解决方法。
```

那么从上我们大概知道，VMess的认证信息淘汰机制发生了变化，而我们要解决的话就是需要配置环境变量: `v2ray.vmess.aead.forced = false`;于是我在启动v2ray的时候修改了启动文件，最终确实可以得以解决这个问题。

```
$ vim /etc/systemd/system/v2ray.service

[Unit]
Description=V2Ray Service
Documentation=https://www.v2fly.org/
After=network.target nss-lookup.target

[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true

# 这两段就是我们需要增加/修改的
Environment="V2RAY_VMESS_AEAD_FORCED=false"
ExecStart=/usr/bin/env v2ray.vmess.aead.forced=false /usr/local/bin/v2ray -config /usr/local/etc/v2ray/config.json

Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target

```

问题的如何解决我们已经知道了，但事情的缘由；我们还不知道；于是我通过在网上查找，最终找到了一份比较详细的说明：
```
if s.userValidator.ShouldShowLegacyWarn() {
    newError("Critical Warning: potentially invalid user: a non VMessAEAD connection is received. From 2022 Jan 1st, this kind of connection will be rejected by default. You should update or replace your client software now. This message will not be shown for further violation on this inbound.").AtWarning().WriteToLog()
}
```

```
VMess MD5 认证信息 玷污机制
为了进一步对抗可能的探测和封锁，自 v4.24 版本起，每个 VMess 认证数据的服务器端结构都会包含一个一次写入的玷污状态标记，初始状态为无瑕状态，当服务器检测到重放探测时或者因为其他原因入站连接出错以致校验数据不正确时，该连接所对应的请求认证数据会被玷污。

被玷污的认证数据无法被用于建立连接，当攻击者或客户端使用被玷污的认证数据建立连接时，服务器会输出包含 "invalid user" "ErrTainted" 的错误信息，并阻止该连接。

当服务器没有受到重放攻击时，该机制对正常连接的客户端没有影响。如果服务器正在被重放攻击，可能会出现连接不稳定的情况。

拥有服务器 UUID 以及其他连接数据的恶意程序可能根据此机制对服务器发起拒绝服务攻击，受到此类攻击的服务可以通过修改 proxy/vmess/validator.go 文件中 func (v *TimedUserValidator) BurnTaintFuse(userHash []byte) error 函数的 atomic.CompareAndSwapUint32(pair.taintedFuse, 0, 1) 语句为 atomic.CompareAndSwapUint32(pair.taintedFuse, 0, 0) 来解除服务器对此类攻击的安全保护机制。使用 VMessAEAD 认证机制的客户端不受到 VMess MD5 认证信息 玷污机制 的影响。

#VMess MD5 认证信息 淘汰机制
VMessAEAD 协议已经经过同行评议并已经整合了相应的修改。 VMess MD5 认证信息 的淘汰机制已经启动。

自 2022 年 1 月 1 日起，服务器端将默认禁用对于 MD5 认证信息 的兼容。任何使用 MD5 认证信息的客户端将无法连接到禁用 VMess MD5 认证信息的服务器端。

在服务器端可以通过设置环境变量 v2ray.vmess.aead.forced = true 以关闭对于 MD5 认证信息的兼容。 或者 v2ray.vmess.aead.forced = false 以强制开启对于 MD5 认证信息 认证机制的兼容 （不受到 2022 年自动禁用机制的影响） 。 (v4.35.0+)
```

不得不说一句这个确实有点坑了。而且是从今年开始的；另外就是在解决这个问题之前；我也曾看到过很多文章上面说，需要修改系统时间或是将额外ID（alterId） 修改为：0 来解决，很不凑巧的是我没在看日志之前，也通过这两种方法尝试过，但都没有解决。建议还是不要走弯路，用原生的方法试下。

更多内容参考: 

底层传输配置说明文档：https://www.v2ray.com/chapter_02/05_transport.html 

相关源码: 
https://github.com/v2fly/v2ray-core/blob/a21e4a7deb2d60b40ea4ebcedf6e22a56dcb4d04/proxy/vmess/encoding/server.go#L200  
https://github.com/v2fly/v2ray-core/blob/3ef7feaeaf737d05c5a624c580633b7ce0f0f1be/proxy/vmess/encoding/server.go#L194


