# MoonSynthesis

MoonSynthesis 是用 MoonBit 实现的独立研究汇总数据 Meta 分析库，另提供 JSON 批处理命令。输入每项研究的效应与采样方差，或连续/二分类结局的两组摘要；输出合并效应、区间、异质性、敏感性结果和可交换报告。运行库只依赖 MoonBit 标准库，不调用 Python 或远程统计服务。

## 适用任务

- 系统综述分析者把各研究两组均值、标准差和样本量转换为均值差，再合并并报告不确定性。完整流程见 `examples/quickstart`。
- 研究复现或测量平台接收相互独立的效应记录，重新拟合留一法、按输入顺序累积的结果及预先定义亚组。完整流程见 `examples/sensitivity`。
- 科研报告软件把两组事件数转换为 log RR / log OR，通过稳定 JSON 协议得到结构化统计量、CSV 表格和无主动内容的 SVG 森林图。完整流程见 `examples/binary` 和 `examples/request.json`。

这些功能要求效应方向、量纲、结局定义和采样单位可比较；输入层只能检查数据结构，不能证明研究独立性或可合并性。

## 环境与安装

比赛编译器下限为 `moonc 0.10.16`；本项目使用当前属性语法，要求 `moonc >= 0.10.20`。交付测试使用官方 `moonc v0.10.20+65efd5b93 (2026-11-05)`；建议使用当前官方工具链。核心库和三个示例支持 wasm-gc、wasm、JS、native，批处理 stdin/文件适配器需要 Node.js 22+。Python 只用于独立开发验证。

在自己的模块中固定安装本次版本：

```sh
moon new synthesis-consumer --user example
cd synthesis-consumer
moon add 2200732518gjy/moonsynthesis@0.1.1
```

此处样例仅在测试中调用依赖，在消费包的 `moon.pkg` 中加入测试专用导入：

```moonbit
import { "2200732518gjy/moonsynthesis" @synthesis } for "test"
```

消费包的最小测试文件 `synthesis_test.mbt`：

```moonbit
test "pool independent studies" {
  let studies = [
    @synthesis.study("a", 0.1, 0.02),
    @synthesis.study("b", 0.2, 0.03),
    @synthesis.study("c", 0.5, 0.04),
  ]
  let result = @synthesis.analyze(studies)
  assert_eq(result.count, 3)
  assert_true(result.pool.variance() > 0.0)
  println(result.to_json().stringify())
}
```

执行 `moon test --target wasm-gc --deny-warn`。安装的是 `0.1.1`，无须 GitHub 凭据或 MoonCakes token。

## 从源码快速运行

```sh
git clone https://github.com/2200732518gjy/moonsynthesis.git
cd moonsynthesis
git checkout v0.1.1
moon run examples/quickstart --target wasm-gc
moon run examples/sensitivity --target wasm-gc
moon run examples/binary --target wasm-gc
moon build --target js --release --deny-warn
node tools/synthesis.mjs examples/request.json
```

最后一个命令返回一份 JSON。`results.summary.pool.estimate` 约为 `0.3601137463`，`tau2` 约为 `0.0579425008`，另含其余六种输出。也可用 `node tools/synthesis.mjs < examples/request.json` 从 stdin 读取。适配器只读指定文件或 stdin，结果写 stdout；请求不能选择输出文件路径。解析和统计错误返回 `ok:false`，进程退出码仍为 0；IO、无效 UTF-8、超大输入或未构建等主机错误退出 2 并写 stderr。

## 算法与 API

`study(id, effect, variance, group=...)` 中 `variance` 是方差，不能传标准误；标准误需先平方。`Study` 和 `Pool` 的内部数组受保护，`weights()` 返回副本。

| 入口 | 实现与解释 |
| --- | --- |
| `fixed` / `random_dl` / `random_pm` | 固定逆方差、非负 DL、括区间二分求解 PM 的 Q(tau²)=k-1 |
| `analyze` | 默认 PM + `ModifiedHK`；可指定 `model=DL`、`inference=Normal`、`alpha=0.05` |
| `heterogeneity` | 固定权重 Cochran Q、df、I² 比例、H²；Q=0 时 I²=0、H²=0 |
| `mean_difference` / `hedges_g` | 独立连续两组；Hedges J=1-3/(4df-1)，方差 N/(nt·nc)+g²/[2(N-3.94)] |
| `log_odds_ratio` / `log_risk_ratio` | 独立二分类两组；默认零单元报错，显式 `correction=HalfIfZero` 才加半 |
| `leave_one_out` / `cumulative` | 每个子集都重新拟合 tau²；累积顺序就是输入顺序，不自动按日期排序 |
| `subgroups` | 每组重新拟合；组间 Q 使用固定权重 Q 总和减组内 Q，不输出交互 p 值 |
| `summarize_studies` | 研究正态区间、归一化权重、按 sqrt(v+tau²) 标准化的描述性残差 |
| `render_csv` / `render_forest` | CSV 固定十列，SVG 使用输入的加性效应尺度 |
| `exponentiate_interval` | 调用者显式把 log 尺度区间转为比值，拒绝溢出/下溢 |

