---
title: "DeepSeek-R1 vLLM性能基准测试：wrk压力测试详细报告"
date: 2025-05-30T00:24:14+08:00
tags: [vllm]
categories: [vllm, deepseek, wrk, stress]
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

创建一个请求文件

```shell
cat > post.lua << 'EOF'
wrk.method = "POST"
wrk.body = '{"model":"deepseek-14b","messages":[{"role":"user","content":"写一个50字的短文"}],"max_tokens":50}'
wrk.headers["Content-Type"] = "application/json"
wrk.headers["Authorization"] = "Bearer your-api-key"
EOF
```

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

## 服务器容量估算

基于以上性能测试报告，估算1000注册用户的服务器配置需求。

#### 用户行为分析与容量估算

1. 用户活跃度假设
对于1000注册用户，需要考虑不同的活跃度场景：

**保守估算（10%同时在线）**：
- 同时在线用户：100人
- 峰值并发请求：假设20-30%用户同时发起请求
- 预期并发数：20-30个请求

**中等估算（20%同时在线）**：
- 同时在线用户：200人
- 峰值并发请求：40-60个请求

**高峰估算（30%同时在线）**：
- 同时在线用户：300人
- 峰值并发请求：60-90个请求

2. 基于测试数据的性能分析

从报告数据看：
- **单台A40服务器最大RPS**: 36.60（200连接时）
- **推荐配置RPS**: 26.64（100连接，延迟3.62s）
- **每个请求平均响应时间**: 3-5秒

#### 服务器配置建议

方案A：保守配置（适合轻度使用）
```
硬件配置：
- 2台 NVIDIA A40 服务器
- 负载均衡器
- 理论峰值：70+ RPS
- 支持并发：50-60个请求
```

方案B：标准配置（推荐）
```
硬件配置：
- 3-4台 NVIDIA A40 服务器  
- 负载均衡器 + 自动扩缩容
- 理论峰值：100-140 RPS
- 支持并发：80-100个请求
```

方案C：高性能配置（高频使用）
```
硬件配置：
- 5-6台 NVIDIA A40 服务器
- 高可用负载均衡
- 理论峰值：180+ RPS  
- 支持并发：120-150个请求
```

#### 成本与性能权衡

**推荐方案B的理由**：
- 考虑到AI推理的3-5秒延迟，用户不会频繁发起请求
- 预留50%性能余量应对突发流量
- 支持业务增长空间
- 成本相对合理

#### 监控与优化建议

**关键监控指标**：
- 实时并发数
- 平均响应时间
- GPU利用率
- 队列长度

**优化策略**：
- 实现请求队列管理
- 设置用户频率限制（如每分钟最多3次请求）
- 考虑缓存常见请求结果
- 实现服务降级机制

#### 实际部署建议

**初期部署**：
- 先部署2台A40服务器测试真实用户行为
- 收集1-2周的实际使用数据
- 根据真实并发模式调整配置

**扩容计划**：
- 当平均GPU利用率超过70%时考虑扩容
- 当95%响应时间超过8秒时必须扩容

这样的配置应该能够很好地支持1000用户的AI服务需求，同时保持良好的用户体验和合理的成本控制。
