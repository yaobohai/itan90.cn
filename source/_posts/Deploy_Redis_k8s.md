---
title: Kubernetes部署Redis集群最佳实践
date: 2022-07-12 16:51:16
categories: 运维笔记
---

Redis的部署历程从单机部署、主从模式、哨兵模式、集群路径进行演变，如果你还不了解这四种模式以及优缺点的话，这篇文章会很适合你进行阅读认识。[《一文读懂Redis的四种模式，单机、主从、哨兵、集群》][1] <!--more-->

## 介绍

> 什么是Redis集群

对于高可用的部署，或者说在Kubernetes里进行部署，假如说现有的业务以已经使用了redis里多个db，那么Redis集群只有db0可以使用，这样使用起来代码变更代价也是很高的，所以要根据现有的业务模式进行合理选择。

关于Redis Cluster，先来看看它的架构

![集群架构][2]

**Redis Cluster 数据分片**

Redis Cluster 不使用一致散列，而是一种不同形式的分片，其中每个键在概念上都是我们所谓的散列槽的一部分。

Redis 集群中有 16384 个哈希槽，要计算给定键的哈希槽是多少，我们只需取密钥的 CRC16 模数 16384。

Redis 集群中的每个节点都负责哈希槽的一个子集，例如，您可能有一个包含 3 个节点的集群，其中：

- 节点 A 包含从 0 到 5500 的哈希槽
- 节点 B 包含从 5501 到 11000 的哈希槽
- 节点 C 包含从 11001 到 16383 的哈希槽

这允许在集群中轻松添加和删除节点。例如，如果我想添加一个新节点 D，我需要将一些哈希槽从节点 A、B、C 移动到 D。同样，如果我想从集群中删除节点 A，我可以移动 A 提供的哈希槽到 B 和 C。当节点 A 为空时，我可以将其从集群中完全删除。

由于将哈希槽从一个节点移动到另一个节点不需要停止操作，因此添加和删除节点或更改节点持有的哈希槽百分比不需要任何停机时间。

Redis Cluster 支持多键操作，只要涉及到单个命令执行（或整个事务，或 Lua 脚本执行）的所有键都属于同一个哈希槽。用户可以使用称为散列标签的概念强制多个键成为同一个散列槽的一部分。

Redis Cluster 规范中记录了哈希标签，但要点是如果键中的 {} 括号之间有一个子字符串，则只有字符串内的内容会被哈希，因此例如this{foo}key和another{foo}key 保证在同一个哈希槽中, 并且可以在具有多个键作为参数的命令中一起使用。

Redis Cluster 主从模式 为了在主节点子集出现故障或无法与大多数节点通信时保持可用，Redis 集群使用主从模型，其中每个哈希槽具有从 1（主节点本身）到 N 个副本（N -1 个额外的从节点）。

在我们包含节点 A、B、C 的示例集群中，如果节点 B 发生故障，集群将无法继续，因为我们不再有办法为 5501-11000 范围内的哈希槽提供服务。


然而，当集群创建时（或稍后），我们为每个主节点添加一个从节点，这样最终的集群由主节点 A、B、C 和从节点 A1、B1、C1 组成. 这样，如果节点 B 出现故障，系统就能够继续运行。

节点 B1 复制 B，并且 B 失败，集群会将节点 B1 提升为新的 master 并继续正常运行。

但是需要注意的是，如果节点 B 和 B1 同时发生故障，Redis Cluster 将无法继续运行。

Redis 集群一致性保证 Redis Cluster 无法保证强一致性。实际上，这意味着在某些情况下，Redis Cluster 可能会丢失系统已向客户端确认的写入。

Redis Cluster 会丢失写入的第一个原因是因为它使用异步复制。这意味着在写入期间会发生以下情况：

