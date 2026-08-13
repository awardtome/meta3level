# meta3level 0.6.2 完整中文使用说明书

## 1. 软件定位

`meta3level` 用于在 R 中运行三水平元分析和普通随机效应元分析。它不是新的
统计估计器，而是把 `metafor` 等包的常用步骤组织成简短、可审查、可重复的
`m3*` 函数。

本包支持：

- 相关系数 `r`；
- Cohen's `d` 与 Hedges' `g`；
- 优势比 `OR`；
- 研究者已计算好的自定义 `yi` 与抽样方差 `vi`；
- 三水平主效应、多层 I² 和方差成分单侧 LRT；
- 连续、分类及自然样条调节效应；
- 普通随机效应元分析及研究内效应量 GLS 合并；
- Egger、PET-PEESE、trim-and-fill 及补充发表偏误诊断；
- leave-one-effect-out 和 leave-one-study-out；
- 森林图、调节图、样条图、漏斗图和敏感性折线图；
- 控制台完整输出、底层 R 复现代码和安装包函数源码。

## 2. 安装

### 2.1 从 GitHub 安装

从 GitHub 安装：

```r
install.packages("remotes")
remotes::install_github(
  "awardtome/meta3level",
  dependencies = NA,
  upgrade = "never"
)
library(meta3level)
```

### 2.2 从 Release 源码包安装

```r
install.packages("metafor")
install.packages(
  "meta3level_0.6.2.tar.gz",
  repos = NULL,
  type = "source"
)
library(meta3level)
```

在 RStudio 中也可依次选择 **Tools → Install Packages → Install from:
Package Archive File**，再选择 `.tar.gz` 文件。

### 2.3 可选依赖

```r
install.packages(c(
  "readxl",    # Excel
  "openxlsx",  # Excel 导出
  "meta",      # Copas 辅助对象
  "metasens",  # Copas
  "puniform",  # p-uniform
  "zcurve"     # z-curve
))
```

只有调用相应功能时才需要可选包。核心三水平分析主要依赖 `metafor`。

### 2.4 验证安装

```r
library(meta3level)
packageVersion("meta3level")
help(package = "meta3level")
```

期望版本为 `0.6.2`。

## 3. 最短工作流程

所有分析都遵循四步：读取、准备效应量、运行、提取或作图。

```r
library(meta3level)

raw <- m3read("编码文件.xlsx", sheet = 1)

dat <- m3prep(
  raw,
  measure = "r",
  study = "studyID",
  effect = "effectID",
  value = "r",
  n = "样本量"
)

result <- m3run(
  dat,
  cont = c("平均年龄", "出版年份"),
  groups = list(
    var = "研究设计",
    ref = "横向",
    name = "横向/纵向"
  ),
  spline = list(
    var = "平均年龄",
    df = 1:3,
    name = "平均年龄"
  ),
  bias = TRUE,
  leave = TRUE,
  level = "three",
  show = TRUE,
  keep = TRUE,
  code = FALSE
)
```

`show = TRUE` 将全部结果打印在控制台。`keep = TRUE` 表示某个可选分析失败时
继续运行其他组件，并把错误原因存入该组件的 `$message`；主模型失败仍会停止。

## 4. 数据编码规则

### 4.1 一行代表什么

一行应代表一个效应量。最少包含：

| 字段 | 要求 |
|---|---|
| 研究 ID | 表示统计上独立的样本，而不只是论文编号。 |
| 效应量 ID | 同一研究内唯一；没有该列时可由程序按原始行号生成。 |
| 效应量输入 | `r`、`d`、`g`、`OR`、四格表或自定义 `yi`。 |
| 不确定性输入 | 样本量、组别样本量、CI、SE、四格表或 `vi`。 |

一篇论文包含两个独立样本时，应使用两个 `studyID`。同一样本报告多个结果时，
这些行共享一个 `studyID`，但具有不同 `effectID`。

### 4.2 三水平模型何时适用

三水平模型要求至少两个独立研究，并且至少一个研究贡献多个效应量。更稳妥的
情况是有多个研究包含重复效应。若每项研究只有一个效应量，应使用
`level = "single"`。

### 4.3 缺失与非法值