固定模型必须使用 `Normal`。普通区间为 z×sqrt(合并方差)；保守修正 HKSJ 为 t(k-1)×sqrt(合并方差×max(1,Q残差/(k-1)))，并非未经修正的 HKSJ。随机模型且 k>=3 时，预测区间使用 t(k-2)×sqrt(tau²+已选区间方法的标准误²)，这是常规近似，并非覆盖率保证。固定模型或 k=2 时 `prediction` 为 None，派生 JSON 会省略该字段。研究自己的区间始终使用采样方差与正态分位数。I² 是 0..1 比例；Q 没有 p 值。

两组连续数据要求各 n 为 2..100000000、SD 非负；合成方差须正。二分类要求 0<=events<=total<=100000000 且 total>=1；双方同时零事件或同时全事件一律拒绝。加半仅在任一单元为零时对四个单元都加 0.5，因此两组总数各加 1；这个策略并不声称消除稀有事件偏差。

## JSON 协议 v1

```json
{"version":1,"model":"pm","inference":"modified-hk","alpha":0.05,"outputs":["summary","studies"],"studies":[{"id":"a","effect":0.1,"variance":0.02},{"id":"b","effect":0.2,"variance":0.03}]}
```

`version` 必填且为 1；`model` 为 `fixed|dl|pm`，默认 pm；`inference` 为 `normal|modified-hk`，默认随机模型 modified-hk、固定模型 normal。输出可选 `summary|studies|leave-one-out|cumulative|subgroups|csv|svg`，默认 summary，重复值和未知字段均拒绝。

每条研究默认 `kind:"direct"`，字段为 `id,effect,variance,group?`。`kind:"md"` 或 `"hedges-g"` 使用 `treatment,control` 两个对象，各含 `n,mean,sd`；`kind:"log-or"` 或 `"log-rr"` 两个对象各含 `events,total`，还可显式指定 `correction:"none"|"half-if-zero"`。同一请求不得混合 kind。`group` 默认空串，做亚组分析时所有标签必须非空，每组至少两项，至少两个组。直接库调用者自行确保量纲一致。

成功返回 `{"ok":true,"version":1,"results":{...}}`；失败为 `{"ok":false,"version":1,"error":{"code":"invalid_input","message":"..."}}`。一次输出失败则整份请求失败，不返回不完整的成功结果。详见 [协议与安全](docs/protocol-security.md)。

## 边界与数值限制

- 每次基本拟合 2..512 项，研究 ID 唯一且非空；ID/组名各不超过 256 个 UTF-16 单元。留一法要求 3..64 项，累积最多 128 项。亚组要求至少 4 项。
- alpha 在 [0.0001,0.5]，效应有限、方差有限且正。正态分位数使用 Acklam 有理近似；Student t 使用 Lanczos、正则 beta 连分式与二分。差分检查容差写在验证脚本中，不是任意极端输入的精度保证。
- 使用缩放权重减少 1/v 溢出，但极端动态范围、中间量溢出、合并方差下溢和无法表示的区间都会报错；不承诺处理所有有限 Double 的组合。
- 请求最大 1048576 个 UTF-16 单元、嵌套深度 16，重复 JSON 键拒绝；Node 入口更严格限制为 1048576 字节并要求有效 UTF-8。
- CSV 使用 CRLF、全字段引号及双引号转义；危险文本前缀加单引号，因此不是标签的无损存档。SVG 只含静态图形和转义文本，禁用 XML 非法控制字符；很长标签显示序号，完整值保留在 title。长图不分页。
- 不支持相关研究、多变量/网络 Meta、Meta 回归、出版偏倚诊断、个体层因果推断、序贯检验或研究检索；不输出医疗、政策或业务决策建议。

## 检查与独立验证

```sh
moon info
moon fmt --check
moon check --target wasm-gc --deny-warn
moon test --target wasm-gc --deny-warn
moon build --target wasm-gc --deny-warn
moon build --target js --release --deny-warn
python tools/verify_workflows.py
python -m pip install -r tools/oracle-requirements.txt
python tools/verify_oracle.py
```

把 wasm-gc 换为 wasm、js、native 可检查其它后端。native 测试/构建需要 C 工具链。CI 在 Linux 对四个后端执行严格检查、构建、测试和三个示例；另执行 JS 协议回归、固定种子独立数值差分和格式检查。差分脚本检查 228 次拟合：36 组直接效应×5 个模型/区间组合，以及 12 组×4 种摘要转换。DL/效应转换参考 statsmodels 0.14.5，PM 参考 SciPy 独立括区间求根，正态/t 区间参考 SciPy 分布；不把参考库自身边界行为当作数学真值。见 [验证说明](docs/verification.md)。

## 结构、许可与来源

根目录 `.mbt` 是实际统计、协议和报告引擎；`cmd/protocol` 是可移植入口；`tools/synthesis.mjs` 仅负责 Node IO；`examples` 是三种下游工作流；[架构](docs/architecture.md) 说明数据流。

本项目为原创实现，采用 [MIT](LICENSE)。运行依赖 MoonBit core；成熟统计公式和参考实现仅用于设计/验证，不捆绑第三方统计源码。来源、参考约定差异与 AI 使用披露见 [ATTRIBUTION.md](ATTRIBUTION.md)。查重记录见 [语义边界](docs/competition/duplicate-check.md)。[CHANGELOG.md](CHANGELOG.md) 记录本次发布能力。AI 参与了选题研究、代码、文档和测试编写；正确性依赖可复现验证，仍可能存在未覆盖问题。
