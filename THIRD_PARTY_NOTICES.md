# 第三方声明

## Apache Commons Math Lanczos 系数表

`probability.mbt` 使用 Apache Commons Math 3.6.1 `org.apache.commons.math3.special.Gamma` 中的 Lanczos 系数表及对应参数化。MoonBit 函数由本项目独立编写，没有复制其 Java 源码文本。

- 上游项目：Apache Commons Math 3.6.1
- 来源文件：https://github.com/apache/commons-math/blob/MATH_3_6_1/src/main/java/org/apache/commons/math3/special/Gamma.java
- 许可：Apache License 2.0；本仓库 `LICENSE-APACHE-2.0` 提供许可全文。
- 版权归属：Copyright 2001-2016 The Apache Software Foundation。

本项目沿用的适用上游 NOTICE 归属声明：

> Apache Commons Math. Copyright 2001-2016 The Apache Software Foundation. This product includes software developed at The Apache Software Foundation (http://www.apache.org/).

此处仅复现适用于所用类的通用 NOTICE 归属；Commons Math 中与 Gamma 类无关的 Orekit、Minpack 等第三方组件未被使用。上述来源声明不改变本项目原创代码的 MIT 许可。BCG 数据/参考快照另按 `fixtures/metafor-bcg/COPYING` 与该目录 README 中说明的 GPL-2.0-or-later 分发；其他算法参考与 AI 使用说明见 `ATTRIBUTION.md`。
