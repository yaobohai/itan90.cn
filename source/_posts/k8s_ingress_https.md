---
title: 为ingress发布的服务增加https访问
date: 2023-04-03 17:12:16
categories: K8S运维笔记
---

暂无描述内容

<!--more-->

## 创建secret

```bash
$ kubectl create secret tls 证书名 --key key文件 --cert crt文件 -n 命名空间
```

或使用yaml方式创建

```
apiVersion: v1
kind: Secret
metadata:
  name: 证书名
  namespace: 命名空间
data:
  tls.crt: base64后的crt文件内容 
  tls.key: base64后的key文件内容 
type: kubernetes.io/tls
```

## 查看secret


```bash
$ kubectl describe secret 证书名 -n ops
```

## 配置ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  rules:
  - host: 域名
  ......
  tls:
    - hosts:
        - 域名
      secretName: 证书名
```


