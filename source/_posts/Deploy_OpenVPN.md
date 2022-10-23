---
layout: post
cid: 93
title: CentOS7部署OpenVPN服务
slug: 93
date: 2022/03/09 00:25:00
updated: 2022/05/10 01:18:22
status: publish
author: sunday
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
categories:
  - 运维笔记
---

最近需要部署openvpn服务来实现电脑与另外一个服务器环境内网互通，在网上找到的多数的OpenVPN例子都是基于客户端密钥认证的，多个客户那就要多个密钥，这样配置服务端或者客户端都非常麻烦。

本次文章主要实现功能: 

- 容易安装
- 容易配置
- 多个账号
- 客户端仅需导入一个配置 
- Prometheus监控 <!--more-->

这里建议是使用TCP部署服务

## 环境准备

### 使用主机
|  IP        |  系统                   | 端口       | 作用       | 
| ---------- | ---------------------------- | ---------- |---------- |
|    106.212.66.32        | CentOS Linux release 7.9.2009 (Core)  | 5001/tcp |OpenVPN 服务器 |
|    192.168.50.1        | ------  | ----- | 内网测试服务器 |

### 网络分配

|  IP        |  作用       | 
| ---------- | ---------- |
| 10.80.0.0/24  |    OpenVPN网段    | 
| 192.168.50.0/24  |    内网通讯网段    | 


### 软件资源

|  软件名称       |  版本      |
| ---------- | ---------- |
| easy-rsa   |    3.0.8    | 
| openvpn   |    2.4.11    |     

## 安装环境


本文使用yum来安装openvpn，openvpn及其依赖的一些包在epel源上，首先先安装epel源。

```shell
# 安装epel源
yum install -y epel-release
# 安装依赖包
yum install -y openssl lzo pam openssl-devel lzo-devel pam-devel net-tools*
yum install -y easy-rsa
# 安装openvpn
yum install -y openvpn
```

## 配置环境

上面我们已经安装好了openvpn了，下面我们对openvpn进行配置。

### 配置证书密钥

我们通过yum方式安装的 easy-rsa 版本是3.0.8，直接从安装路径copy一份工具出来。这里用默认的 easy-rsa 3.0.8 来配置生成证书密钥。

```
# 复制easy-rsa工具
cp -rf /usr/share/easy-rsa/3.0.8 /etc/openvpn/server/easy-rsa
cd /etc/openvpn/server/easy-rsa
# 生成证书密钥
./easyrsa init-pki
./easyrsa build-ca nopass
./easyrsa build-server-full server nopass
# 下面这步可能要几分钟
./easyrsa gen-dh
openvpn --genkey --secret ta.key
```

### 配置服务端

#### 创建使用的目录并授权

```
# 日志存放目录
mkdir -p /var/log/openvpn/
# 用户管理目录
mkdir -p /etc/openvpn/server/user
# 配置权限
chown -R openvpn:openvpn /var/log/openvpn
```

#### 配置服务端配置文件

新建 `/etc/openvpn/server/server.conf`文件，并写入以下内容:

```
local 0.0.0.0
# VPN服务端端口
port 5001
# VPN服务端协议
proto tcp

dev tun
ca /etc/openvpn/server/easy-rsa/pki/ca.crt
cert /etc/openvpn/server/easy-rsa/pki/issued/server.crt
key /etc/openvpn/server/easy-rsa/pki/private/server.key
dh /etc/openvpn/server/easy-rsa/pki/dh.pem
tls-auth /etc/openvpn/server/easy-rsa/ta.key 0

auth-user-pass-verify /etc/openvpn/server/user/checkpsw.sh via-env

# 把openvpn的状态写入日志中,单位秒
status  /var/log/openvpn/status.log 3
# 配合status，记录客户端字段：虚拟地址，虚拟IPv6地址，用户名，客户端ID，对等ID
status-version 3

script-security 3
verify-client-cert none
username-as-common-name

# VPN客户端自动分配的DHCP地址池
server 10.80.0.0 255.255.255.0
# 需要通讯的内网网段（如果需要VPN客户端与客户端组成一个私网,也可加入10.80.0.0网段）
push "route 192.168.50.0 255.255.255.0"

compress lzo
client-to-client
duplicate-cn
keepalive 10 120
cipher AES-256-CBC
comp-lzo
persist-key
persist-tun
verb 3

client-cert-not-required

# 日志配置路径
log /var/log/openvpn/server.log
log-append /var/log/openvpn/server.log
status /var/log/openvpn/status.log
```