- 不要用 `0` 代表缺失，除非 0 确实有含义。
- `studyID + effectID` 组合必须唯一。
- 相关系数必须满足 `|r| < 1`，且 `n > 3`。
- 抽样方差必须大于 0。
- 连续变量中不能混入无法解释的文字。
- 分类变量的实际取值必须与 `ref` 完全匹配。

`m3prep()` 会打印或警告被删除的非法行。分析报告中应保留这一数据筛选记录。

### 4.4 百分比变量

女性占比等变量可使用 0–1 比例或 0–100 百分点，但同一列应保持一致。包可以
识别部分带 `%` 的混合写法；若 `1` 既可能表示 1% 又可能表示 100%，程序会
停止，要求研究者先统一尺度。

## 5. 读取数据：`m3read()`

### 5.1 Excel

```r
raw <- m3read(
  file = "G:/项目/编码表.xlsx",
  sheet = 1
)
```

`sheet` 可用工作表序号或名称。

### 5.2 CSV、TSV 与文本文件

```r
raw <- m3read(
  file = "G:/项目/编码表.csv",
  encoding = "auto"
)
```

`encoding = "auto"` 会尝试 UTF-8、GB18030 和 GBK；分隔符会在逗号、分号和
制表符之间自动判断。小数逗号文件应设置：

```r
raw <- m3read("data.csv", decimal = ",")
```

### 5.3 读取后必须检查

```r
dim(raw)
names(raw)
head(raw)
str(raw)
attr(raw, "meta3_source")$name_map
```

`m3read()` 可能保留文本型数字列，以避免在导入阶段悄悄改变原始编码。`m3prep()`、
`m3cont()` 和 `m3spline()` 会按记录的小数点设置解析所需数值；若要在包外自行做
算术运算，应先显式检查并转换，例如 `age <- as.numeric(raw$age)`。

重复表头会按原始位置修复，例如两个“热执行功能”可能变成
`热执行功能...12` 和 `热执行功能...14`。必须在后续映射中使用修复后的名称。

## 6. 准备效应量：`m3prep()`

### 6.1 相关系数 r

```r
dat <- m3prep(
  raw,
  measure = "r",
  study = "studyID",
  effect = "effectID",
  value = "r",
  n = "样本量"
)
```

模型内部使用 Fisher's z：`yi = atanh(r)`，`vi = 1/(n-3)`。总体效应、分类
组效应、预测值和敏感性结果会自动转回 `r`。

### 6.2 独立干预组与对照组 Cohen's d

```r
raw$对照组人数 <- raw$总人数 - raw$干预组人数

dat <- m3prep(
  raw,
  measure = "d",
  design = "independent",
  study = "studyID",
  effect = "effectID",
  value = "Cohens_d",
  n1 = "干预组人数",
  n2 = "对照组人数"
)
```

程序使用精确 Hedges 校正因子将 `d` 转换为 `g`，模型和报告尺度均为 `g`。
必须在所有研究中保持组别顺序和正负方向一致。

### 6.3 已计算好的 Hedges' g

```r
dat <- m3prep(
  raw,
  measure = "g",
  study = "studyID",
  effect = "effectID",
  value = "Hedges_g",
  vi = "g方差"
)
```

`vi` 必须是方差，不能填标准误。若只有标准误，应先计算：

```r
raw$g方差 <- raw$g标准误^2
```

### 6.4 单组或前后测 d/g

优先由研究设计公式计算抽样方差，并明确提供：

```r
dat <- m3prep(
  raw,
  measure = "d",
  design = "onegroup",
  variance = "known",
  study = "studyID",
  effect = "effectID",
  value = "组内_d",
  n = "干预组人数",
  vi = "组内_d方差"
)
```

若确实无法获得设计特定方差，只能把近似作为披露清楚的敏感性模型：

```r
dat <- m3prep(
  raw,
  measure = "d",
  design = "onegroup",
  variance = "approximate",
  study = "studyID",
  effect = "effectID",
  value = "组内_d",
  n = "干预组人数"
)
```

前后测效应的方差通常依赖前后测相关和标准化定义，因此不应把近似结果包装成
唯一精确分析。

### 6.5 OR 与 95% CI

```r
dat <- m3prep(
  raw,
  measure = "or",
  study = "studyID",
  effect = "effectID",
  value = "OR",
  lower = "OR下限",
  upper = "OR上限",
  conf = 0.95
)
```