您的客户端写入主 B。 主 B 向您的客户端回复 OK。 主设备 B 将写入传播到其从设备 B1、B2 和 B3。 如您所见，B 在回复客户端之前不会等待来自 B1、B2、B3 的确认，因为这对 Redis 来说是一个令人望而却步的延迟惩罚，因此如果您的客户端写入某些内容，B 会确认写入，但会在之前崩溃能够将写入发送到其从站，其中一个从站（未收到写入）可以提升为主站，永远失去写入。

这与大多数配置为每秒将数据刷新到磁盘的数据库发生的情况非常相似，因此您已经能够推理出这种情况，因为过去使用不涉及分布式系统的传统数据库系统的经验。同样，您可以通过强制数据库在回复客户端之前将数据刷新到磁盘来提高一致性，但这通常会导致性能低得令人望而却步。在 Redis Cluster 的情况下，这相当于同步复制。

基本上，需要在性能和一致性之间进行权衡。


## 部署Redis

在Kubernetes中部署Redis集群面临挑战，因为每个Redis实例都依赖于一个配置文件，该文件可以跟踪其他集群实例及其角色。为此，我们需要结合使用Kubernetes StatefulSets和PersistentVolumes。

*PV的建立* 需要建立6个PersistentVolume，pv是集群级别的基础资源，声明pv时候，使用apply 进行创建是不需要指定命名空间的。 执行与结果：


```
$ cat redis-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  finalizers:
    - kubernetes.io/pv-protection
  labels:
    alicloud-pvname: redis-pv1
  name: redis-pv1
spec:
  capacity:
    storage: 3Gi
  accessModes: 
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  storageClassName: "redis-cluster"
  csi:
    driver: nasplugin.csi.alibabacloud.com
    volumeAttributes:
      path: /data/pv1
      server: ID-dxx6.cn-beijing.nas.aliyuncs.com
      vers: '3'
    volumeHandle: redis-pv1
---  
apiVersion: v1
kind: PersistentVolume
metadata:
  finalizers:
    - kubernetes.io/pv-protection
  labels:
    alicloud-pvname: redis-pv2
  name: redis-pv2
spec:
  capacity:
    storage: 3Gi
  accessModes: 
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  storageClassName: "redis-cluster"
  csi:
    driver: nasplugin.csi.alibabacloud.com
    volumeAttributes:
      path: /data/pv2
      server: ID-dxx6.cn-beijing.nas.aliyuncs.com
      vers: '3'
    volumeHandle: redis-pv2
---
apiVersion: v1
kind: PersistentVolume
metadata:
  finalizers:
    - kubernetes.io/pv-protection
  labels:
    alicloud-pvname: redis-pv3
  name: redis-pv3
spec:
  capacity:
    storage: 3Gi
  accessModes: 
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  storageClassName: "redis-cluster"
  csi:
    driver: nasplugin.csi.alibabacloud.com
    volumeAttributes:
      path: /data/pv3
      server: ID-dxx6.cn-beijing.nas.aliyuncs.com
      vers: '3'
    volumeHandle: redis-pv3
---
apiVersion: v1
kind: PersistentVolume
metadata:
  finalizers:
    - kubernetes.io/pv-protection
  labels:
    alicloud-pvname: redis-pv4
  name: redis-pv4
spec:
  capacity:
    storage: 3Gi
  accessModes: 
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  storageClassName: "redis-cluster"
  csi:
    driver: nasplugin.csi.alibabacloud.com
    volumeAttributes:
      path: /data/pv4
      server: ID-dxx6.cn-beijing.nas.aliyuncs.com
      vers: '3'
    volumeHandle: redis-pv4
---
apiVersion: v1
kind: PersistentVolume
metadata:
  finalizers:
    - kubernetes.io/pv-protection
  labels:
    alicloud-pvname: redis-pv5
  name: redis-pv5
spec:
  capacity:
    storage: 3Gi
  accessModes: 
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  storageClassName: "redis-cluster"
  csi:
    driver: nasplugin.csi.alibabacloud.com
    volumeAttributes:
      path: /data/pv5
      server: ID-dxx6.cn-beijing.nas.aliyuncs.com
      vers: '3'
    volumeHandle: redis-pv5
---
apiVersion: v1
kind: PersistentVolume
metadata:
  finalizers:
    - kubernetes.io/pv-protection
  labels:
    alicloud-pvname: redis-pv6
  name: redis-pv6
spec:
  capacity:
    storage: 3Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  storageClassName: "redis-cluster"
  csi:
    driver: nasplugin.csi.alibabacloud.com
    volumeAttributes:
      path: /data/pv6
      server: ID-dxx6.cn-beijing.nas.aliyuncs.com
      vers: '3'
    volumeHandle: redis-pv6 
```