也可以复制一份模板文件进行改写，模板文件路径 `/usr/share/doc/openvpn-2.4.11/sample/sample-config-files/server.conf`

#### 创建用户密码文件

格式是`用户 密码`以空格分割即可

```
echo 'demo demo123.' >> /etc/openvpn/server/user/psw-file
chmod 600 /etc/openvpn/server/user/psw-file
chown -R openvpn:openvpn /etc/openvpn/server/user/psw-file
```

#### 创建密码检查脚本

新建一个shell文件`/etc/openvpn/server/user/checkpsw.sh`；用作核对登录用户密码、用户是否正确等；内容如下：

```
#!/bin/sh

PASSFILE="/etc/openvpn/server/user/psw-file"
LOG_FILE="/var/log/openvpn/password.log"
TIME_STAMP=`date "+%Y-%m-%d %T"`

if [ ! -r "${PASSFILE}" ]; then
  echo "${TIME_STAMP}: Could not open password file \"${PASSFILE}\" for reading." >>  ${LOG_FILE}
  exit 1
fi
CORRECT_PASSWORD=`awk '!/^;/&&!/^#/&&$1=="'${username}'"{print $2;exit}' ${PASSFILE}`
if [ "${CORRECT_PASSWORD}" = "" ]; then
  echo "${TIME_STAMP}: User does not exist: username=\"${username}\", password=
\"${password}\"." >> ${LOG_FILE}
  exit 1
fi
if [ "${password}" = "${CORRECT_PASSWORD}" ]; then
  echo "${TIME_STAMP}: Successful authentication: username=\"${username}\"." >> ${LOG_FILE}
  exit 0
fi
echo "${TIME_STAMP}: Incorrect password: username=\"${username}\", password=
\"${password}\"." >> ${LOG_FILE}
exit 1
```

赋予可执行的权限

```
chmod 700 /etc/openvpn/server/user/checkpsw.sh
chown openvpn:openvpn /etc/openvpn/server/user/checkpsw.sh
```

#### 路由配置

1). 防火墙配置

需要配置一条NAT的规则;这里有两种方式: iptables或者firewalld、任选其一


```
# iptables
iptables -t nat -A POSTROUTING -s 10.80.0.0/24 -o eth0 -j MASQUERADE

```

```
# firewalld
firewall-cmd --permanent --add-masquerade
firewall-cmd --permanent --add-service=openvpn

# 或者添加自定义端口
firewall-cmd --permanent  --add-port=5001/tcp
firewall-cmd --permanent --direct --passthrough ipv4 -t nat -A POSTROUTING -s 10.80.0.0/24 -o eth0 -j MASQUERADE
firewall-cmd --reload

```

2). 开启路由转发

```
echo "net.ipv4.ip_forward = 1" >>/etc/sysctl.conf
sysctl -p
```

#### 启动服务端

```
nohup openvpn /etc/openvpn/server/server.conf >/dev/null 2>&1 &
```

验证是否启动成功

```
netstat -anpt|grep -w 'openvpn'|if [[ $(wc -l) != 0 ]];then echo "openvpn启动成功";else echo "openvpn启动失败";fi

# 启动成功后；也会自动为服务器新增一张通讯网卡`tun0`
ifconfig tun0
```

#### 配置客户端

