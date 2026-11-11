# 可复现验证方法

运行 README 的命令即可执行本地单元与回归，独立差分依赖固定版本 requirements。生产库无需这些 Python 包。`verify_oracle.py` 固定随机种子 20261111：36 组直接输入，各比较固定正态、DL 正态、DL 修正 HK、PM 正态、PM 修正 HK；12 组两臂数据，各比较 MD、Hedges g、log OR、log RR，共 228 次完整拟合。

比较量包括 tau²、合并估计/方差/残差 Q、Q/I²、标准误、区间和研究权重。统计量按 max(1,abs(reference)) 归一误差容差 2e-8，区间 3e-6；这是所列样本的测试容差，不能推导任意输入上界。PM 使用 SciPy 的维度缩放 brentq 解同一估计方程，避免 statsmodels 0.14.5 的迭代在微小负残差处归零；该参考差异及最初失败保存在开发者的本地验收证据中。statsmodels 在零异质性/负 DL 的内部派生量上可能发出运行警告，脚本仅使用其 Q 和 DL 原始矩估计，再按本项目非负策略重算权重；不压制未知错误。

标准库集成脚本 `verify_workflows.py` 真正从 Node 入口读取 stdin/文件：检查七类结果、累积末项等于完整拟合、留一法数量、CSV 解析、SVG XML 解析、恶意标签、重复键/无效 JSON、无效 UTF-8、超大输入及退出码。

原生后端要求 C 工具链；Windows 本地如仅能检查则以 Linux CI 的实际 native 测试/构建/示例结果补足。GitHub Actions 必须对应发布 SHA，不能用旧成功替代。未测吞吐、覆盖率、临床覆盖率或与其它软件的性能差异，因此不声明这些指标。

中文 README 的导入和最小测试通过 `python tools/verify_readme.py` 在独立 workspace 中逐字提取检查；这项发布前检查使用本地候选源码，发布后还须用无 token、无缓存的消费者安装精确注册版本。
