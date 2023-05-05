---
layout: post
title: 使用aws的cloudfront来加速websocket应用
date: 2023/04/23 22:50:00
categories: 技术分享
---

![](https://resource.static.tencent.itan90.cn/mac_pic/2023-05-05/Dn3aVU.jpg)

在此之前可能很多小伙伴Cloudflare用的比较多，CloudFront则可能是用的少之又少，本篇文章则分享下以富强应用为代表的websocket在CloudFront中的配置流程。

好的，来看下关于CloudFront的介绍吧～

CloudFront是aws亚马逊云推出的全球CDN功能，并且拥有Cloudflare免费套餐没有的亚太地区的加速节点，得益于具有免费套餐；每个账户可获得一定的 [免费额度](https://aws.amazon.com/cn/cloudfront/pricing/?loc=ft#AWS_Free_Usage_Tier) 如：

- 每月 1 TB 传出数据
- 每月 10000000 个 HTTP 或 HTTPS 请求
- 每月 200 万次 CloudFront 函数调用
- 免费 SSL 证书(泛域名)
- 并且网络体验效果优于Cloudflare

亚马逊云的优点上面也介绍了，但也有些许不友好的地方，如：

- 注册需要外币信用卡(visa卡)
- 配置起来略微复杂于其他云厂商

具体的配置方法在下术章节来体现吧～

<!--more-->

# 准备工作

开始之前需要的材料如下：

- 域名一只
- VISA信用卡一张
- 域名具有admin邮箱 (可选)


之后在 [注册 AWS ](https://portal.aws.amazon.com/billing/signup?nc2=h_ct&src=header_signup&redirect_url=https%3A%2F%2Faws.amazon.com%2Fregistration-confirmation&language=zh_cn#/start/email) 页面注册账号

# 实战配置

## 创建账户

## 创建分配

进入CloudFront的 [控制台](https://us-east-1.console.aws.amazon.com/cloudfront/v3/home)

首先是设置需要加速的域名，这里需要注意下，aws的cf产品设计于其他云厂商不太一样，他的源节点，也就是需要加速的真实的后端节点需要填写域名的方式,而其他云厂商则大部分是填写IP地址。

那么我们先解析一条A记录的域名，如：`tmt-seattle-node02.init.ac` 解析到具体后端节点IP，如 `1.1.1.1`，解析好之后，直接将需要加速的域名填进去，仅仅处理HTTPS，最低的SSL选择 `TLSv1.2`

![](https://resource.static.tencent.itan90.cn/mac_pic/2023-05-05/FjLkER.png)



