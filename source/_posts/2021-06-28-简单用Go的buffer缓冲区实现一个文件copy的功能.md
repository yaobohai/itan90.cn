---
layout: post
cid: 35
title: 简单用Go的buffer缓冲区实现一个文件copy的功能
slug: 35
date: 2021/06/28 20:59:00
updated: 2021/06/28 21:04:36
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
thumb: 
thumbChoice: default
thumbDesc: 
thumbSmall: 
thumbStyle: default
---

来看看吧 <!--more--> 

代码示例：

    package main
    
    import (
    	"bufio"
    	"fmt"
    	"io"
    	"os"
    )
    
    var (
    	/* 源文件路径*/
    	Src_File_Path = "C://Users/Administrator/Downloads/Compressed/111111.zip"
    
    	/* 目标文件路径(不存在则自动创建)*/
    	TarGet_File_Path = "d://test/navicat.zip"
    )
    
    func main()  {
    	src_file,err := os.OpenFile(Src_File_Path, os.O_RDONLY, 0666)
    	if os.IsNotExist(err) {
    		fmt.Printf("file %s not found",Src_File_Path)
    		return
    	}
    	dst_file, err := os.OpenFile(TarGet_File_Path, os.O_WRONLY|os.O_CREATE, 0666)
    
    	defer func() {
    		src_file.Close()
    		dst_file.Close()
    	}()
    
    	reader := bufio.NewReader(src_file)
    	writer := bufio.NewWriter(dst_file)
    
    	// 创建一个小的缓冲区(1MB)
    	buffer := make([]byte, 1048576)
    
    	for  {
    		_, err := reader.Read(buffer)
    		if err != nil {
    			if err == io.EOF {
    				break
    			}else {
    				fmt.Println("copy file failed.msg:",err)
    				return
    			}
    		}else {
    			_, err := writer.Write(buffer)
    			if err != nil {
    				fmt.Println("copy file failed.msg:",err)
    				return
    			}
    		}
    	}
    	writer.Flush()
    }

注意记得修改下默认的`Src_File_Path`源文件路径和`TarGet_File_Path`目标文件路径。即可完成复制操作(默认缓冲区大小：1M)