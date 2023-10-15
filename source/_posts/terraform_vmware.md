---
layout: post
title: 通过Terraform快速创建虚拟机
date: 2023/10/12 18:29:00
updated: 2023/10/12 18:29:00
author: 姚
categories:
  - 技术分享
---
  
# Terraform的认识

Terraform 是最流行的基础架构即代码（IaC）工具，用于安全的编排、构建、修改和版本化管理基础设施，其采用声明式进行管理，并会基于代码变化对基础设施进行变更，更有利于对基础设施的自动化配置；得益于Terraform良好的生态，其提供非常完整的适配，例如：

- vSphere..私有云
- AWS/GCP/Azure/Aliyun..公有云
- Kuberentes/Docker
- Gtilab/Github
- MySQL/PostgreSQL/RabbitMQ

![](https://resource.static.tencent.itan90.cn/mac_pic/2023-10-12/PBK5Tb.png)

<!--more-->

# Terraform的开始

## 安装terraform

对于使用MacOS的用户，那么配置好brew之后，通过命令即可安装

```shell
brew install terraform
```

其他用户安装稍微略显复杂，本次不再展开

## 准备Terraform工作目录

其中`terraform`目录存储其他后续资源(如集成docker) `vmware` 目录中存储我们terraform代码文件

```shell
# 创建目录
mkdir -p terraform/vmware
```

## 编写terraform代码

本次将创建三个文件：

```
terraform/vmware/main.tf       · 核心资源清单文件：定义各种所需清单  
terraform/vmware/variables.tf  · 变量清单文件：定义main.tf中所需的变量名(可维护默认值)
terraform/vmware/output.tf     · 信息输出文件：在虚拟机创建完成后输出的相关信息
```

### 编写核心资源清单文件

文件名：`terraform/vmware/main.tf` 

```shell
provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          =  var.portgroup
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.template_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "linux" {
  name              = var.vm_name
  resource_pool_id  = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id      = data.vsphere_datastore.datastore.id

  num_cpus = var.vcpu_count
  memory   = var.memory
  guest_id = data.vsphere_virtual_machine.template.guest_id

  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  # 第二块磁盘配置(当模板有多块儿磁盘时需要启用该配置)
  # disk {
  #   label            = "disk1"
  #   unit_number      = "1"            # 磁盘的单元编号(从0开始,每块儿编号不能重复)
  #   size             = data.vsphere_virtual_machine.template.disks.1.size
  # }

  # 第三块磁盘配置(当模板有多块儿磁盘时需要启用该配置)
  # disk {
  #   label            = "disk2"
  #   unit_number      = "2"            # 磁盘的单元编号(从0开始,每块儿编号不能重复)
  #   size             = data.vsphere_virtual_machine.template.disks.2.size
  # }
  
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    linked_clone = "true"

    customize {
      linux_options {
        host_name = var.vm_name
        domain    = var.domain_name
      }

      network_interface {
        ipv4_address = var.vm_ip
        ipv4_netmask = var.vm_cidr
      }

      ipv4_gateway = var.default_gw
      dns_server_list = [var.dns_list]
    }
  }
}
```

### 编写变量清单文件

文件名：`terraform/vmware/variables.tf`

```shell
# VCenter集群配置
variable "vsphere_server" {
  description = "配置vCenter服务地址(只需要IP或域名)"
  default = "192.168.60.1"
}

variable "datacenter" { 
    description = "配置vCenter数据中心名称 (在vSphere Client-->菜单-->主机和集群-->数据中心处查找)"
    default = "上海数据中心"
}

variable "cluster" {  
    description = "配置vCenter集群名称 (在vSphere Client-->菜单-->主机和集群-->主机和群集-->集群处查找)"
    default = "测试集群"
}

variable "vsphere_user" {
  description = "配置vCenter用户"
    default = "administrator@vsphere.local"
}

variable "vsphere_password" {
  description = "配置vCenter密码"
    default = "xxxxxxx"
}

# 虚拟机个性化配置
variable "template_name" { 
    description = "配置虚拟机模板名称"
    default = "Centos7-64-Template-2C-4G-200G"
}

variable "vm_name" { 
    description = "配置虚拟机名称"
    default = "terraform_demo01"
}

variable "memory" { 
    description = "配置虚拟机内存(MB)"
     default = "4096"   
}

variable "vcpu_count" { 
    description = "配置虚拟机CPU个数"
    default = "2"
}

# 虚拟机网络配置
variable "vm_ip" { 
    description = "配置虚拟机IP(为空时则使用DHCP)"
    default = "192.168.60.188"
}

variable "vm_cidr" { 
    description = "配置虚拟机CIDR块"
    default = "24"
}

variable "dns_list" {
    description = "配置虚拟机DNS地址"
    default = "114.114.114.114"
}

variable "domain_name" { 
    description = "配置虚拟机搜索域"
    default = "localdomain"
}

variable "default_gw" { 
    description = "配置虚拟机默认网关地址"
    default = "192.168.60.1"
}

variable "portgroup" { 
    description = "配置虚拟机使用的网络适配器"
    default = "2"
}
```
### 编写信息输出文件

文件名：`terraform/vmware/output.tf`

```terraform
output "DC_ID" {
  description = "id of vSphere Datacenter"
  value       = data.vsphere_datacenter.dc.id
}

output "Linux-VM" {
  description = "VM Names"
  value       = vsphere_virtual_machine.linux.*.name
}

output "Linux-ip" {
  description = "default ip address of the deployed VM"
  value       = vsphere_virtual_machine.linux.*.default_ip_address
}

output "Linux-guest-ip" {
  description = "all the registered ip address of the VM"
  value       = vsphere_virtual_machine.linux.*.guest_ip_addresses
}

output "Linux-uuid" {
  description = "UUID of the VM in vSphere"
  value       = vsphere_virtual_machine.linux.*.uuid
}
```

## 环境初始化

### 修改变量清单配置
当上述文件都创建完成后，就可以定义各个变量的配置；修改 `terraform/vmware/variables.tf` 文件中的每一个default值来完成配置的定义。

### 环境变量方式写入配置(可选)
当然你觉得每次都更改大量的variables.tf配置觉得很麻烦，也可以使用注入系统环境变量的方式来写入配置，在terraform中，变量名以`TF_VAR_`开头，后面可以加自己的变量名，如编写env配置文件 `.envfile`

```ini
TF_VAR_cluster=集群名称
TF_VAR_datacenter=数据中心
TF_VAR_vsphere_server=vsphere地址(仅需IP或者域名)
TF_VAR_vsphere_user=vsphere用户
TF_VAR_vsphere_password=vsphere密码
TF_VAR_datastore=数据磁盘
TF_VAR_vm_name=虚拟机名称
TF_VAR_memory=虚拟机内存(M)
TF_VAR_vcpu_count=虚拟机CPU数
TF_VAR_template_name=模板名称
TF_VAR_vm_ip=虚拟机IP(为空时为DHCP)
TF_VAR_vm_cidr=掩码CIDR
TF_VAR_default_gw=虚拟机默认网关
TF_VAR_dns_list="配置虚拟机DNS地址"
TF_VAR_portgroup=虚拟机使用的网络适配器
TF_VAR_domain_name=虚拟机子域
```

配置完成后可以立马生效配置，**当使用了env这种方式来生效配置，那么则会覆盖掉variables.tf中的default值**

```shell
bohai@bohai vmware % for keys in $(cat .envfile);do export ${keys};done
```
执行后可以使用 `env | grep TF_VAR` 来查看配置是否都以注入当前shell中

```shell
bohai@bohai vmware % env | grep TF_VAR
TF_VAR_cluster=集群名称
TF_VAR_datacenter=数据中心
TF_VAR_vsphere_server=vsphere地址(仅需IP或者域名)
TF_VAR_vsphere_user=vsphere用户
TF_VAR_vsphere_password=vsphere密码
TF_VAR_datastore=数据磁盘
TF_VAR_vm_name=虚拟机名称
TF_VAR_memory=虚拟机内存(M)
TF_VAR_vcpu_count=虚拟机CPU数
TF_VAR_template_name=模板名称
TF_VAR_vm_ip=虚拟机IP(为空时为DHCP)
TF_VAR_vm_cidr=掩码CIDR
TF_VAR_default_gw=虚拟机默认网关
TF_VAR_dns_list="配置虚拟机DNS地址"
TF_VAR_portgroup=虚拟机使用的网络适配器
TF_VAR_domain_name=虚拟机子域
bohai@bohaideMac-mini vmware % 
bohai@bohaideMac-mini vmware % 
```

### 环境初始化

接下来执行 `terraform init`命令，来下载并安装所需环境依赖 (执行一次即可)

## 创建虚拟机

当前面所有的配置都完成后，就可以操作创建虚拟机啦 :) 

