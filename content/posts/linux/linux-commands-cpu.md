---
title: "Linux Command - CPU"
date: 2022-10-23T13:24:14+08:00
tags: [linux,cpu]
categories: [linux]
draft: false
---

Linux CPU 相关命令

## 查看 CPU 信息

```shell
$ lscpu
Architecture:          x86_64
CPU op-mode(s):        32-bit, 64-bit
Byte Order:            Little Endian
CPU(s):                4
On-line CPU(s) list:   0-3
Thread(s) per core:    1
Core(s) per socket:    1
Socket(s):             4
NUMA node(s):          1
Vendor ID:             GenuineIntel
CPU family:            6
Model:                 85
Model name:            Intel Xeon Processor (Skylake, IBRS)
Stepping:              4
CPU MHz:               2299.996
BogoMIPS:              4599.99
Hypervisor vendor:     KVM
Virtualization type:   full
L1d cache:             32K
L1i cache:             32K
L2 cache:              4096K
L3 cache:              16384K
NUMA node0 CPU(s):     0-3
Flags:                 fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss syscall nx pdpe1gb rdtscp lm constant_tsc rep_good nopl xtopology eagerfpu pni pclmulqdq ssse3 fma cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand hypervisor lahf_lm abm 3dnowprefetch ssbd ibrs ibpb stibp fsgsbase tsc_adjust bmi1 hle avx2 smep bmi2 erms invpcid rtm mpx avx512f avx512dq rdseed adx smap clflushopt clwb avx512cd avx512bw avx512vl xsaveopt xsavec xgetbv1 arat pku ospke spec_ctrl intel_stibp
```

## PI 值计算

```shell
$ time echo "scale=5000; 4*a(1)" | bc -l -q
```

## 7-Zip 基准测试

使用 7-Zip 自带的 LZMA 压缩基准测试测量 CPU 性能

```shell
$ 7z b

7-Zip [64] 16.02 : Copyright (c) 1999-2016 Igor Pavlov : 2016-05-21
p7zip Version 16.02 (locale=en_US.UTF-8,Utf16=on,HugeFiles=on,64 bits,4 CPUs Intel Xeon Processor (Skylake, IBRS) (50654),ASM,AES-NI)

Intel Xeon Processor (Skylake, IBRS) (50654)
CPU Freq:  1106  1368  1615  1863  2100  1640  1563  2267  1850

RAM size:   32174 MB,  # CPU hardware threads:   4
RAM usage:    882 MB,  # Benchmark threads:      4

                       Compressing  |                  Decompressing
Dict     Speed Usage    R/U Rating  |      Speed Usage    R/U Rating
         KiB/s     %   MIPS   MIPS  |      KiB/s     %   MIPS   MIPS

22:       8734   350   2431   8497  |     112951   376   2565   9637
23:       8339   313   2718   8497  |      97692   351   2405   8453
24:       9997   355   3028  10749  |      99152   362   2406   8704
25:       9219   368   2860  10527  |      93486   342   2430   8320
----------------------------------  | ------------------------------
Avr:             346   2759   9567  |              358   2452   8778
Tot:             352   2605   9173
```