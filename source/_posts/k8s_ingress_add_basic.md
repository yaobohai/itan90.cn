---
title: 为ingress发布的服务增加Basic 认证访问
date: 2023-04-03 17:12:16
categories: K8S运维笔记
---

暂无描述内容

<!--more-->


## 1. 添加秘钥

1、生成秘钥

```
➜  term_workspace htpasswd -nb 'admin' 'xxxxxx' | base64
xxxxxxxxxxxxxxxxxxxxxx
```

登录用户 admin，记录base64加密后的登录密码 xxxxxxxxxxxxxxxxxxxxxx 

在服务所在命名空间，添加凭证

```
➜  term_workspace cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: basic-auth
data:
  auth: "YWRtaW46JGFwcjEkY3lMdld0ak4kYzdyWUg3Ri5mVFl4d01WeE4waFZ1LwoK"
EOF
```

##  2、添加 Ingress 转发规则

```
➜  term_workspace cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: cerebro
  annotations:
    kubernetes.io/ingress.class: "nginx"
    # 增加注解
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
    
    # 如果是traefik
    # kubernetes.io/ingress.class: "traefik"
    # traefik.ingress.kubernetes.io/auth-type: basic
    # traefik.ingress.kubernetes.io/auth-secret: basic-auth
    # traefik.ingress.kubernetes.io/auth-realm: "Authentication Required"
 
spec:
  rules:
  - host: cerebro.bohai.com
    http:
      paths:
      - path: /
        backend:
          service:
            name: cerebro
            port:
              number: 9000
        pathType: ImplementationSpecific
EOF
```


```
nginx.ingress.kubernetes.io/auth-type: basic 
nginx.ingress.kubernetes.io/auth-secret: basic-auth 

指定了认证的方式为 Basic，认证秘钥为 basic-auth 
```

## 3、访问服务

在访问主机上添加 hosts 指向集群主机,域名即为 Ingress 中配置的 hosts，这里是`cerebro.bohai.com`


