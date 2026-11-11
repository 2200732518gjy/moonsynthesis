# 选题与语义查重（2026-11-11）

执行已安装 osc2026-guide 的 Project Research Guide：moon search（每词上限100）、MoonCakes 精确版本文档及源码ZIP、GitHub 仓库/代码查询（per_page=100）、moonbitlang/awesome-moonbit 全文、moonbit-community 仓库分页和本机永久登记的完整能力指纹。检索不是官方裁决；索引可能漏检，不能证明绝对唯一。

## 需求与选择

MoonSynthesis 接收独立研究的汇总效应/方差，输出合并估计、研究间异质性、留一法/累计/分组敏感性结果。系统综述分析者需要对多个研究结果进行可复现合并；实验平台需要在不交换个体记录时汇总独立实验；研究软件作者需要在WASM/JS/原生共享分析模型。以上是成熟实践支持的任务推断，没有声称访谈或真实采用。成熟行为参照为 statsmodels.stats.meta_analysis（BSD-3-Clause）和 R metafor，而非编造用户经验。

三个完整流程：连续/二分类研究汇总→效应量及方差→固定、DL/PM随机效应与区间；独立研究effect/variance→Q/I²和子组合并→结构化报告；有顺序研究→累计与留一重拟合→敏感性表/森林图。仅处理独立、同一量纲的单变量研究，不实现个体因果推断、网络meta、meta回归或决策建议。

## 候选矩阵

评分1–5：广度/用户/复用/重合安全/深度/验证/可行性/维护。

|不同领域候选|成熟依据|检索与实际近邻|评分|裁决|
|---|---|---|---|---|
|空间克里金插值|PyKrige/gstat|JIA2JIA2/moonbitgeodb@0.1.6：lib/geo/kriging.mbt、kriging_test.mbt、README及GeoDB接口，已有变异函数拟合、普通/KNN克里金；Mostan-303/moonbit-cog@0.2.0已有变异函数与IDW|5/4/5/1/4/5/4/4|直接成熟替代，淘汰|
|寿险生命表与保单现值|传统精算生存与交换函数模型|hua1104/moonactuary@0.1.1：README、valuation/insurance源码与测试，已有保费、准备金、多法核对|4/4/4/1/4/5/4/4|直接成熟替代，淘汰|
|RF Touchstone交换与网络分析|Touchstone/scikit-rf|guolei-dev/touchstone@0.2.1：README、公开接口、矩阵/分析实现及测试，已有S/Y/Z转换、级联、去嵌|5/4/5/1/5/5/3/4|直接成熟替代，淘汰|
|独立研究Meta分析|statsmodels combine_effects、metafor|详见下表；有邻近统计原语，未发现同核心的成熟替代|5/4/5/4/5/5/4/4|通过有界查重，自动选中|

硬失败不能以总分抵消。先前MoonWell、MoonBench、MoonContract、MoonRecur、MoonShard及登记中的保留项目全部排除；本项目不读取、改名或复用它们的实现。

## 选中题目的能力比较

|近邻与版本|实际审阅|核心输入与输出|与选题关系、独立必要性|
|---|---|---|---|
|pla678889/moon-experiment@0.2.3|README、stratified/mantel_haenszel.mbt、接口及测试|单个实验/分层人数→检验、分层共同RR|高度相邻统计原语；不再实现MH分层。跨研究已知方差和tau²重拟合不适合替换其实验生命周期模型|
|structuraBlock/MoonStats@0.3.0|README、接口、分布/统计源码及测试|一般数列→描述统计与检验|通用数学，不是独立研究合并状态；可扩展但新建明确研究记录模型避免混入通用统计接口|
|qjgqjg/moon-causal@0.2.5|inference_diagnostics_advanced.mbt、接口、质量测试|个体处理/结局或分组估计→因果推断和异质性摘要|没有发现DL/PM研究间tau²、HKSJ与研究留一重拟合；个体识别与研究综合职责不同|
|paipai-Studio/BioSeqs|variance_partition.mbt、dreamlet/variance_partition测试、例子|基因/样本混合效应→方差分量/BLUP|random_effects代码命中实际为样本层次混合模型，不是已知研究内方差的汇总分析|

查询扩展包含meta-analysis、metaanalysis、meta_analysis、metafor、Cochran、DerSimonian、Paule Mandel、Mantel Haenszel、pooled effect、effect_size、heterogeneity、statistics；淘汰域含kriging/geostatistics/variogram/PyKrige/gstat/ordinary_kriging/空间插值、actuary/life insurance/commutation/寿险、touchstone/s-parameter/two port。核心API反查random_effects、cochran_q、funnel_plot、DerSimonian。Moon search statistics达到100条上限，明确存在截断；其余结果按实际返回检查。GitHub搜索零条只作辅助，实际源审阅优先。

GitHub带内嵌引号的一次查询参数传递失败，已用等价无内嵌引号查询完成；最初研究桥缺少显式目标/数组类型的本地拒绝已修复，未发远端写入。raw.githubusercontent.com一次连接重置，官方清单改通过已绑定GitHub API读取，并未修改系统代理或账号。MoonCakes页面HTML可读，但判断能力依据真实源码ZIP，不把SPA HTTP200视为功能证明。

## 公开来源与限制

- https://github.com/statsmodels/statsmodels/tree/main/statsmodels/stats/meta_analysis.py
- https://www.metafor-project.org/
- https://github.com/moonbitlang/awesome-moonbit
- https://mooncakes.io/docs/JIA2JIA2/moonbitgeodb@0.1.6/
- https://mooncakes.io/docs/hua1104/moonactuary@0.1.1/
- https://mooncakes.io/docs/guolei-dev/touchstone@0.2.1/
- https://mooncakes.io/docs/pla678889/moon-experiment@0.2.3/
- https://mooncakes.io/docs/structuraBlock/MoonStats@0.3.0/
- https://mooncakes.io/docs/qjgqjg/moon-causal@0.2.5/
- https://github.com/paipai-Studio/BioSeqs

实现前已排他锁定并重读登记，原子追加预留；不覆盖并发记录。原始响应、命令退出码、下载摘要、源码摘录留在仓库外证据目录。交付前须再做行为反查。结论限于上述日期、索引、分页与可见仓库。