### 6.6 OR 与 log(OR) 的 SE 或方差

```r
dat <- m3prep(
  raw, measure = "or",
  study = "studyID", effect = "effectID",
  value = "OR", se = "logOR标准误"
)

# 或
dat <- m3prep(
  raw, measure = "or",
  study = "studyID", effect = "effectID",
  value = "OR", vi = "logOR方差"
)
```

`se` 与 `vi` 均对应 `log(OR)`，不是原始 OR。

### 6.7 OR 的 2×2 四格表

```r
dat <- m3prep(
  raw,
  measure = "or",
  study = "studyID",
  effect = "effectID",
  cellA = "干预组事件",
  cellB = "干预组非事件",
  cellC = "对照组事件",
  cellD = "对照组非事件",
  correction = 0.5
)
```

默认只对含零格的四格表四个格子各加 0.5。事件定义和组别方向必须一致。

### 6.8 自定义 yi/vi

```r
dat <- m3prep(
  raw,
  measure = "custom",
  study = "studyID",
  effect = "effectID",
  value = "yi",
  vi = "vi"
)
```

研究者必须在论文中报告原始统计量到 `yi`、`vi` 的转换公式、方向和假设。

### 6.9 没有效应量 ID

省略 `effect`，程序会根据原始行号生成稳定 ID：

```r
dat <- m3prep(
  raw, measure = "r",
  study = "studyID", value = "r", n = "n"
)
```

## 7. 三水平主效应

```r
main <- m3fit(
  dat,
  method = "REML",
  f = TRUE,
  level = "three"
)

summary(main)
m3effect(main)
m3i2(main)
m3lrt(main)
```

核心模型等价于：

```r
metafor::rma.mv(
  yi,
  V = vi,
  random = ~ 1 | studyID/effectID,
  method = "REML",
  test = "t",
  data = dat
)
```

包内部为兼容性使用 `tdist = TRUE`，其含义是系数采用 t 检验、调节变量 omnibus
检验采用 F 参考分布。对象内部仍可能把 F 统计量存放在 `$QM` 字段，但只有模型
确实使用 t/F 推断时才能报告为 F。

### 7.1 主效应报告尺度

```r
overall <- m3effect(main)
overall
```

- `estimate_analysis`：Fisher z、g、log(OR) 或自定义分析尺度。
- `estimate_reported`：自动转回的 `r`、`g` 或 `OR`。
- `ci_lb_reported`、`ci_ub_reported`：报告尺度置信区间。

### 7.2 多层 I²

```r
i2 <- m3i2(main)
i2
```

三行通常为研究间 Level 3、研究内效应量间 Level 2 和总 I²。I² 描述总变异中
异质性所占比例。方差估计接近 0 是边界估计，不等于证明总体方差严格为 0。

### 7.3 单侧方差成分 LRT

```r
lrt <- m3lrt(main)
lrt
```

`p_one_sided` 使用边界方差检验的混合参考分布近似。应分别报告 Level 3 和
Level 2，而不是用该检验代替效应量显著性检验。

## 8. 普通随机效应元分析

若每项研究只有一个效应量，或研究者计划先合并同一研究内效应量：

```r
single <- m3run(
  dat,
  level = "single",
  rho = 0.60,
  bias = TRUE,
  leave = TRUE,
  show = TRUE
)
```

包会按研究使用 GLS 合并效应量，再运行：

```r
metafor::rma(
  yi, vi,
  method = "REML",
  test = "knha"
)
```

### 8.1 rho 的含义

`rho` 是同一研究内效应量抽样相关的假设值，不能由当前效应量表自动估计。
建议进行敏感性分析：

```r
rho_values <- c(0, 0.30, 0.60, 0.90)

rho_results <- lapply(rho_values, function(rho) {
  x <- m3run(
    dat,
    level = "single",
    rho = rho,
    bias = FALSE,
    leave = FALSE,
    show = FALSE
  )
  data.frame(rho = rho, x$main$overall)
})

do.call(rbind, rho_results)
```

### 8.2 单独研究内合并

```r
study_dat <- m3study(
  dat,
  rho = 0.60,
  keep = c("平均年龄", "研究设计")
)
```

`keep` 只能保留研究层面变量。同一研究内若值冲突，程序会停止，不会擅自平均。

