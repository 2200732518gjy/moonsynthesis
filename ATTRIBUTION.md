# 来源与 AI 使用说明

原创 MoonBit 工程；未移植、粘贴或捆绑下述项目的源代码。公式、算法与数值常数的实现为本工程编写，参考方案用于定义可核验语义。运行依赖 moonbitlang/core（Apache-2.0，按其发布许可证使用）；本工程 MIT 许可证不替代依赖许可证。

- statsmodels 0.14.5 `statsmodels.stats.meta_analysis`（BSD-3-Clause）：固定/DL 逆方差合并、Hedges 标准化均值差和二分类 log 比值的数值参考。Hedges 方差明确采用其 N-3.94 约定。DL 负 tau² 在本工程截为零。参考源码不进入发布包。
- SciPy 1.16.2（BSD-3-Clause）：测试依赖，用其 brentq 独立求解 PM 方程，并以 norm/t 分布核对区间。生产代码不依赖 SciPy。
- Paule–Mandel 估计方程、DerSimonian–Laird 矩估计、Cochran Q 与 I² 为通用统计方法。本项目的 modified HK 用 max(1,Q/df) 的保守修正；不声称等同其它软件全部 HKSJ 变体。
- Peter J. Acklam 的逆正态有理近似数值系数、Lanczos log-gamma 数值系数及不完全 beta 连分式用于分位数计算。这里使用的是数学方法和数值常数，不包含第三方软件源码文本。

参考入口：
- https://www.statsmodels.org/v0.14.5/generated/statsmodels.stats.meta_analysis.combine_effects.html
- https://github.com/statsmodels/statsmodels/blob/v0.14.5/statsmodels/stats/meta_analysis.py
- https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.brentq.html
- https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.t.html

AI 参与需求研究、选题查重、代码/测试/文档编写及验收修复。开发验收包含严格多后端测试、三种实际工作流、恶意标签/有界输入回归和固定种子独立差分。AI 输出和测试均不能证明没有缺陷，项目不提供临床或其它决策结论。
