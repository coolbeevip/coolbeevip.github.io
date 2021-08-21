---
title: "Approximate Counting Morris Algorithm in Java"
date: 2021-08-21T00:24:14+08:00
tags: [counter,memory-efficient,approximation]
categories: [algorithm]
draft: false
---

这是一个莫里斯计数器（近似计数算法）的 Java 实现，用很小的数据结构准确估计具有几十亿数据量的数据计数。

我们通常会定义一个 Long 类型对象，通过累加的方式实现计数。每个 Long 类型占用 8 byte (64bit) 空间，如果你有 30 亿个要记录的对象，那么你就需要 22GB 的空间存储这些计数器，这还不不包括在哈希中的对象ID。

例如我们记录网页的访问数量，并给出热点排名，如果我们面对的是每天有数十亿的访问场景，那么十亿和十亿零几千万差别并不大。这时我们往往不需要精确计数，如果我们只需要得到计数的近似值，并且使用一个小的数据结构( 例如 1 byte) 作为计数器，那么我们只需要大概 2GB 的空间就足够了。

以下样例代码中，我们使用 1 byte (8bit) 的变量，实现千万级的计数

![algorithm-morris-approximate-counter](/images/posts/algorithm/algorithm-morris-approximate-counter/algorithm-morris-approximate-counter.png)

[MorrisApproximateCounter.java](https://github.com/coolbeevip/tutorials/blob/master/algorithm/morris-approximate-counter/src/main/java/org/coolbeevip/algorithm/approximatecounter/MorrisApproximateCounter.java)

```java
public class MorrisApproximateCounter {

  private static final Logger log = LoggerFactory.getLogger(MethodHandles.lookup().lookupClass());

  /**
   * 底数使用欧拉常数或者2
   */
  double radix = 2.718;

  /**
   * 定义一个计数器变量
   */
  byte counter = 0;

  /**
   * 模拟抛硬币概率
   */
  Random random = new Random();

  /**
   * 返回计数值
   */
  public double get() {
    return Math.pow(radix, counter);
  }

  /**
   * 计数值累加
   */
  public byte increment() {
    if (this.counter < 255 && random.nextDouble() < Math.pow(this.radix, -this.counter)) {
      this.counter++;
    }
    return this.counter;
  }

  public static void main(String[] args) {
    MorrisApproximateCounter mc = new MorrisApproximateCounter();

    // 定义实际数量
    int realCount = 2_000;

    double[][] real_graph_data = new double[realCount][2];
    double[][] approximate_graph_data = new double[realCount][2];

    for (int n = 0; n < realCount; n++) {
      // 累加计数
      mc.increment();

      real_graph_data[n][0] = n;
      real_graph_data[n][1] = n;

      approximate_graph_data[n][0] = n;
      approximate_graph_data[n][1] = mc.get();
    }

    // 输出实际计数 和 近似计数
    log.info("实际计数 {}, 近似计数 {}", realCount, (int) mc.get());

    // 绘制图形
    LineChartFrame chart = new LineChartFrame("Algorithm", "Morris Approximate Counting Algorithm", "n","counter");
    chart.addXYSeries("real count",real_graph_data);
    chart.addXYSeries("approximate count",approximate_graph_data);
    chart.pack();
    chart.setVisible(true);
  }
}
```

执行结果，因为采用随机概率，所以每次估算的近似值都不同，有的时候误差还较大，如何减少这种误差？

```shell
实际计数 2000, 近似计数 1095
```

使用是一个小型数组结构，通过哈希定位索引存储多个计数器，可以参考 [MorrisApproximateHashCounter.java](https://github.com/coolbeevip/tutorials/blob/master/algorithm/morris-approximate-counter/src/main/java/org/coolbeevip/algorithm/approximatecounter/MorrisApproximateHashCounter.java)

参考

[Approximate_counting_algorithm](https://en.wikipedia.org/wiki/Approximate_counting_algorithm)