```shell
bohai@bohai vmware % cd terraform/vmware/
bohai@bohai vmware % terraform apply
```

如果配置都正确，也已经执行过`terraform init` 那么`apply` 之后则会打印类似我的输出：

![](https://resource.static.tencent.itan90.cn/202310/1697307244518313311.png)

```
Plan: 1 to add, 0 to change, 0 to destroy.
```

打印的大致内容也就是需要复核一下相关清单是否都如配置所写或配置清单是否正确，如我的虚拟机配置清单为：`一台名为terraform-demo的2核4G配置虚拟机IP192.168.60.133` 的机器。

如果都配置ok，那么需要我们输入一下 `yes` 来继续下一步都创建动作

![](https://resource.static.tencent.itan90.cn/202310/169730754689848527.png)

于此同时，vsphere的任务栏也有执行进度的列表

![](https://resource.static.tencent.itan90.cn/202310/1697307628127115385.png)

当看到执行返回`Apply complete! Resources: 1 added, 0 changed, 0 destroyed.`后，则说明任务已经完成。

创建完成后,terraform会按照我们之前定义的信息输出文件 `terraform/vmware/output.tf` 输出一些信息；并且会将虚拟机自动开机

![](https://resource.static.tencent.itan90.cn/202310/1697307722962239757.png)

Linux-VM也就是虚拟机名称,Linux-guest-ip、Linux-ip则是虚拟机的IP,接下来通过Vsphere来查看查看`主机名、内存、CPU`是否按照预期要求来创建

![](https://resource.static.tencent.itan90.cn/202310/1697308155510153456.png)

当然如果模板都做的相对来说比较完美，那么我们直接远程上去查看

![](https://resource.static.tencent.itan90.cn/202310/1697308095540194375.png)

至此，通过Terraform来创建虚拟机的的步骤皆已完成～

## Terraform on docker

某些场景我们可能只需要运行一次性docker容器来完成虚拟机的创建，创建完成相应资源后自动删除该容器；对于这种方式也有相对比较好的解决方法

### 编写Dockerfile

文件名：`terraform/dockerfile`

```dockerfile
FROM hashicorp/terraform:latest

# 将vmware编排内容拷贝至容器目录
COPY vmware /opt/vmware

WORKDIR /opt/vmware
# 直接在容器内完成依赖的获取避免运行时造成额外的时间浪费
RUN terraform init
```

### 构建和运行

接着来构建terraform的docker镜像

```shell
bohai@bohai vmware % cd terraform
bohai@bohai vmware % docker build -t terraform_vmware:latest .
```

构建完成后，准备我们的启动参数，同样通过`TF_VAR_`的方式，注入容器变量来尝试启动容器即可创建虚拟机

```shell
bohai@bohai vmware % docker run -it --rm \
-e TF_VAR_cluster="集群名称" \
-e TF_VAR_datacenter="集群名称" \
-e TF_VAR_vsphere_server="vsphere地址(仅需IP或者域名)" \
-e TF_VAR_vsphere_user="vsphere用户" \
-e TF_VAR_vsphere_password="vsphere密码" \
-e TF_VAR_datastore="数据磁盘" \
-e TF_VAR_vm_name="虚拟机名称" \
-e TF_VAR_memory="虚拟机内存(M)" \
-e TF_VAR_vcpu_count="虚拟机CPU数" \
-e TF_VAR_template_name="模板名称" \
-e TF_VAR_vm_ip="虚拟机IP(为空时为DHCP)" \
-e TF_VAR_vm_cidr=掩码CIDR \
-e TF_VAR_dns_list="DNS_IP" \
-e TF_VAR_default_gw="虚拟机默认网关地址" \
-e TF_VAR_portgroup="虚拟机使用的网络适配器" \
-e TF_VAR_domain_name="虚拟机子域" \
terraform_vmware apply
```

当上述配置全部正确，并执行运行指令后，即可开始创建。

![](https://resource.static.tencent.itan90.cn/202310/1697308774410359498.png)

# 最后

## 帮助链接

- 本次所有相关代码都已上传至Git仓库：https://github.com/yaobohai/terraform_vmware
- terraform在阿里云的最佳实践: https://help.aliyun.com/product/95817.html?spm=a2c4g.95820.0.0.11242aa9498EFO

## 常见问题

1、为什么修改配置后，重新执行是重建原有虚拟机而不是新建

```shell
删除 terraform.tfstate 开头的文件即可
```