客户端直接下载安装最新版安装包即可: [点我跳转(需富强)](https://links.jianshu.com/go?to=https%3A%2F%2Fwww.techspot.com%2Fdownloads%2F5182-openvpn.html)

因为我们前面配置的是账号密码认证又是集成客户端配置到一个ovpn文件内，所以我们只需要从server端将生成的`ca.crt、ta.key`提取出来并嵌入到ovpn文件内即可。步骤如下:

1). 查看`ca.crt`文件内容并记录

```
cat /etc/openvpn/server/easy-rsa/pki/ca.crt
```

2). 查看`ta.key`文件内容并记录

```
cat /etc/openvpn/server/easy-rsa/ta.key
```

在`/etc/openvpn/client`目录下新建一个文件 client.ovpn，文件内容如下：

```
client
dev tun
verb 3
mute 10
proto tcp
auth-nocache
persist-tun
persist-key
compress lzo
key-direction 1

# 客户端通过用户名和密码认证
auth-user-pass
cipher AES-256-CBC

# 配置VPN服务器地址及端口
remote 106.212.66.32 5001
remote-cert-tls server

<ca>
查看ca.crt文件的内容粘贴到此处
</ca>
<tls-auth>
查看ta.key文件的内容粘贴到此处
</tls-auth>

```

## 使用

一切准备就绪后，将编写的`client.ovpn`客户端文件下发至客户端内，启动openvpn的客户端，导入客户端文件；然后输入账号密码即可登录。

默认部署用户: demo
默认部署密码: demo123.



![](https://oss.itan90.cn/2022/03/09/16467594940447.jpg)



![](https://oss.itan90.cn/2022/03/09/16467595253024.jpg)

登陆成功后；我们可测试Ping一下之前配置可通讯的网段是否可正常连接.

![](https://oss.itan90.cn/2022/03/09/16467595699012.jpg)


## 监控

这里使用Prometheus [openvpn_exporter](https://github.com/kumina/openvpn_exporter/) 的方式来进行监控；因为前面我们已经在vpn的配置文件中写入了状态文件，所以openvpn服务端启动后，我们就可以直接进行监控。

以docker的方式在openvpn服务端启动的exrporter为例：

```shell
docker run -itd -p 9176:9176 --name openvpn_exporter \
  -v /var/log/openvpn/status.log:/etc/openvpn_exporter/server.status \
  -v /etc/localtime:/etc/localtime \
  kumina/openvpn-exporter -openvpn.status_paths /etc/openvpn_exporter/server.status
```

启动后，访问 `http://127.0.0.1:9176/metrics` 的方式进行请求测试，若无问题，则返回一下示例：

```shell
[root@localhost ~]# curl 127.0.0.1:9176/metrics
# HELP go_gc_duration_seconds A summary of the GC invocation durations.
# TYPE go_gc_duration_seconds summary
go_gc_duration_seconds{quantile="0"} 8.9293e-05
go_gc_duration_seconds{quantile="0.25"} 0.000138057
go_gc_duration_seconds{quantile="0.5"} 0.000184327
......
```

接着在Prometheus的配置文件prometheus.yml中配置exporter的JOB

```shell
  - job_name: openvpn-metrics
    static_configs:
      - targets: ['IP:9176']
```

Prometheus配置重载后，即可。接着在普罗米修斯中查询语句，也可正常返回数据

![](https://resource.static.tencent.itan90.cn/mac_pic/2022-09-23/8c2a-4d40-b688-9b70bcedda9e.png)

关于Grafana面板，则使用ID为 [10562](https://grafana.com/grafana/dashboards/10562-openvpn-server/) 的即可,最终效果如下：

![](https://resource.static.tencent.itan90.cn/mac_pic/2022-09-23/46EFBF0A-A71F-454A-AE0E-BADA9E30BE5F.png)

## 运维


一、客户端连接是不是只需要给一个配置文件和一个账户信息就行?

```
是
```

二、如何查看服务端日志?

```
tailf /var/log/openvpn/server.log
```

三、如何查看用户登陆信息?

```
tailf /var/log/openvpn/password.log
```

四、如何为VPN新增/删除连接用户?

```
# 格式是用户 密码以空格分割即可
vim /etc/openvpn/server/user/psw-file
```
