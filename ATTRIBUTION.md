# 来源与 AI 使用说明

原创 MoonBit 工程；未移植、粘贴或捆绑下述项目的源代码。统计公式与算法由本工程编写；log-gamma 使用明确标注来源的 Apache Commons Math Lanczos 系数表。参考方案用于定义可核验语义。运行依赖 moonbitlang/core（Apache-2.0，按其发布许可证使用）；本工程 MIT 许可证不替代依赖许可证。

- statsmodels 0.14.5 `statsmodels.stats.meta_analysis`（BSD-3-Clause）：固定/DL 逆方差合并、Hedges 标准化均值差和二分类 log 比值的数值参考。Hedges 方差明确采用其 N-3.94 约定。DL 负 tau² 在本工程截为零。参考源码不进入发布包。
- SciPy 1.16.2（BSD-3-Clause）：测试依赖，用其 brentq 独立求解 PM 方程，并以 norm/t 分布核对区间。生产代码不依赖 SciPy。
- Paule–Mandel 估计方程、DerSimonian–Laird 矩估计、Cochran Q 与 I² 为通用统计方法。本项目的 modified HK 用 max(1,Q/df) 的保守修正；不声称等同其它软件全部 HKSJ 变体。
- Peter J. Acklam 的逆正态有理近似用于分位数计算。其原始说明明确允许算法及所列实现用于任何目的，并请求适当致谢；本项目采用独立 MoonBit 实现并在此归属。归档来源：https://web.archive.org/web/20151030215612/http://home.online.no/~pjacklam/notes/invnorm/ 。
- log-gamma 使用 Apache Commons Math 3.6.1 `Gamma` 所载 Lanczos 系数表与对应参数化，独立以 MoonBit 表达；适用 Apache-2.0 许可副本及来源见 `LICENSE-APACHE-2.0` 和 `THIRD_PARTY_NOTICES.md`。

参考入口（均为开发/验证来源，不作为运行时源码依赖）：
- https://www.statsmodels.org/v0.14.5/generated/statsmodels.stats.meta_analysis.combine_effects.html
- https://github.com/statsmodels/statsmodels/blob/v0.14.5/statsmodels/stats/meta_analysis.py
- https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.brentq.html
- https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.t.html

AI 参与需求研究、选题查重、代码/测试/文档编写及验收修复。开发验收包含严格多后端测试、三种实际工作流、恶意标签/有界输入回归和固定种子独立差分。AI 输出和测试均不能证明没有缺陷，项目不提供临床或其它决策结论。


## 0.2.0 REML / Meta 回归与公开数据

REML 得分、研究层混合效应回归和保守 modified-HK 的方法约定参考 metafor 文档：
https://wviechtb.github.io/metafor/reference/rma.uni.html 。原创 MoonBit 以加权 QR、杠杆值迹和括根求解实现，未复制或移植 R 实现源码。
开发期运行 R/metafor 4.8-0 与 metadat 1.4-0 建立独立数值基准；metadat 1.4-0 的已归档 CRAN DESCRIPTION 声明 GPL (>=2)，metafor 只作为开发期计算器，未复制或链接其源码；它们均不作为生产依赖。
BCG 数据及派生参考快照独立按 GPL-2.0-or-later 放在 fixtures/metafor-bcg，附来源和 COPYING；根代码仍为 MIT。
AI 参与了这次算法实现、差分测试和文档，正确性依据可复现的公开基准及回归，不依据 AI 的判断。