## 9. 连续调节变量：`m3cont()`

```r
age <- m3cont(
  dat,
  var = "平均年龄",
  name = "平均年龄",
  level = "three"
)

print(age)
age$center
age$coefficients
age$f_test
age$i2
age$lrt
```

程序会对该变量完整案例样本计算均值，并创建 `moderator_c = 原值 - 均值`。
连续变量只拟合有截距模型，不运行无截距版本。

### 9.1 解释

- 截距：调节变量等于完整案例均值时的合并效应。
- `moderator_c` 斜率：调节变量每增加 1 个原始单位，效应量在分析尺度上的变化。
- `age$f_test`：调节效应的 F、分子自由度、分母自由度和 p 值。

相关系数模型的斜率位于 Fisher z 尺度，不能直接执行 `tanh(斜率)` 并称为
“r 每单位变化”。OR 模型斜率位于 log(OR) 尺度。应结合预测图或在有意义的
变量值处计算预测效应进行解释。

## 10. 分类调节变量：`m3group()`

```r
design <- m3group(
  dat,
  var = "研究设计",
  ref = "横向",
  name = "横向/纵向"
)

print(design)
design$reference
design$counts_effects
design$counts_studies
design$contrasts
design$group_effects
design$f_test
```

包同时拟合：

- 有截距模型：截距是参照组效应，其余系数是相对参照组的差值；F 表检验整体
  组间差异。
- 无截距模型：每个系数是相应类别的合并效应，并自动转到报告尺度。

`ref` 必须使用数据中的原始类别值。若某类别只有一个研究，该类别估计和 F
检验通常不稳定，包会警告。

## 11. 自然样条非线性检验：`m3spline()`

```r
age_curve <- m3spline(
  dat,
  var = "平均年龄",
  df = 1:3,
  linear = TRUE,
  name = "平均年龄"
)

print(age_curve)
age_curve$comparison
age_curve$minimum_ic_model
age_curve$best_model
age_curve$selection_criterion
```

候选模型使用相同完整案例和 ML，而不是 REML，以比较 `logLik`、AIC、AICc、
BIC 和 `delta`。

- `minimum_ic_model`：信息准则数值最小的模型。
- `best_model`：在 `delta <= 2` 的竞争模型中优先选择更简单模型。
- `selection_criterion`：当前优先依据 AICc 还是 AIC。

不要为了寻找显著结果无限增加 df。高 df 相对少量研究容易产生不稳定曲线，尤其
在年龄范围两端数据稀疏时。

## 12. 一次运行多个调节变量：`m3run()`

```r
result <- m3run(
  dat,
  cont = list(
    list(var = "个人主义指数", name = "个人主义指数"),
    list(var = "样本量", name = "样本量"),
    list(var = "女性占比", name = "女性占比"),
    list(var = "出版年份", name = "出版年份"),
    list(var = "平均年龄", name = "平均年龄")
  ),
  groups = list(
    list(var = "研究设计", ref = "横向", name = "横向/纵向"),
    list(var = "是否实验", ref = "实验", name = "实验/非实验")
  ),
  spline = list(
    list(var = "平均年龄", df = 1:3, linear = TRUE, name = "年龄非线性")
  ),
  bias = TRUE,
  leave = TRUE,
  rho = 0.60,
  level = "three",
  show = TRUE,
  keep = TRUE,
  code = FALSE
)
```

同一类型的 `name` 必须唯一。连续变量也可简写为：

```r
cont = c("平均年龄", "出版年份", "样本量")
```

## 13. 发表偏误与小样本效应：`m3bias()`

```r
bias <- m3bias(
  dat,
  rho = 0.60,
  extra = TRUE,
  direction = "auto",
  level = "three"
)

print(bias)
```

### 13.1 核心输出

```r
bias$pet_coefficients
bias$pet_f
bias$peese_coefficients
bias$peese_f
bias$decision
bias$selected_effect
```

三水平模式的 PET/PEESE 保留效应量依赖结构。`decision` 的默认规则是：PET
截距 p < .05 时选择 PEESE，否则选择 PET。该规则不能代替实质判断。

### 13.2 研究级补充方法

`extra = TRUE` 时，包先按 `rho` 聚合为每研究一个效应，再尝试：