```
$ kubectl apply -f redis-pv.yaml
persistentvolume/redis-pv1 created
persistentvolume/redis-pv2 created
persistentvolume/redis-pv3 created
persistentvolume/redis-pv4 created
persistentvolume/redis-pv5 created
persistentvolume/redis-pv6 created
```

此时查看到pv已经就绪

```
$ kubectl get pv
NAME                                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                        STORAGECLASS               REASON   AGE
redis-pv1                                                  3Gi        RWO            Recycle          Available                                redis-cluster                       3m6s
redis-pv2                                                  3Gi        RWO            Recycle          Available                                redis-cluster                       3m6s
redis-pv3                                                  3Gi        RWO            Recycle          Available                                redis-cluster                       3m6s
redis-pv4                                                  3Gi        RWO            Recycle          Available                                redis-cluster                       3m6s
redis-pv5                                                  3Gi        RWO            Recycle          Available                                redis-cluster                       3m6s
redis-pv6                                                  3Gi        RWO            Recycle          Available                                redis-cluster                       3m6s
```

*statefulset的建立* 这里可以自定义redis的conf配置,并且带上了namespaces,使pod会在db空间内生成。

```
cat  redis-sts.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: redis-cluster
data:
  update-node.sh: |
    #!/bin/sh
    REDIS_NODES="/data/nodes.conf"
    sed -i -e "/myself/ s/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/${POD_IP}/" ${REDIS_NODES}
    exec "$@"    
  redis.conf: |+
    cluster-enabled yes
    cluster-require-full-coverage no
    cluster-node-timeout 15000
    cluster-config-file /data/nodes.conf
    cluster-migration-barrier 1
    appendonly yes
    protected-mode no    
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: redis-cluster
spec:
  serviceName: redis-cluster
  replicas: 6
  selector:
    matchLabels:
      app: redis-cluster
  template:
    metadata:
      labels:
        app: redis-cluster
    spec:
      containers:
      - name: redis
        image: redis:6.2.1
        ports:
        - containerPort: 6379
          name: client
        - containerPort: 16379
          name: gossip
        command: ["/conf/update-node.sh", "redis-server", "/conf/redis.conf"]
        env:
        - name: POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        volumeMounts:
        - name: conf
          mountPath: /conf
          readOnly: false
        - name: data
          mountPath: /data
          readOnly: false
      volumes:
      - name: conf
        configMap:
          name: redis-cluster
          defaultMode: 0755
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 3Gi
      storageClassName: redis-cluster
```

```
$ kubectl apply -f redis-sts.yml -n db
configmap/redis-cluster created
statefulset.apps/redis-cluster created
```

此时查看pod状态,为Runing

```
$ kubectl get pods -l app=redis-cluster -n db
NAME              READY   STATUS    RESTARTS   AGE
redis-cluster-0   1/1     Running   0          37s
redis-cluster-1   1/1     Running   0          35s
redis-cluster-2   1/1     Running   0          34s
redis-cluster-3   1/1     Running   0          30s
redis-cluster-4   1/1     Running   0          28s
redis-cluster-5   1/1     Running   0          27s
```

查看存储声明pvc，和存储卷pv

