---
title: "Approximate Counting Morris Algorithm in Java"
date: 2021-08-20T13:24:14+08:00
tags: [counter,approximate]
categories: [algorithm]
draft: false
type: "post"
---

本文介绍如何使用莫里斯计数器（近似计数算法）的 Java 实现 ，莫里斯计数器采用概率计数原理，用很小的内存实现海量数据的近似计数。

本例中，我们使用一个 byte (8bit) 的变量，实现千万级的计数

```java
public class MorrisApproximateCounter {

  private static final Logger log = LoggerFactory.getLogger(MethodHandles.lookup().lookupClass());

  /**
   * 定义一个计数器变量
   */
  byte counter = 0;

  /**
   * 使用随机模拟概率
   */
  Random random = new Random();

  /**
   * 计算计数器表示的近似值
   */
  public double get() {
    return Math.exp(counter);
  }

  /**
   * 计数器累加
   */
  public void increment() {
    double probability = 1.0 / this.get();
    // 使用伪随机数增加概率
    if (random.nextDouble() < probability) {
      this.counter++;
    }
  }

  public static void main(String[] args) {
    MorrisApproximateCounter mc = new MorrisApproximateCounter();

    // 定义实际数量
    int realCount = 20_000_000;

    for (int n = 0; n < realCount; n++) {
      // 累加计数
      mc.increment();
    }

    // 输出实际计数 和 近似计数
    log.info("实际计数 {}, 近似计数 {}", realCount, (int) mc.get());
  }
}
```

执行结果

```shell
22:09:42.416 [main] INFO org.coolbeevip.algorithm.approximatecounter.MorrisApproximateCounter - 实际计数 20000000, 近似计数 24154952
```

[MorrisApproximateCounter.java](https://github.com/coolbeevip/tutorials/blob/master/algorithm/morris-approximate-counter/src/main/java/org/coolbeevip/algorithm/approximatecounter/MorrisApproximateCounter.java)
