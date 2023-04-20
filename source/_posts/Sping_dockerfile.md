---
layout: post
title: Java学习笔记-Sping自动构建docker镜像
date: 2023/04/14 22:50:00
categories: Java
---

在构建时一同构建docker镜像及推送

![](https://resource.static.tencent.itan90.cn/mac_pic/2023-04-20/8OqUrP.jpg)


# 定义Pom

<!--more-->

在pom的description节点中引入properties定义推送的镜像仓库

```xml
    <properties>
        <java.version>1.8</java.version>
        <docker.repostory>registry.cn-hangzhou.aliyuncs.com/bohai_repo</docker.repostory>
    </properties>
```

build节点中引入插件：dockerfile-maven-plugin

```shell
            <plugin>
                <groupId>com.spotify</groupId>
                <artifactId>dockerfile-maven-plugin</artifactId>
                <version>1.4.10</version>
                <executions>
                    <execution>
                        <id>default</id>
                        <goals>
                            <goal>build</goal>
                            <goal>push</goal>
                        </goals>
                    </execution>
                </executions>
                <configuration>
                    <repository>${docker.repostory}/${project.artifactId}</repository>
                    <!--  镜像tag取用project.version -->
                    <tag>${project.version}</tag>
                    <buildArgs>
                        <!--  在target目录中查找project.build.finalName节点下的jar包 -->
                        <JAR_FILE>target/${project.build.finalName}.jar</JAR_FILE>
                    </buildArgs>
                </configuration>
            </plugin>
```

新建一个dockerfile

```dockerfile
FROM openjdk:8u191-jre-alpine3.9
ENTRYPOINT ["/usr/bin/java", "-jar", "/app.jar"]
# 在pom中定义的 标签
ARG JAR_FILE
ADD ${JAR_FILE} /app.jar
EXPOSE 8080
```

# 构建

```shell
# 只构建
$ mvn install dockerfile:build

# 构建+ 推送
$ mvn install dockerfile:push

[INFO] --- dockerfile:1.4.10:push (default-cli) @ demo ---
[INFO] The push refers to repository [registry.cn-hangzhou.aliyuncs.com/bohai_repo/demo]
[INFO] Image 72a6d2e10f94: Preparing
[INFO] Image 4222fe8d2ce7: Preparing
[INFO] Image 9afc0e59c268: Preparing
[INFO] Image b83703e07573: Preparing
[INFO] Image 4222fe8d2ce7: Layer already exists
[INFO] Image 9afc0e59c268: Layer already exists
[INFO] Image b83703e07573: Layer already exists
[INFO] Image 72a6d2e10f94: Pushing
[INFO] Image 72a6d2e10f94: Pushed
[INFO] 1.1.0-SNAPSHOT: digest: sha256:091d1dba02edc1754040c34d716001c5c4f30e5059fe387df6572cc1722117d1 size: 1159
```

## 在M1芯片中构建

```shell
$ brew install socat
$ nohup socat TCP-LISTEN:2375,range=127.0.0.1/32,reuseaddr,fork UNIX-CLIENT:/var/run/docker.sock &> /dev/null &
$ export DOCKER_HOST=tcp://127.0.0.1:2375
```