```
$ kubectl get pvc -n db
NAME                   STATUS   VOLUME      CAPACITY   ACCESS MODES   STORAGECLASS    AGE
data-redis-cluster-0   Bound    redis-pv1   3Gi        RWO            redis-cluster   2m30s
data-redis-cluster-1   Bound    redis-pv2   3Gi        RWO            redis-cluster   2m28s
data-redis-cluster-2   Bound    redis-pv3   3Gi        RWO            redis-cluster   2m27s
data-redis-cluster-3   Bound    redis-pv4   3Gi        RWO            redis-cluster   2m23s
data-redis-cluster-4   Bound    redis-pv5   3Gi        RWO            redis-cluster   2m21s
data-redis-cluster-5   Bound    redis-pv6   3Gi        RWO            redis-cluster   2m20s
```

此时pod内的redis已经跑起来了。

*service的建立* 建立一个service使其可以被外部使用，Service是一种抽象的对象，它定义了一组Pod的逻辑集合和一个用于访问它们的策略，一个Serivce下面包含的Pod集合一般是由Label Selector来决定的。我们后端运行了6个副本，这些副本都是可以替代的，因为前端并不关心它们使用的是哪一个后端服务。尽管由于各种原因后端的Pod集合会发生变化，但是前端却不需要知道这些变化，也不需要自己用一个列表来记录这些后端的服务，Service的这种抽象就可以帮我们达到这种解耦的目的。

```
cat redis-svc.yml
---
apiVersion: v1
kind: Service
metadata:
  name: redis-cluster
spec:
  type: ClusterIP
  clusterIP: 172.21.7.233
  ports:
  - port: 6379
    targetPort: 6379
    name: client
  - port: 16379
    targetPort: 16379
    name: gossip
  selector:
    app: redis-cluster
```

```
$ kubectl apply -f redis-svc.yml -n db
service/redis-cluster created
```

查看它

```
$ kubectl get svc -n db
NAME            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)              AGE
redis-cluster   ClusterIP   172.21.7.233   <none>        6379/TCP,16379/TCP   27s
```

## 部署Redis Cluster

下一步是形成Redis集群。为此，我们运行以下命令并键入`yes`以接受配置。前三个节点成为主节点，后三个节点成为从节点。

### 组成集群

```
$ kubectl exec -it redis-cluster-0 -n db -- redis-cli --cluster create --cluster-replicas 1 $(kubectl get pods -l app=redis-cluster -n db -o jsonpath='{range.items[*]}{.status.podIP}:6379 ')
>>> Performing hash slots allocation on 6 nodes...
Master[0] -> Slots 0 - 5460
Master[1] -> Slots 5461 - 10922
Master[2] -> Slots 10923 - 16383
Adding replica 10.0.0.161:6379 to 10.0.0.228:6379
Adding replica 10.0.0.231:6379 to 10.0.0.160:6379
Adding replica 10.0.0.230:6379 to 10.0.0.229:6379
M: e932f689437e024d1f961f78d3eabdc595605460 10.0.0.228:6379
   slots:[0-5460] (5461 slots) master
M: 5caf072ecb472fc3a0cd9d09c76f25ba726a2bef 10.0.0.160:6379
   slots:[5461-10922] (5462 slots) master
M: 9b6cd2c941ca59967b6b239f22ccce97c0fe3207 10.0.0.229:6379
   slots:[10923-16383] (5461 slots) master
S: 9ce6c623287c3d1e27095209d7259f8af911d349 10.0.0.230:6379
   replicates 9b6cd2c941ca59967b6b239f22ccce97c0fe3207
S: 1db5432d03bba51ade44572a362cbde1315daa4b 10.0.0.161:6379
   replicates e932f689437e024d1f961f78d3eabdc595605460
S: 6ddf99f6f9c10e2fef06f8309ef273f21a2a1714 10.0.0.231:6379
   replicates 5caf072ecb472fc3a0cd9d09c76f25ba726a2bef
Can I set the above configuration? (type 'yes' to accept): yes
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join
..
>>> Performing Cluster Check (using node 10.0.0.228:6379)
M: e932f689437e024d1f961f78d3eabdc595605460 10.0.0.228:6379
   slots:[0-5460] (5461 slots) master
   1 additional replica(s)
S: 1db5432d03bba51ade44572a362cbde1315daa4b 10.0.0.161:6379
   slots: (0 slots) slave
   replicates e932f689437e024d1f961f78d3eabdc595605460
M: 5caf072ecb472fc3a0cd9d09c76f25ba726a2bef 10.0.0.160:6379
   slots:[5461-10922] (5462 slots) master
   1 additional replica(s)
S: 6ddf99f6f9c10e2fef06f8309ef273f21a2a1714 10.0.0.231:6379
   slots: (0 slots) slave
   replicates 5caf072ecb472fc3a0cd9d09c76f25ba726a2bef
M: 9b6cd2c941ca59967b6b239f22ccce97c0fe3207 10.0.0.229:6379
   slots:[10923-16383] (5461 slots) master
   1 additional replica(s)
S: 9ce6c623287c3d1e27095209d7259f8af911d349 10.0.0.230:6379
   slots: (0 slots) slave
   replicates 9b6cd2c941ca59967b6b239f22ccce97c0fe3207
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
```

