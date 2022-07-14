---
layout: post
cid: 63
title: 在 M1 Pro Mac 上构建 x86 Docker 镜像
slug: zai-m1-pro-mac-shang-gou-jian-x86-docker-jing-xian
date: 2021/11/19 20:35:00
updated: 2022/03/20 23:04:39
status: publish
author: sunday
categories: 
  - 默认分类
  - MacOS
  - 技巧分享
tags: 
  - 博客文档
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

## 新建Builder实例

Docker 默认的 builder 不支持同时指定多个架构，所以要新建一个：

```
docker buildx create --use --name M1Pro_Builder
```
查看并启动 Builder 实例：

```
docker buildx inspect --bootstrap
```

platforms就是代表支持的架构，跨平台构建的底层是用 QEMU 实现的。

![](https://oss.itan90.cn/2021/11/20/16373479934829.jpg)


## 准备构建多架构镜像

DOCKERFILE这里以Cerebro程序为例。Github地址：https://github.com/lmenezes/cerebro-docker/blob/master/Dockerfile

```
# 编写Dockerfile
vim cerebro.dockerfile
```
```
FROM openjdk:11.0.10-jre-slim

ENV CEREBRO_VERSION 0.9.4

RUN  apt-get update \
 && apt-get install -y wget \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /opt/cerebro/logs \
 && wget -qO- https://github.com/lmenezes/cerebro/releases/download/v${CEREBRO_VERSION}/cerebro-${CEREBRO_VERSION}.tgz \
  | tar xzv --strip-components 1 -C /opt/cerebro \
 && sed -i '/<appender-ref ref="FILE"\/>/d' /opt/cerebro/conf/logback.xml \
 && addgroup -gid 1000 cerebro \
 && adduser -gid 1000 -uid 1000 cerebro \
 && chown -R cerebro:cerebro /opt/cerebro

WORKDIR /opt/cerebro
USER cerebro

ENTRYPOINT [ "/opt/cerebro/bin/cerebro" ]
```

使用 Buildx 构建：

```
# 构建单架构amd64时
docker buildx build \
  -f cerebro.dockerfile \
  --platform linux/amd64 \
  --push -t registry.cn-hangzhou.aliyuncs.com/bohai_repo/cerebro-multi:latest .

```

```
# 构建多架构arm、amd64时
docker buildx build \
  -f cerebro.dockerfile \
  --platform linux/amd64,linux/arm64 \
  --push -t registry.cn-hangzhou.aliyuncs.com/bohai_repo/cerebro-multi:latest .
```

其中, `-f` 是需要进行构建的Dockerfile，`--push` 表示将构建好的镜像推送到 Docker 仓库,`-t` 参数指定远程仓库。如果不想直接推送，也可以改成 `--load`，即将构建结果加载到镜像列表中,但加载到镜像列表时，便不支持多架构的构建方式。构建时将会报错：

```
error: docker exporter does not currently support exporting manifest lists
```

接着上面的构建参数，`--platform` 参数就是要构建的目标平台，这里我就选了本机的 arm64 和服务器用的 amd64。最后的 .（构建路径）注意不要忘了加。

![](https://oss.itan90.cn/2021/11/20/16373538490724.jpg)

构建完 push 上去以后，可以查看远程仓库的 manifest信息：

```
docker buildx imagetools inspect registry.cn-hangzhou.aliyuncs.com/bohai_repo/cerebro-multi:latest|grep Platform
```
![](https://oss.itan90.cn/2021/11/20/16373539835172.jpg)

如果如上图，同时返回多种架构，则构建成功。

本文完～