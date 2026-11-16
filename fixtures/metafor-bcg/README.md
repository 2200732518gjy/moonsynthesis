# BCG 公开数据与数值基准

本目录的 `reference.json` 使用 metadat **1.4-0** 的 `dat.bcg`（13 项 BCG 研究），
由 R 4.5.1 / metafor **4.8-0** 实际计算，不是 MoonSynthesis 自行生成的预期值。
`data` 中保留两组事件/非事件数、发表年份 `year`、绝对纬度 `ablat` 和分配方式；
`yi` 为 log RR，`vi` 为采样方差。它们是教学/复现数据，不是医学建议。

- 数据文档：https://wviechtb.github.io/metadat/reference/dat.bcg.html
- 数据源：Colditz et al. (1994), JAMA 271(9), 698–702，DOI 10.1001/jama.1994.03510330076038。
- Meta 回归参考：Berkey et al. (1995), Statistics in Medicine 14(4), 395–411，DOI 10.1002/sim.4780140406。
- 包版本源码：https://cran.r-project.org/src/contrib/Archive/metadat/metadat_1.4-0.tar.gz
- 参考实现：https://cran.r-project.org/src/contrib/Archive/metafor/metafor_4.8-0.tar.gz
- 模型说明：https://wviechtb.github.io/metafor/reference/rma.uni.html

metadat 的上述版本声明 GPL (>= 2)。为保守保留来源约束，本目录的数据快照及派生参考值
按 **GPL-2.0-or-later** 分发，完整文本见 `COPYING`；数据整理来源归属 Wolfgang Viechtbauer / metadat 作者。
根目录 MIT 许可证适用于原创 MoonBit 与工具代码，不替代本目录的独立许可。
没有移植或链接 metafor 的 R 源码；R/统计包只是开发期参照，不是生产依赖。

## 重建与验证

在独立 R 环境安装 metadat 1.4-0、metafor 4.8-0（CRAN Archive）及 jsonlite，执行：

```sh
Rscript tools/reference_metafor.R fixtures/metafor-bcg/reference.json
moon build --target js --release --deny-warn
python -m pip install -r tools/oracle-requirements.txt
python tools/verify_modeling.py
```

脚本明确校验包版本，拟合截距、纬度、纬度+年份三种 REML 模型，分别计算 `z` 和
`adhoc`（保守 modified-HK）推断。`QE` 是 tau²=0 时的残差异质性检验量，
`residual_q` 是估计 tau² 后的加权残差平方和，二者不可混用。
回归输入从原始两组事件数经生产 log-RR 入口转换；测试比较 tau²、系数、SE、协方差、
区间及预测均值。预测区间单独按文档的 t(k-p-1) 近似用 SciPy 核对，不冒称与 metafor 默认 PI 定义相同。
新参考值的末位可能随 BLAS/R 版本轻微变化；容差写在验证脚本中。
