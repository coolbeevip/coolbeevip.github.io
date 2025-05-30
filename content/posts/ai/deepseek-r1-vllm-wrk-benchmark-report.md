---
title: "DeepSeek-R1 vLLM性能基准测试：wrk压力测试详细报告"
date: 2025-05-30T00:24:14+08:00
tags: [vllm]
categories: [vllm, benchmark, wrk]
draft: false
---

## 配置

- DeepSeek-R1-Distill-Qwen-14B
- NVIDIA A40
- vLLM vllm/vllm-openai:v0.8.5
- NVIDIA-SMI 560.35.03              
- Driver Version: 560.35.03      
- CUDA Version: 12.6
- [wrk](https://github.com/wg/wrk)

## 测试方法

10 线程 20 并发持续测试一分钟

```shell
[root@myserver wrk-4.2.0]# ./wrk --timeout 30s -t10 -c20 -d60s -s post.lua http://10.1.2.100:8080/v1/chat/completions
Running 1m test @ http://10.1.2.100:8080/v1/chat/completions
  10 threads and 20 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     3.07s    38.32ms   3.20s    66.93%
    Req/Sec     1.45      3.05    10.00     87.92%
  381 requests in 1.00m, 285.10KB read
Requests/sec:      6.34
Transfer/sec:      4.74KB
```

10 线程 100 并发持续测试一分钟

```shell
[root@myserver wrk-4.2.0]# ./wrk --timeout 30s -t10 -c100 -d60s -s post.lua http://10.1.2.100:8080/v1/chat/completions
Running 1m test @ http://10.1.2.100:8080/v1/chat/completions
  10 threads and 100 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     3.62s   108.42ms   4.34s    95.19%
    Req/Sec    20.14     22.29    89.00     88.81%
  1601 requests in 1.00m, 1.17MB read
Requests/sec:     26.64
Transfer/sec:     19.97KB
```

100 线程 100 并发持续测试一分钟

```shell
[root@myserver wrk-4.2.0]# ./wrk --timeout 30s -t100 -c100 -d60s -s post.lua http://10.1.2.100:8080/v1/chat/completions
Running 1m test @ http://10.1.2.100:8080/v1/chat/completions
  100 threads and 100 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     3.62s   103.22ms   4.24s    87.65%
    Req/Sec     0.00      0.00     0.00    100.00%
  1603 requests in 1.00m, 1.17MB read
Requests/sec:     26.67
Transfer/sec:     19.99KB
```

100 线程 200 并发持续测试一分钟

```shell
[root@myserver wrk-4.2.0]# ./wrk --timeout 30s -t100 -c200 -d60s -s post.lua http://10.1.2.100:8080/v1/chat/completions
Running 1m test @ http://10.1.2.100:8080/v1/chat/completions
  100 threads and 200 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     5.27s   265.22ms   6.80s    92.77%
    Req/Sec     1.33      3.25    10.00     86.58%
  2200 requests in 1.00m, 1.61MB read
Requests/sec:     36.60
Transfer/sec:     27.43KB
```

## 报告解读

#### 测试配置对比

| 测试 | 线程数 | 连接数 | 平均延迟  | RPS   | 传输速率      |
|----|-----|-----|-------|-------|-----------|
| 1  | 10  | 20  | 3.07s | 6.34  | 4.74KB/s  |
| 2  | 10  | 100 | 3.62s | 26.64 | 19.97KB/s |
| 3  | 100 | 100 | 3.62s | 26.67 | 19.99KB/s |
| 4  | 100 | 200 | 5.27s | 36.60 | 27.43KB/s |

#### 关键发现

**性能瓶颈分析：**
- 服务器在低并发（20连接）时表现最差，RPS仅6.34
- 并发数从20增加到100时，性能显著提升（RPS从6.34提升到26.64）
- 线程数从10增加到100对性能影响很小（测试2和3几乎相同）
- 连接数增加到200时，延迟明显上升（从3.62s增加到5.27s）

**延迟特征：**
- 所有测试的平均延迟都超过3秒，表明这是一个高延迟的服务（可能是AI推理服务）
- 延迟标准差相对较小，说明响应时间比较稳定
- 最高延迟在6.8秒以内，99%的请求延迟分布较为集中

**吞吐量分析：**
- 最佳吞吐量出现在200连接配置下（36.60 RPS）
- 100连接配置达到了较好的延迟/吞吐量平衡点
- 传输数据量较小，每个响应平均约750字节

#### 建议

1. **最优配置**：推荐使用100连接的配置，能够在保持合理延迟的同时获得良好的吞吐量
2. **容量规划**：当前服务器在理想条件下最大支持约40 RPS
3. **监控重点**：重点关注3-6秒的响应时间是否符合业务需求
4. **扩展方案**：如需更高吞吐量，考虑水平扩展或优化后端处理逻辑

这个性能表现符合典型的AI推理服务特征，高延迟但相对稳定的响应时间。

