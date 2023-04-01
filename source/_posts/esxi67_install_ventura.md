---
layout: post
title: ESXI 6.7.0安装MacOS Ventura
date: 2023/04/1 16:00:00
categories: 关于MAC 虚拟化
---

在ESXI安装MacOS步骤略微繁琐，再次记录下安装步骤。

## 镜像准备

### 下载镜像

如果你使用的是MacOS。则可在Mac的应用商店中搜索 `MacOS Ventura` 或 [点击此处](https://apps.apple.com/cn/app/macos-ventura/id1638787999?mt=12) 跳转下载。

系统大小在12GB,需提前准备下载该镜像，下载完成后，如果系统自动打开了安装程序，则切不可点下一步，需要按 `Command + Q` 退出。

### 制作镜像

下载完成接下来，我们使用的一系列操作均需要root权限。我们打开 shell终端，并输入 `sudo -i` 来切换至root用户。

```shell
sudo -i
```

接着在/tmp文件夹下创建一个dmg格式的镜像文件，该文件的大小为14GB。

```shell
hdiutil create -o /tmp/ventura -size 14000.1m -volname ventura -layout SPUD -fs HFS+J
```

挂载该镜像

```shell
hdiutil attach /tmp/ventura.dmg -noverify -mountpoint /Volumes/ventura
```

将此镜像设置为可启动macos的启动介质

```shell
sudo /Applications/Install\ macOS\ Ventura.app/Contents/Resources/createinstallmedia --volume /Volumes/ventura --nointeraction
```

这一步需要一定的时间，在过程中会显示进度信息，完成后将在/Volumes中生成Install ventura。接着弹出它：

```shell
hdiutil eject -force /volumes/Install\ macOS\ Ventura
```

此时dmg文件写入完成。下一步将其转换为cdr文件。cdr文件即是macOS系统上的iso文件。注意：需将`<you name>`替换为你的MacOS的用户名

```shell
hdiutil convert /tmp/ventura.dmg -format UDTO -o /Users/<you name>/Downloads/ventura.cdr
```

接下来还需将cdr重命名为esxi所需的iso

```shell
mv /Users/<you name>/Downloads/ventura.cdr /Users/<you name>/Downloads/ventura.iso
```
同样还是注意把`<you name>`换成你的用户名

上述步骤都完成后，可以清理下临时的镜像文件

```shell
rm -rf /tmp/ventura.dmg
```

### 上传镜像

有了ISO文件后，我们接下来将其上传到ESXi的数据存储上。

1. 登录ESXi 主机
2. 选择左侧的存储后，选择一个预上传文件的存储。
3. 点击右侧的Datastroe brower(数据浏览)
4. 选择一个预上传的文件夹
5. 点击上传
6. 上传过程需要一定的时候，可以在下侧的最近任务状态中查看上传结果。

趁着再上传的过程中我们还需执行解锁esxi，具体步骤如下

## 解锁ESXI

安装unlocker的作用，是防止在vmware上安装macos时出现的死循环。但安装此工具 **需重启ESXI服务器，请确保可以操作**

[点击下载 esxi-unlocker](https://github.com/shanyungyang/esxi-unlocker/archive/refs/heads/master.zip)

大家可以试下不安装会怎么样 我没试过:)

本地下载后，还需上传只esxi中，与上传iso文件的方法相同，将master.zip上传至vmware的存储上。之后：

1. 登录ESXi 主机
2. 选择左侧的管理，并点击 `服务` 选项卡
3. 选中 `TSM` 右键启动
4. 选中 `TSM-SSH` 右键启动
5. 打开终端 `ssh ESXI主机IP`

SSH连接上ESXI后，通过 `df -h` 查看具体存储的文件系统挂载位置，通过 `cd 进入改存储`

进入后，解压并执行解锁命令:

```shell
unzip master.zip
cd esxi-unlocker-master
tar zcf unlocker.tgz etc
chmod +x esxi-install.sh
./esxi-install.sh
```

执行后，正常返回：

```shell
VMware Unlocker 3.0.2
===============================
Copyright: Dave Parsons 2011-18
Installing unlocker.tgz
Acquiring lock /tmp/bootbank.lck
Copying unlocker.tgz to /bootbank/unlocker.tgz
Editing /bootbank/boot.cfg to add module unlocker.tgz
Success - please now restart the server!
```

根据上述提示信息，还需重启下ESXI服务器，在终端下执行

```shell
reboot
```

## 安装MacOS

此步骤就于普通创建虚拟机步骤一致了，步骤过于繁多，再次就不记录了 :)