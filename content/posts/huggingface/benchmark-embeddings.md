---
title: "Benchmark for BAAI/bge-3m on an Nvidia A800/CPU/Mac M1"
date: 2025-01-06T13:24:14+08:00
tags: [huggingface,embedding]
categories: [embedding,bge-3m,benchmark]
draft: false
---

在同一个服务器上测试 CPU/GPU 性能差异

## 测试代码

```shell
import time

import sentence_transformers
import torch

if __name__ == "__main__":
    device = "cuda" if torch.cuda.is_available() else "cpu"
    embedding = sentence_transformers.SentenceTransformer(
        model_name_or_path="/Volumes/SD/huggingface-models/bge-m3",
        cache_folder="/Volumes/SD/huggingface-models",
        device=device
    )
    total = 10000
    batch_size = 100
    start_time = time.time()
    sentences = ["I am AnCopilot, nice to meet you!"]
    for i in range(total // batch_size):
        embedding.encode(sentences * batch_size, normalize_embeddings=True)
        print(f"{i + 1} / {total // batch_size}")
    end_time = time.time()
    total_time = end_time - start_time
    average_time = total_time / total
    throughput = total / total_time
    print(f"Device {device}")
    print(f"Total {total} sentences")
    print(f"Batch size: {batch_size}")
    print(f"Total time: {total_time:.4f} seconds")
    print(f"Average time per iteration: {average_time:.4f} seconds")
    print(f"Throughput: {throughput:.2f} iterations per second")
```

## 设备信息

GPU 设备信息

```
+---------------------------------------------------------------------------------------+
| NVIDIA-SMI 535.129.03             Driver Version: 535.129.03   CUDA Version: 12.2     |
|-----------------------------------------+----------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |         Memory-Usage | GPU-Util  Compute M. |
|                                         |                      |               MIG M. |
|=========================================+======================+======================|
|   0  NVIDIA A800-SXM4-80GB          Off | 00000000:3D:00.0 Off |                    0 |
| N/A   35C    P0              63W / 400W |  47848MiB / 81920MiB |      0%      Default |
|                                         |                      |             Disabled |
+-----------------------------------------+----------------------+----------------------+
```

CPU 信息

| 属性                      | 值                                                         |
|-------------------------|------------------------------------------------------------|
| Architecture            | x86_64                                                    |
| CPU op-mode(s)         | 32-bit, 64-bit                                           |
| Byte Order              | Little Endian                                            |
| CPU(s)                  | 128                                                        |
| On-line CPU(s) list     | 0-127                                                      |
| Thread(s) per core      | 2                                                          |
| Core(s) per socket      | 32                                                         |
| Socket(s)               | 2                                                          |
| NUMA node(s)           | 2                                                          |
| Vendor ID               | GenuineIntel                                             |
| CPU family              | 6                                                          |
| Model                   | 106                                                        |
| Model name              | Intel(R) Xeon(R) Platinum 8358P CPU @ 2.60GHz            |
| Stepping                | 6                                                          |
| CPU MHz                 | 800.000                                                   |
| CPU max MHz             | 2601.0000                                                |
| CPU min MHz             | 800.0000                                                 |
| BogoMIPS                | 5200.00                                                  |
| Virtualization           | VT-x                                                      |
| L1d cache               | 48K                                                       |
| L1i cache               | 32K                                                       |
| L2 cache                | 1280K                                                    |
| L3 cache                | 49152K                                                  |
| NUMA node0 CPU(s)      | 0-31, 64-95                                              |
| NUMA node1 CPU(s)      | 32-63, 96-127                                            |
| Flags                   | fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc art arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf eagerfpu pni pclmulqdq dtes64 ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid dca sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch epb cat_l3 invpcid_single ssbd mba rsb_ctxsw ibrs ibpb stibp ibrs_enhanced tpr_shadow vnmi flexpriority ept vpid fsgsbase tsc_adjust bmi1 hle avx2 smep bmi2 erms invpcid rtm cqm rdt_a avx512f avx512dq rdseed adx smap avx512ifma clflushopt clwb intel_pt avx512cd sha_ni avx512bw avx512vl xsaveopt xsavec xgetbv1 cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local dtherm ida arat pln pts avx512vbmi umip pku ospke avx512_vbmi2 gfni vaes vpclmulqdq avx512_vnni avx512_bitalg avx512_vpopcntdq md_clear pconfig spec_ctrl intel_stibp flush_l1d arch_capabilities |

内存信息

|        类型        |   总计   |    已用    |   空闲   |  共享   |  缓冲/缓存  | 可用   |
|------------------|---------|------------|--------|-------|---------|-------|
| **Mem**          |  2.0T   |   302G     |  37G   | 8.1G  |  1.6T   | 1.7T  |
| **Swap**         |   0B    |    0B      |  0B    |  -    |    -    |   -   |

## 对比结果

以下是基准测试结果的对比表格：

| Device   | Batch Size | Total Sentences | Total Time (seconds) | Average Time per Iteration (seconds) | Throughput (iterations per second) |
|----------|------------|-----------------|----------------------|--------------------------------------|------------------------------------|
| CUDA     | 100        | 10000           | 13.6438              | 0.0014                               | 732.93                             |
| **CUDA** | **200**    | **10000**       | **12.1587**          | **0.0012**                           | **822.46**                         |
| CPU      | 100        | 10000           | 77.3202              | 0.0077                               | 129.33                             |
| CPU      | 200        | 10000           | 72.6335              | 0.0073                               | 137.68                             |


## 总结

根据基准测试结果，可以得出以下分析和总结：

1. **设备性能**：
    - **CUDA（GPU）设备的表现明显优于CPU设备**。无论是100还是200的批量大小，CUDA设备的总时间和每次迭代的时间均显著低于CPU设备，CPU的总时间大约是CUDA的5到6倍。

2. **批量大小的影响**：
    - **增加批量大小对CUDA设备有利**：在CUDA上，从100的批量大小提升到200，虽然总时间略有减少（从13.6438秒降至12.1587秒），每次迭代的时间也减少了（从0.0014秒降至0.0012秒），同时吞吐量提升了（从732.93迭代/秒增至822.46迭代/秒）。
    - **在CPU设备上，增加批量大小同样有利**：在CPU上，从批量大小100提高到200，虽然总时间也有所减少（从77.3202秒降至72.6335秒），每次迭代的时间也有小幅下降（从0.0077秒下降至0.0073秒），吞吐量由129.33迭代/秒提升至137.68迭代/秒。

3. **总体吞吐量**：
    - CUDA设备的吞吐量显著高于CPU设备，200批量的CUDA吞吐量达到822.46迭代/秒，而CPU则只有137.68迭代/秒，这表明在处理大量数据时，CUDA设备能够提供更高的效率。

4. **总结**：
    - 在执行密集型任务（如处理大量句子）时，使用CUDA（GPU）设备会显著提高性能，减少计算时间。尽管CPU设备可通过增加批量大小来提高效率，但其性能仍无法与GPU设备相较。对于大量数据的处理，特别是需要实时反馈或低延迟的场景，选择CUDA设备将是更优的选择。