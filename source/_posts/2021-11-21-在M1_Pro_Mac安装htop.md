---
layout: post
cid: 64
title: 在M1 Pro Mac安装htop
slug: zaim1-pro-mac-an-zhuanghtop
date: 2021/11/21 10:30:00
updated: 2022/03/20 23:04:17
status: publish
author: sunday
categories: 
  - 默认分类
  - MacOS
  - 技巧分享
tags: 
  - 博客文档
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
---

来看看吧 <!--more-->

<p>目前通过brew已经无法直接安装。不过我们可以找源码进行本地编译安装。</p>
<pre class="line-numbers"><code class="language-plain_text">$ wget https://hisham.hm/htop/releases/2.2.0/htop-2.2.0.tar.gz
$ tar -zxvf htop-2.2.0.tar.gz
$ cd htop-2.2.0/
$ ./configure
$ make
$ sudo make install
</code></pre>
<p>安装完成后，执行<code>htop</code>命令查看效果</p>