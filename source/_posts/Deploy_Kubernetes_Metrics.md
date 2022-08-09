---
title: 使用Kubernetes Metrics收集Kubernetes指标
date: 2022-08-09 11:12:16
categories: 运维笔记
---

如果您曾经在 Linux 系统上工作过，那么您很可能使用过top命令。如果您知道该命令，您将很快习惯 Kubernetes 中的命令是如何工作的。如果你不这样做，不要害怕！虽然kubectl top 是一个强大的命令，但使用起来非常简单。<!--more-->

## 安装Metrics

1、检查是否安装

```shell
kubectl get pods --all-namespaces | grep metrics-server
```
2、如果没有安装 那执行以下命令即可安装

```shell
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

安装完成后可使用第一步的命令来检查`metrics`pod是否running 可通过 `kubectl logs -f --tail=200 -n kube-system metrics-server-xxxxx` 来获取运行日志。

如果遇到报错：

```shell
E0908 15:28:39.751310       1 scraper.go:139] "Failed to scrape node" err="Get \"https://10.68.14.125:10250/stats/summary?only_cpu_and_memory=true\": x509: cannot validate certificate for 10.68.14.125 because it doesn't contain any IP SANs" node="kube-node01"
```

可将 https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml下载到本地。修改yaml文件:

```yaml
132     spec:
133       containers:
134       - args:
135         - --cert-dir=/tmp
136         - --secure-port=4443
137         - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
138         - --kubelet-use-node-status-port
139         - --metric-resolution=15s
140         - --kubelet-insecure-tls  # 添加
141         - --metric-resolution=30s # 添加
```

在metrics的容器里增加参数后，重新apply文件即可


4、使用

```shell
$ kubectl top node

NAME          CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
kube-master   2594m        64%    2798Mi          36%
kube-node01   1137m        28%    1235Mi          16%
kube-node02   1509m        37%    1210Mi          15%

$ kubectl top pod -n {namespace}
.....
```