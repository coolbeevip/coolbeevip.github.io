---
title: "Approximate Counting Morris Algorithm in Java"
date: 2021-08-21T00:24:14+08:00
tags: [counter,algorithm]
categories: [algorithm]
draft: false
---

这是一个莫里斯计数器（近似计数算法）的 Java 实现，用很小的数据结构准确估计具有几十亿数据量的数据计数。

我们通常会定义一个 Long 类型对象，通过累加的方式实现计数。每个 Long 类型占用 8 byte 空间，如果你有 30 亿个要记录的对象，那么你就需要 22GB 的空间存储这些计数器，这还不不包括在哈希中的对象ID。
如果我们只需要得到计数的近似值，并且使用一个小的数据结构( 例如 1 byte) 作为计数器，那么我们只需要大概 2GB 的空间就足够了。

以下样例代码中，我们使用 1 byte (8bit) 的变量，实现千万级的计数

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
实际计数 20000000, 近似计数 24154952
```

[MorrisApproximateCounter.java](https://github.com/coolbeevip/tutorials/blob/master/algorithm/morris-approximate-counter/src/main/java/org/coolbeevip/algorithm/approximatecounter/MorrisApproximateCounter.java)
