---
layout: post
cid: 36
title: Python3中使用Requests模块后请求参数%被编码为25的解决办法
slug: 36
date: 2021/07/07 16:57:48
updated: 2021/07/07 16:57:48
status: publish
author: sunday
categories: 
  - Python
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
---

来看看吧 <!--more--> 

首先，需要载入unquote

    from urllib.parse import unquote

之后在request.get的前方加入

    params['键名'] = unquote(params['键名'])

即可解决