### 验证集群部署

```
$ kubectl exec -it redis-cluster-0 -n db -- redis-cli cluster info
cluster_state:ok
cluster_slots_assigned:16384
cluster_slots_ok:16384
cluster_slots_pfail:0
cluster_slots_fail:0
cluster_known_nodes:6
cluster_size:3
cluster_current_epoch:6
cluster_my_epoch:1
cluster_stats_messages_ping_sent:2358
cluster_stats_messages_pong_sent:2471
cluster_stats_messages_sent:4829
cluster_stats_messages_ping_received:2466
cluster_stats_messages_pong_received:2358
cluster_stats_messages_meet_received:5
cluster_stats_messages_received:4829
```

### 查看role

```
for x in $(seq 0 5); do
    echo "redis-cluster-$x"
    kubectl exec redis-cluster-$x -n db -- redis-cli role
    echo
done
```

```
$ for x in $(seq 0 5); do     echo "redis-cluster-$x";     kubectl exec redis-cluster-$x -n db -- redis-cli role;     echo; done
redis-cluster-0
master
3486
10.0.0.161
6379
3486

redis-cluster-1
master
3486
10.0.0.231
6379
3486

redis-cluster-2
master
3500
10.0.0.230
6379
3486

redis-cluster-3
slave
10.0.0.229
6379
connected
3500

redis-cluster-4
slave
10.0.0.228
6379
connected
3486

redis-cluster-5
slave
10.0.0.160
6379
connected
3486
```

### 测试 Redis 集群

在生产使用之前，做好测试工作是必要的。进行连接和故障模拟，对于连接使用将部署一个简单的Python应用程序，而对于故障模拟将删除一个节点并观察集群行为。

#### 部署命中计数器应用

将一个简单的应用程序部署到我们的集群中，并在它前面放置一个负载均衡器。此应用程序的目的是在将计数器值作为 HTTP 响应返回之前增加一个计数器并将该值存储在 Redis 集群中。

```
cat app-deployment-service.yml
apiVersion: v1
kind: Service
metadata:
  name: hit-counter-lb
spec:
  type: ClusterIP
  ports:
  - port: 80
    protocol: TCP
    targetPort: 5000
  selector:
      app: myapp
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hit-counter-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: calinrus/api-redis-ha:1.0
        ports:
        - containerPort: 5000
```

应用

```
$ kubectl apply -f app-deployment-service.yml -n db
service/hit-counter-lb created
deployment.apps/hit-counter-app created
```

