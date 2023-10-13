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

其中、terraform存储其他资源，vmware中存储我们本次要使用的相关代码。

```shell
mkdir -p terraform/vmware
```

## 编写terraform代码

本次将创建三个文件：

- terraform/vmware/main.tf       资源入口文件：定义各种所需清单
- terraform/vmware/variables.tf  变量清单文件：定义main.tf中所需的变量名(可维护默认值)
- terraform/vmware/output.tf     信息输出文件：在虚拟机创建完成后输出的相关信息

编写terraform/vmware/main.tf

```terraform
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

  # 当模板有多块儿磁盘时需要启用该配置
  # disk {
  #   label            = "disk1"
  #   unit_number      = "1"            # 磁盘的单元编号(从0开始,每块儿编号不能重复)
  #   size             = data.vsphere_virtual_machine.template.disks.1.size
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

编写 terraform/vmware/variables.tf

```terraform
variable "vsphere_server" {}

variable "adminpassword" {}

variable "vsphere_user" {}

variable "vsphere_password" {}

variable "datacenter" {}

variable "datastore" {}

variable "cluster" {}

variable "portgroup" {}

variable "domain_name" {}

variable "default_gw" {}

variable "dns_list" { 
    default = ["114.114.114.114"]
}

variable "template_name" {}

variable "vm_name" {}

variable "vm_ip" {}

variable "vm_cidr" {}

variable "vcpu_count" {}

variable "memory" {}
```

编写 terraform/vmware/output.tf 信息输出文件

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

## 进行配置书写

- todo

## 创建虚拟机

- todo

## Terraform on docker

某些场景我们可能只需要运行一次性docker容器来完成虚拟机的创建，创建完成相应资源后自动删除该容器；对于这种方式也有相对比较好的解决方法

### 书写dockerfile

进入terraform目录准备我们的相关资源 `cd terraform`

```
vim dockerfile
```

```dockerfile
FROM hashicorp/terraform:latest

# 将vmware编排内容拷贝至容器目录
COPY vmware /opt/vmware

WORKDIR /opt/vmware
# 进行初始化操作以便后续直接使用
RUN terraform init
```

### 构建和运行

接着来构建terraform的docker镜像

```shell
docker build -t terraform_vmware:latest .
```

构建完成后，准备我们的启动参数，修改下列参数尝试启动容器创建虚拟机

```shell
docker run -it --rm \
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
-e TF_VAR_adminpassword="虚拟机密码(如果允许修改)" \
-e TF_VAR_vm_ip="虚拟机IP(为空时为DHCP)" \
-e TF_VAR_vm_cidr=掩码CIDR \
-e TF_VAR_dns_list="DNS_IP" \
-e TF_VAR_default_gw="虚拟机默认网关地址" \
-e TF_VAR_portgroup="虚拟机使用的网络适配器" \
-e TF_VAR_domain_name="虚拟机子域" \
terraform_vmware apply --auto-approve
```

当上述配置全部正确，并执行运行指令后，即可开始创建。


# 最后

本次所有相关代码都已上传至Git仓库：https://github.com/yaobohai/terraform_vmware
