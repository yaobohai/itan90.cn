---
layout: post
cid: 4
title: [Golang]Go的数组&amp;切片&amp;map
slug: 4
date: 2021/03/06 00:50:00
updated: 2021/03/08 14:58:45
status: publish
author: sunday
categories: 
  - GOLANG
tags: 
customSummary: 
mathjax: auto
noThumbInfoStyle: default
outdatedNotice: no
reprint: standard
thumb: https://api.yimian.xyz/img?type=moe
thumbChoice: default
thumbDesc: 
thumbSmall: https://api.yimian.xyz/img?type=moe
thumbStyle: default
---

没用的Golang学习笔记 <!--more-->

```Go
    package main
    
    import "fmt"
    
    // 数组
    //func main()  {
    //	// 数组长度
    //	array:=[6]string{"a","b","c","d","e","f"}
    //	// 打印数组具体值
    //	//fmt.Println(array[1:4])
    //	// 循环打印数组中的key:value
    //	for i,v:=range array{
    //		// i+1 重新对i进行赋值，表示列表从1开始
    //		i=i+1
    //		fmt.Println("key:",i,"value:",v)
    //	}
    //
    //}
    
    //// 切片
    //func main() {
    //	// 数组长度
    //	//array := [6]string{"a", "b", "c", "d", "e", "f"}
    //
    //	// 切片名:=数组名称[start值:end值]
    //	//num_list:=array[2:6]
    //	// 省略start值
    //	// num_list:=array[:6] // 等价于array[0:6]
    //	// 省略end值
    //	// num_list:=array[1:] // 等价于array[1:6]
    //	// 省略start:end值
    //	// num_list:=array[:]  // 等价于array[0:6]
    //	// fmt.Println(num_list)
    //
    //	// 切片数据修改;可以理解为重新赋值后
    //	//array[0]="zz/"
    //	//array[1]="dd/"
    //	//fmt.Println(array)
    //
    //	//// 循环打印切片数据
    //	//for i, v := range array {
    //	//	fmt.Println("key:",i,"value:",v)
    //	//}
    //
    //
    //	// append 切片添加数据
    //	/// 源数据
    //	array:=[]string{"a", "b", "c", "d", "e", "f"}
    //	/// 在切片中添加新数据
    //	new_array:=append(array,"g","h","i","j","k","m")
    //	for i,v:=range new_array{
    //		fmt.Println("ID:",i,"VALUE:",v)
    //	}
    //
    //	// 切片和数组的比较：切片占用内存更小处理更快实际开发环境切片用的也更多
    //}
    
    // 字段映射(Map)
    func main()  {
    	nameAgeMap:=make(map[string]int)
    	nameAgeMap["博海年龄"]=20
    	nameAgeMap["博哥年龄"]=21
    	nameAgeMap["海哥年龄"]=22
    	for i,v:=range nameAgeMap{
    		fmt.Println("value:",i,"key",v)
    	}
    
    	fmt.Println(len(nameAgeMap))
    }

```
