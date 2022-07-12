---
layout: post
cid: 43
title: Prometheus通过记录规则持久查询监控数据
slug: 43
date: 2021/09/06 18:37:00
updated: 2021/10/02 02:12:50
status: publish
author: sunday
categories: 
  - 运维
  - Pometheus
tags: 
  - 运维
customSummary: 
mathjax: auto
noThumbInfoStyle: default
outdatedNotice: no
reprint: standard
thumb: https://api.ixiaowai.cn/gqapi/gqapi.php
thumbChoice: default
thumbDesc: 
thumbSmall: https://api.ixiaowai.cn/gqapi/gqapi.php
thumbStyle: default
---
来看看吧 <!--more-->

## 作用

 1. 记录规则 — 从查询中创建新的指标。 
 2. 警报规则 - 从查询生成警报。 
 3. 可视化 — 使用像Grafana这样的仪表盘来可视化.

## 配置

  记录规则存储在Prometheus服务器上，存储在Prometheus服务器加载的文件中。规则是自动计算的，频率由
`prometheus.yml`全局块中的`evaluation_interval`参数控制。

### 配置修改

修改普罗米修斯主配置文件 `prometheus.yml`

    rule_files:
    - "rules/node_rules.yml"

### 配置规则

    [root@master ~]# mkdir /usr/local/prometheus/rules
    [root@master ~]# vim /usr/local/prometheus/rules/node_rules.yml

    # 写入规则
    groups:
    - name: node_rules
      interval: 10s
    
      rules:
      - record: instance:node_cpu:avg5m
        expr: 100 - avg (irate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance) * 100
    
      - record: instance:node_memory_usage:percentage
        expr: (node_memory_MemTotal_bytes - (node_memory_MemFree_bytes + node_memory_Cached_bytes + node_memory_Buffers_bytes)) / node_memory_MemTotal_bytes * 100
    
      - record: instance:root:node_filesystem_usage:percentage
        expr: (node_filesystem_size_bytes{mountpoint="/"} - node_filesystem_free_bytes{mountpoint="/"}) / node_filesystem_size_bytes{mountpoint="/"} * 100




### 重载配置

    [root@master ~]# ps -ef|grep prometheus|grep -v grep |awk '{print $2}'|xargs kill -HUP

## 查看

![rules][1]


  [1]: https://itan90.cn/usr/uploads/2021/09/3902747039.png