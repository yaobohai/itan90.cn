---
layout: post
title: 使用aws的cloudfront来加速websocket应用
date: 2023/05/05 10:50:00
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

之后在 [注册 AWS ](https://portal.aws.amazon.com/billing/signup?nc2=h_ct&src=header_signup&redirect_url=https%3A%2F%2Faws.amazon.com%2Fregistration-confirmation&language=zh_cn#/start/email) 页面注册账号

# 实战配置

## 创建账户

注册账户略微复杂，步骤繁琐，这里不再提到，可自行查阅文档。

## 创建分配

进入CloudFront的 [控制台](https://us-east-1.console.aws.amazon.com/cloudfront/v3/home)

### 源配置

首先是来到源配置，在源配置中配置需要加速的域名，这里需要注意下，aws的cf产品设计于其他云厂商不太一样，他的源节点，也就是需要加速的真实的后端节点需要填写域名的方式,而其他云厂商则大部分是填写IP地址。

那么我们先解析一条A记录的域名，如：`tmt-seattle-node02.init.ac` 解析到具体后端节点IP，如 `1.1.1.1`，并且在nginx中添加该域名，可参考下述配置，解析好之后，直接将需要加速的域名填进去，仅仅处理HTTPS，最低的SSL选择 `TLSv1.2`


```shell
# nginx中使用tmt-seattle-node02.init.ac域名
server {
    listen 443 ssl http2;
    server_name tmt-seattle-node02.init.ac;
    .....
```

![](https://resource.static.tencent.itan90.cn/mac_pic/2023-05-05/FjLkER.png)

其他配置先默认不管

### 默认缓存行为

来到默认缓存行为配置处，在查看器协议策略处，改为`HTTPS only` ; 缓存键和源请求改为 `Legacy cache settings` 其余配置则都为默认即可

![](https://resource.static.tencent.itan90.cn/mac_pic/2023-05-05/ur4GcQ.png)


### 函数关联

不配置

### 设置

来到设置处，在备用域名(CNAME)这里，我们先留意一下，后面需要配置，此处先忽略


点击创建分配处，完成分配的创建

## 测试访问

![](https://resource.static.tencent.itan90.cn/mac_pic/2023-05-05/YXcg7l.png)

创建好之后，会分配给我们一个代理后的CDN地址: `d1f2etmdjsscrh.cloudfront.net`，试着访问该域名的https协议，看是不是已经反代到了我们的网站。如果打开后是我们自己的网站，说明配置成功～

-----

到这里结束了吗？并没有。我们虽然已经成功使用aws的cf完成代理服务，但对外发布的域名并不是我们自己的域名，下面步骤来增加一个我们自己的域名对外发布使用。当然如果你想，也可以使用cloudfront.net这个域名啦

## 配置域名

### 申请证书

来到 AWS 的 [AWS Certificate Manager](https://us-east-1.console.aws.amazon.com/acm/home?region=us-east-1#/certificates/request) 申请一个证书

在完全限定域名处我们可以直接写 `*.xxx.com` 申请到为期一年的泛域名证书 (可惜只能在aws产品中使用～)；验证方法使用DNS验证(当然你的域名下如果有邮箱服务且邮箱名称是admin、administrator、hostmaster、postmaster、webmaster的任意一种，那么更适合使用邮箱来验证，邮箱验证的速度比dns要快很多),其他保持默认,接下来点你的证书ID，来到域这个地方，可以看到
状态为等待验证，需要在域名解析处添加一条cname解析。

![](https://resource.static.tencent.itan90.cn/mac_pic/2023-05-05/75oP1s.png)

等到后面验证通过即可，一般DNS验证时间比较久，需要耐心等待

![](https://resource.static.tencent.itan90.cn/mac_pic/2023-05-05/1DJ3U7.png)

### 绑定域名

完成dns验证后接着来到cloudfront的控制台，并点击具体的id进入`设置` --> `编辑` 页面

![](https://resource.static.tencent.itan90.cn/mac_pic/2023-05-05/OarhXd.png)

在 `备用域名(CNAME)`处填写我们自定义的域名 如：`tmt-seattle-node02-cdn.init.ac` 并绑定的自定义SSL证书；证书就选我们刚刚申请通过的

![](https://resource.static.tencent.itan90.cn/mac_pic/2023-05-05/dNQTf4.png)

之后保存提交，并在dns解析处新增加一条cname的解析：`自定义域名 cname解析到 cloudfront的域名` 如：

![](https://resource.static.tencent.itan90.cn/mac_pic/2023-05-05/VOH3Yb.png)

等到域名解析生效即可访问 https://自定义域名 来愉快的玩耍啦～