```r
bias$single_egger
bias$trimfill
bias$begg
bias$fail_safe_n
bias$three_psm
bias$vevea_table
bias$copas
bias$puniform
bias$pcurve
bias$zcurve_note
bias$study_reported_effects
```

某些方法需要可选包或足够数量的显著研究；不满足条件时会跳过或返回可读错误。

### 13.3 正确解释

- Egger 显著表示效应量与精度相关，即小样本效应或漏斗图不对称，不等于已经
  证明发表偏误。
- trim-and-fill 缺失数为 0 与 Egger 显著可以同时出现，因为两者检验模式不同。
- Hedges' g 与其 SE/方差可能机械相关，因此 PET-PEESE 需谨慎解释。
- 选择模型和 p-uniform 等方法应作为补充敏感性证据，不应投票决定结论。

## 14. Leave-one-out 敏感性分析

```r
loo_effect <- m3leave(dat, by = "effect")
loo_study <- m3leave(dat, by = "study")

loo_effect$full_effect
loo_effect$results
loo_study$full_effect
loo_study$results
```

结果表包含：被删除 ID、删除效应量数、剩余效应量数、剩余研究数、合并效应、
p 值、置信区间和拟合错误。

- leave-one-effect-out：每次删除一行效应量。
- leave-one-study-out：每次删除某研究的全部效应量，是更强的研究聚类层面检验。

重点报告合并效应范围、方向是否改变、显著性是否改变，以及是否由单一研究驱动。

## 15. 作图：`m3plot()`

### 15.1 从完整结果作图

```r
m3plot(result, "forest")
m3plot(result, "cont", name = "平均年龄")
m3plot(result, "spline", name = "年龄非线性")
m3plot(result, "bias")
m3plot(result, "effect")
m3plot(result, "study")
```

连续和样条结果可按显示名或原始变量名选择，也可使用 `index = 1`。

### 15.2 线性调节图

```r
pred_age <- m3plot(
  result,
  "cont",
  name = "平均年龄",
  point_col = "gray70",
  line_col = "black",
  ci_col = "gray45",
  main = "Age moderator",
  xlab = "Age"
)
```

函数隐式返回预测表 `x`、`estimate`、`ci_lb` 和 `ci_ub`。

### 15.3 样条图

```r
result$spline[["年龄非线性"]]$comparison

pred_curve <- m3plot(
  result,
  "spline",
  name = "年龄非线性",
  models = c("linear", "spline_df3"),
  colors = c("gray35", "black"),
  line_types = c(2, 1),
  show_ci = "spline_df3",
  main = "Age moderator: linear vs spline df=3"
)
```

模型名称必须来自 `$models` 或 `$comparison$model`。

### 15.4 保存高分辨率图片

```r
png(
  "年龄调节.png",
  width = 2400,
  height = 1800,
  res = 300,
  type = "cairo"
)
m3plot(result, "cont", name = "平均年龄")
dev.off()
```

含中文的 PDF 推荐：

```r
grDevices::cairo_pdf("结果图.pdf", width = 8, height = 6)
m3plot(result, "study")
grDevices::dev.off()
```

## 16. 结果对象提取

完整工作流包含：

```r
names(result)
# main cont groups spline bias effectleave studyleave
```

### 16.1 主效应

```r
result$main$model       # 原始 metafor 模型
result$main$overall     # 总体效应及报告尺度 CI
result$main$i2          # 多层或普通 I²
result$main$lrt         # 单侧方差 LRT
result$main$aggregation # 单水平研究内合并记录
result$main$prediction  # 单水平空模型预测区间
```

### 16.2 连续调节

```r
result$cont[["平均年龄"]]$center
result$cont[["平均年龄"]]$coefficients
result$cont[["平均年龄"]]$f_test
result$cont[["平均年龄"]]$i2
result$cont[["平均年龄"]]$lrt
```

### 16.3 分类调节

```r
result$groups[["横向/纵向"]]$reference
result$groups[["横向/纵向"]]$counts_effects
result$groups[["横向/纵向"]]$counts_studies
result$groups[["横向/纵向"]]$contrasts
result$groups[["横向/纵向"]]$group_effects
result$groups[["横向/纵向"]]$f_test
```

### 16.4 样条

