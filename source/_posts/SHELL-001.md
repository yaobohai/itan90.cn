---
layout: post
cid: 14
title: SHELL脚本并发
slug: 14
date: 2021/04/20 14:31:00
updated: 2021/04/20 16:09:20
status: publish
author: sunday
tags: 
customSummary: 
mathjax: auto
noThumbInfoStyle: default
outdatedNotice: no
reprint: forbidden
thumb: https://cdn.jsdelivr.net/gh/ihewro/blog@master/usr/uploads/2018/11/2975346373.jpg
thumbChoice: default
thumbDesc: 
thumbSmall: https://cdn.jsdelivr.net/gh/ihewro/blog@master/usr/uploads/2018/11/2975346373.jpg
thumbStyle: default
categories:
  - 运维笔记
---

在很多实践中，我们使用脚本通常情况下只能同时运行一个任务，但我们的需求往往不可能等脚本任务一个一个完成，这样既浪费时间又造成有脚本取值运行超时的风险。

shell实现起来并发和其他编程语言类似，比如Go...等等，下面我用具体的代码来实现效果：
<!--more-->

    
    num_list='1 2 3 4 5 6 7 8 9 10'

    function connect(){
            # sleep 实际环境中不需要;这里为了模拟
           echo $1;sleep 60
    }

    for i in $num_list;do
            # 任务放入后台继续执行;不影响其他任务
            connect $i &
    done

    sleep 1


上述代码我定义了数字列表分别是数字1-10，基本思路是，我们实现一个函数，函数里面就是要做的动作，通过for循环获取任务数量返回给函数作为入参参数并放入后台run起任务。

这时，代码要做的就是同时将数字打印出来,而不是依次，类似于运行效果等于10个任务同时运行。我们来执行模拟看下结果：

    sh demo.sh &>/dev/null & 
    ps -ef|grep -v grep|grep demo.sh

![模拟][1]


  [1]: https://oss.itan90.cn/out_pic/2022-07-20/B35a79.jpg

可以注意到，我们执行脚本并放到后台后，通过ps -ef查看脚本进程，脚本进程返回10个任务。

当然，与其他编程语言一致，你也可以定义一个数字范围，来限制并发数量等等。