此时，我们可以开始使用浏览器点击 IP 来为点击计数器生成一些值。 获取ip

```
$ kubectl get svc -n db
NAME             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)              AGE
hit-counter-lb   ClusterIP   172.21.15.161   <none>        80/TCP               2m37s
redis-cluster    ClusterIP   172.21.7.233    <none>        6379/TCP,16379/TCP   57m
``` 

也可以通过`kubectl get svc hit-counter-lb -o json|jq -r .spec.clusterIP`获取。 现在直接使用`curl`进行模拟点击

```
$ curl 172.21.15.161
I have been hit 1 times since deployment.
$ curl 172.21.15.161
I have been hit 2 times since deployment.
$ curl `kubectl get svc hit-counter-lb -n db -o json|jq -r .spec.clusterIP`
I have been hit 3 times since deployment.
$ kubectl exec -it redis-cluster-0 -n db -- redis-cli get hits
"3"
```

可看到redis集群正常工作。

#### 模拟节点故障

从前面的信息当中我们可以得知redis-cluster-0为集群其中的一个master节点，我们可以直接对其进行删除来模拟主节点宕机的情形：

```
$ kubectl describe pods redis-cluster-0 -n db | grep IP
IP:           10.0.0.228
IPs:
  IP:           10.0.0.228
      POD_IP:   (v1:status.podIP)
#此时redis-cluster-0的ip为10.0.0.228

$ kubectl delete pods redis-cluster-0 -n db
pod "redis-cluster-0" deleted

# 已经删除，再次获取ip印证
$ kubectl describe pods redis-cluster-0 -n db | grep IP
IP:           10.0.0.234
IPs:
  IP:           10.0.0.234
      POD_IP:   (v1:status.podIP)
```
数据有没有丢失呢？ 再次验证一下

```
$ kubectl exec -it redis-cluster-0 -n db -- redis-cli get hits
"3"
$ curl `kubectl get svc hit-counter-lb -n db -o json|jq -r .spec.clusterIP`
I have been hit 4 times since deployment.
```

可以看到数据还在，并且模拟点击时数值也是正常的变化。

#### 集群如何愈合

当我们创建集群时，我们创建了一个 ConfigMap，它反过来创建了一个脚本/conf/update-node.sh，容器在启动时调用该脚本。此脚本使用本地节点的新 IP 地址更新 Redis 配置。使用 confic 中的新 IP，集群可以在新 Pod 以不同 IP 地址启动后修复。

在这个过程中，如果我们继续加载页面，计数器继续递增，随着集群收敛，我们看到没有数据丢失。

### 结论

Redis 是一个强大的数据存储和缓存工具。由于 Redis 存储数据的方式，Redis Cluster 通过提供分片和相关的性能优势、线性扩展和更高的可用性来扩展功能。数据会自动在多个节点之间拆分，从而允许操作继续进行，即使部分节点出现故障或无法与集群的其余部分进行通信。

有关 Redis Cluster 的更多信息，请访[问官方教程][3]或[规范文档][4]。

那么更多，可参考文献：[Deploying Redis Cluster on Top of Kubernetes][5]


  [1]: https://www.xiaohuait.com/2020/06/15/%E4%B8%80%E6%96%87%E8%AF%BB%E6%87%82redis%E7%9A%84%E5%9B%9B%E7%A7%8D%E6%A8%A1%E5%BC%8F%EF%BC%8C%E5%8D%95%E6%9C%BA%E3%80%81%E4%B8%BB%E4%BB%8E%E3%80%81%E5%93%A8%E5%85%B5%E3%80%81%E9%9B%86%E7%BE%A4/
  [2]: https://oss.itan90.cn/out_pic/2022-06-04/TsqPvX.jpg
  [3]: https://redis.io/topics/cluster-tutorial
  [4]: https://redis.io/topics/cluster-spec
  [5]: https://rancher.com/blog/2019/deploying-redis-cluster/