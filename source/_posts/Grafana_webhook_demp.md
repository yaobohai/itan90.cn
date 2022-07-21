---
title: grafana告警与webhook配置
date: 2022-07-21 16:51:16
categories: 运维笔记
---

一、什么是webhook?

1. webhook简介

用过Jenkins自动化构建项目的流程都知道，当git push之后，git的webhook机制便会发出请求，向Jenkins服务器通知开始执行构建流程。
Webhooks可以理解为满足特定的事件触发时（例如git push代码后，或者grafana触发告警），源网站发起一个HTTP请求到webhook配置的URL。webhook收到请求后进行相对应的处理（比如Jenkins自动构建项目，或者转发grafana告警）。
概括来说，就是在一个系统触发事件后，另一个系统收到请求并处理相应的任务，而收到请求并处理的部分便是webhook

2.grafana使用webhook场景

虽然grafana内置了非常丰富的告警媒介（例如邮箱、钉钉、slack、Prometheus Alertmanager等）具体参考官方文档：https://grafana.com/docs/grafana/latest/alerting/notifications/。
但是如果需求是收到grafana告警后执行一系列的其他操作，此时内置的告警媒介便不能满足需求，例如在企业内部已有告警平台接口，实现了告警分级通知，分组通知等功能。但是grafana告警事件与现有的告警平台接口并不能直接对接，因为grafana告警输出格式与告警平台接入格式并不匹配。此时就要用到webhook充当中间人角色，收到grafana告警内容后做一系列处理工作，转换为告警接口要求的请求格式，从而实现告警触发。

 <!--more-->

![](https://oss.itan90.cn/out_pic/2022-07-21/N5J4qT.jpg)



## webhook程序编写

### 1. 需求分析

webhook程序功能很简单，就是运行一个监听端口的服务。当webhook收到grafana的请求后，获取到request的body内容，进行一系列的处理后，返回给grafana一个正常的response。

### 2. 示例程序

> 此处使用python的flask框架开启一个webhook服务为例

```python
from flask import Flask, request

app = Flask(__name__)

@app.route('/', methods=["POST"])
def index():
    req = request.json
    print(req)
    return 'success!'

if __name__ == '__main__':
    app.run(debug=True,host='0.0.0.0',port=8099)
```

## webhook配置

1. 点击添加告警通知

![](https://oss.itan90.cn/out_pic/2022-07-21/Kxanxn.jpg)

2. 添加webhook通知配置

![](https://oss.itan90.cn/out_pic/2022-07-21/Ym6TAx.jpg)

3. 点击test发送测试告警，查看flask程序控制台是否打印请求内容

![](https://oss.itan90.cn/out_pic/2022-07-21/ZumO8u.png)


至此，一个简单的webhook基本功能就实现了。接下来根据实际的业务需求，编写相关的逻辑代码即可。






