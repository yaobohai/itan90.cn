---
layout: post
title: 体验通过colab以及ChilloutMix&Lora零成本生成AI照片
date: 2023/02/26 22:50:00
categories: AI技术
---

得益于Google的colab可以为我们免费提供13GiB的内存以及15GiB GPU、80GiB硬盘的运算算力，因此，可以借助该资源来体验stable-diffusion项目

话不多耍，先来看下最终效果

![使用 Stable Diffusion 生成的照片](https://resource.static.tencent.itan90.cn/mac_pic/2023-02-26/WjDPGO.jpg)

<!--more-->

准备材料：

- 谷歌账号&网络出国条件
- 运算资源 https://colab.research.google.com/ 
- 存放模型的硬盘 https://drive.google.com/ 
- 模型&关键词 https://civitai.com/


## 下载 LORA 模型到本地

```
打开链接下载模型，也可以打开 civitai.com 下载其他模型
https://civitai.com/models/7448/korean-doll-likeness
https://civitai.com/models/7716/taiwan-doll-likeness
https://civitai.com/models/10135/japanese-doll-likeness
```


![点箭头位置](https://resource.static.tencent.itan90.cn/mac_pic/2023-02-26/PKHuAX.jpg)

## 将模型上传到 Google 云端硬盘

```
1、在浏览器打开链接：https://drive.google.com/
2、新建一个 " model " 的目录,用来存储模型
```

![新建模型目录](https://resource.static.tencent.itan90.cn/mac_pic/2023-02-26/vUuw7A.png)


![将下载的模型上传](https://resource.static.tencent.itan90.cn/mac_pic/2023-02-26/igfEIX.jpg)

## 在 Colab 运行

```
在浏览器打开链接：

https://colab.research.google.com/drive/1FFGO7zyrZwp0yePWdK1cH_s-75wx6JOF?usp=share_link
```

### 初始化

打开后，点击 “连接” 或 “连接到托管的运行时”

![连接](https://resource.static.tencent.itan90.cn/mac_pic/2023-02-26/5saVpI.png)

当出现 2 时的绿色打勾以及可观察到资源使用时表示已经连接到可分配到计算资源

![初始化](https://resource.static.tencent.itan90.cn/mac_pic/2023-02-26/s0EXBi.png)

稍等片刻，初始化操作略慢，初始化整个资源库8、9G大小这样，当底部出现 “Runing” 的时候 再次点击运行的图标，停止运行。

![停止运行](https://resource.static.tencent.itan90.cn/mac_pic/2023-02-26/e1xldA.png)

### 挂载云盘

![](https://resource.static.tencent.itan90.cn/mac_pic/2023-02-26/gZChT3.png)

### 复制模型

挂载云盘完成后，就可以把 当时上传到 “model” 目录下的模型文件复制到工作目录了，如果在第 2 步骤中，新建的目录名不叫 model ，那自行修改下即可

![](https://resource.static.tencent.itan90.cn/mac_pic/2023-02-26/abOunF.png)

### 运行stable-diffusion

点击运行运行旁边的启动按钮，则可在colab运算资源中运行stable-diffusion运算项目，当出现 `Running on public URL` 则说明项目启动完毕，接着点击该链接，会跳转到一个新的页面：“stable-diffusion-webui” 此时colab的页面我们不用去管他 (也不要关闭)。

![](https://resource.static.tencent.itan90.cn/mac_pic/2023-02-26/urkl4u.png)


## 制作图形

### 导入模型

点橙色按钮 `Generate` 下面的第三个按钮，接着来到Lora层级，选择三个任意一个模型。

![](https://resource.static.tencent.itan90.cn/mac_pic/2023-02-26/71CRHo.jpg)

### 配置参数

在 4.1 选择好模型后，会自动在上方第一个大框中填上模型的前缀，然后我们在后面加上一些我们想要的参数

![](https://resource.static.tencent.itan90.cn/mac_pic/2023-02-26/POdms6.png)

第一个框中输入的参数：

```
// 注意事项：选一个模型之后，会自动在第一个输入框填充前缀，不要删除
// 参数大孩子可以解释为：需要一个很可爱戴眼镜的JK妹子 

(8k, best quality, masterpiece:1.2), (realistic, photo-realistic:1.37), ultra-detailed,1 girl in JK uniform,cute,wear glasses,solo,stand,dating,(nose blush),(smile:1.15),(grin) big breasts,Long legged
```

第二个框的参数：

```
paintings, sketches, (worst quality:2), (low quality:2), (normal quality:2), lowres, normal quality, ((monochrome)), ((grayscale)), skin spots, acnes, skin blemishes, age spot, (outdoor:1.6), manboobs, backlight,(ugly:1.331), (duplicate:1.331), (morbid:1.21), (mutilated:1.21), (tranny:1.331), mutated hands, (poorly drawn hands:1.331), blurry, (bad anatomy:1.21), (bad proportions:1.331), extra limbs, (disfigured:1.331), (more than 2 nipples:1.331), (missing arms:1.331), (extra legs:1.331), (fused fingers:1.61051), (too many fingers:1.61051), (unclear eyes:1.331), bad hands, missing fingers, extra digit, (futa:1.1), bad body, NG_DeepNegative_V1_75T,pubic hair, glans
```

接着来到下方，继续调整图片中红色标注的地方参数

![](https://resource.static.tencent.itan90.cn/mac_pic/2023-02-26/bIg478.jpg)

### 生成图片

参数调整好之后，点击上方橙色图标 `Generate` 即可根据导入的模型以及参数来生成人像图片：

![](https://resource.static.tencent.itan90.cn/mac_pic/2023-02-26/QEAieS.png)

下拉底部可以看到进度，生成一张图片大概需要3-5分钟左右，过程如下：

![](https://resource.static.tencent.itan90.cn/mac_pic/2023-02-26/d5r9mQ.png)

需要注意的是，如果需要同时生成多张图片，修改下 `Batch size` 的值即可，但需要注意的是，不要生成太多，免费的运算资源GPU不够用，生成图片要消耗的时间就更长。

## 最后

```
1、更多关键词可以在 https://civitai.com/ 查看获取
2、每张图片右侧都有生成的参数、词汇等信息
3、每个参数的相关含义可以查看本文尾部的参考资料
```