```r
result$spline[["年龄非线性"]]$comparison
result$spline[["年龄非线性"]]$minimum_ic_model
result$spline[["年龄非线性"]]$best_model
```

### 16.5 发表偏误和敏感性分析

```r
result$bias$selected_effect
result$bias$study_reported_effects
result$effectleave$results
result$studyleave$results
```

## 17. 导出表格

包不强制自动保存文件；结果对象可以自行导出。

### 17.1 CSV

```r
write.csv(
  result$studyleave$results,
  "leave-one-study-out.csv",
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
```

### 17.2 Excel

```r
install.packages("openxlsx")
library(openxlsx)

write.xlsx(
  list(
    main = result$main$overall,
    i2 = result$main$i2,
    lrt = result$main$lrt,
    leave_effect = result$effectleave$results,
    leave_study = result$studyleave$results
  ),
  file = "meta-analysis-results.xlsx",
  overwrite = TRUE
)
```

## 18. 控制台重显、审计代码与源码

```r
# 重新显示完整结果
m3report(result)

# 结果后附底层复现代码
m3report(result, code = TRUE)

# 只生成本次分析的底层 R 代码
m3code(result)

# 保存可独立运行的审计脚本和最小数据快照
m3code(result, file = "analysis-audit.R")

# 查看某个包函数的真实实现
m3source("m3bias")

# 保存全部安装版本函数源码
m3source("all", print = FALSE, file = "meta3level-source.R")

sessionInfo()
```

保存 `m3code()` 时会同时生成同名 `_data.rds` 文件。审计脚本和该数据快照必须
一起保留。快照只包含实际模型所需的 ID、`yi`、`vi` 和调节变量，但仍应按研究
数据管理规范保存，不要未经检查直接公开。

## 19. 论文结果报告规则

### 19.1 主效应

建议至少报告：效应量类型、转换、模型、REML、效应量数 `k`、独立研究数、
合并效应及 95% CI、p 值、Level 3/Level 2 方差、多层 I²、QE 和单侧 LRT。

示例句式：

> 采用 REML 估计的三水平随机效应模型，将效应量嵌套于研究中。相关系数先
> 转换为 Fisher's z 进行分析，并在报告时转回 r。共纳入 k = ... 个效应量，
> 来自 ... 项独立研究。总体效应为 r = ...，95% CI [...]，p = ...。
> Level 3 与 Level 2 方差分别为 ... 和 ...，对应 I² 为 ...% 与 ...%。

### 19.2 连续调节效应

报告中心化均值、斜率、SE、t、分母 df、p、CI，以及 omnibus F：

> 年龄按完整案例样本均值 ... 岁中心化。年龄调节效应为 b = ...，SE = ...，
> t(df) = ...，p = ...，95% CI [...]；总体 F(1, df) = ...，p = ...。

### 19.3 分类调节效应

报告参照组、每类别效应量/研究数、整体 F、有截距模型的对比，以及无截距模型
中每组的报告尺度合并效应。

### 19.4 样条

报告共同样本、ML、候选集合、AIC/AICc/BIC、delta 和简约选择规则。若较复杂
模型只略微改善拟合，应说明为何仍选择或不选择它。

### 19.5 发表偏误

使用“漏斗图不对称”或“小样本效应”而不是直接断言发表偏误。说明哪些模型
保留依赖效应，哪些方法使用研究级聚合数据，并解释不同方法的分歧。

### 19.6 Leave-one-out

报告删除后合并效应范围、方向与显著性是否改变、最有影响的研究，以及
leave-one-study-out 中每项研究删除了多少效应量。

## 20. 常见报错

### 20.1 CSV 只读出一列或三列

检查分隔符、编码和小数点。先运行：

```r
raw <- m3read("data.csv", encoding = "auto")
dim(raw)
names(raw)
```

### 20.2 缺少列或列名重复

```r
names(raw)
attr(raw, "meta3_source")$name_map
```

使用导入后实际列名，不要凭肉眼猜测同名列。

### 20.3 三水平模型提示没有重复效应

改用 `level = "single"`。不要为了运行三水平模型而人为复制效应量。

### 20.4 F 检验仍存放在 QM

这是 `metafor` 对象字段历史命名。应检查模型是否使用 `test = "t"` 或
`tdist = TRUE`；只有这时 omnibus statistic 才按 F 参考分布解释。

### 20.5 F 不显著但 z/QM 显著

小样本 F 使用 t/F 分布和有限分母自由度，通常更保守。应报告事先规定的 F
结果，不应在分析后选择更小的 p 值。

### 20.6 方差成分为 0

这是允许的边界估计。检查研究数、重复效应研究数、LRT 和模型警告，不要因为
数值看起来小就手工改动。

### 20.7 Egger 显著但 trim-and-fill 为 0

两者针对不同的不对称机制，这种组合可以真实出现。报告并解释分歧，不要把
其中一个自动判定为代码错误。

### 20.8 样条预测提示无法匹配变量 2 或 3

不要手工向 `predict()` 传入裸数值向量。使用 `m3plot()`，或复用原始自然样条
basis 的 knots 和 boundary knots。

### 20.9 中文图片或 PDF 乱码

使用 Cairo 图形设备并选择系统已安装的中文字体。该问题不影响模型估计。

### 20.10 可选分析失败但流程继续

```r
inherits(result$bias, "meta3_error")
result$bias$message
```

若希望首次错误就停止，设置 `m3run(..., keep = FALSE)`。

## 21. 多重检验与分析规范

- 连续、分类和样条变量应尽量预先规定。
- 不要排列组合分类变量或不断增加样条 df 来寻找显著结果。
- 探索性分析应明确标记，并考虑多重比较问题。
- 研究数少于 10 时，方差、F 和发表偏误检验通常不稳定。
- 默认三水平模型使用对角 `V = vi`。若共享被试、共享对照或代数关系产生已知
  抽样协方差，应建立设计特定的 V 矩阵；随机效应不能自动替代已知协方差。
- 不同构念、不同对照或不同时间点未必适合在单水平分析中合并为一个研究效应。

## 22. 完整可替换模板

```r
library(meta3level)

# 1. 读取 ---------------------------------------------------------------
raw <- m3read(
  file = "【替换：编码文件完整路径.xlsx】",
  sheet = 1
)

names(raw)
head(raw)

# 2. 准备效应量：以下以 r 为例 -----------------------------------------
dat <- m3prep(
  raw,
  measure = "r",
  study = "【替换：研究ID列名】",
  effect = "【替换：效应量ID列名】",
  value = "【替换：r列名】",
  n = "【替换：样本量列名】"
)

# 3. 一键分析 -----------------------------------------------------------
result <- m3run(
  dat,
  cont = c(
    "【替换：连续变量1】",
    "【替换：连续变量2】"
  ),
  groups = list(
    list(
      var = "【替换：分类变量】",
      ref = "【替换：参照组实际取值】",
      name = "【替换：显示名称】"
    )
  ),
  spline = list(
    list(
      var = "【替换：非线性连续变量】",
      df = 1:3,
      linear = TRUE,
      name = "【替换：非线性结果名称】"
    )
  ),
  bias = TRUE,
  leave = TRUE,
  rho = 0.60,
  level = "three",  # 普通元分析改为 "single"
  show = TRUE,
  keep = TRUE,
  code = FALSE
)

# 4. 提取 ---------------------------------------------------------------
result$main$overall
result$main$i2
result$main$lrt
result$cont[[1]]$coefficients
result$cont[[1]]$f_test
result$groups[[1]]$counts_effects
result$groups[[1]]$counts_studies
result$groups[[1]]$group_effects
result$groups[[1]]$f_test
result$spline[[1]]$comparison
result$bias$selected_effect
result$effectleave$results
result$studyleave$results

# 5. 作图 ---------------------------------------------------------------
m3plot(result, "forest")
m3plot(result, "cont", 1)
m3plot(result, "spline", 1)
m3plot(result, "bias")
m3plot(result, "effect")
m3plot(result, "study")

# 6. 审计 ---------------------------------------------------------------
m3report(result, code = TRUE)
m3code(result, file = "analysis-audit.R")
m3source("all", print = FALSE, file = "meta3level-source.R")
sessionInfo()
```

## 23. 获得帮助与提交 Bug

提交问题时至少提供：

```r
packageVersion("meta3level")
sessionInfo()
```

同时附上完整错误、最小可复现数据或脱敏示例、函数调用、效应量定义和预期行为。
不要公开真实姓名、未脱敏研究编码表或受限制的数据。
