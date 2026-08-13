# meta3level 全部公开函数简明参考

本页覆盖 `meta3level` 0.6.2 导出的全部 18 个 `m3*` 函数。正式参数说明可使用
`?函数名`，安装版本的真实实现可使用 `m3source("函数名")` 查看。

## 1. 推荐调用顺序

1. 用 `m3read()` 读取编码文件。
2. 用 `m3prep()` 把研究报告的统计量转换为 `yi` 和 `vi`。
3. 优先用 `m3run()` 运行完整流程；需要单独控制时使用 `m3fit()` 和各专项函数。
4. 用 `m3report()`、`m3plot()` 和 `m3code()` 重显、作图与审计。

## 2. 一览表

| 函数 | 简单用途 |
|---|---|
| `m3read()` | 读取 CSV、TSV、TXT、XLSX 或 XLS 编码文件。 |
| `m3prep()` | 准备 `r`、`d`、`g`、`OR` 或自定义 `yi/vi`。 |
| `m3fit()` | 拟合三水平或普通随机效应模型。 |
| `m3effect()` | 提取截距/总体效应并转换到报告尺度。 |
| `m3ftest()` | 提取调节变量 omnibus F 检验。 |
| `m3i2()` | 计算多层或普通异质性指标。 |
| `m3lrt()` | 运行方差成分单侧边界似然比检验。 |
| `m3cont()` | 分析一个中心化连续调节变量。 |
| `m3group()` | 分析一个分类调节变量及每组合并效应。 |
| `m3spline()` | 用 ML 比较线性与自然样条模型。 |
| `m3study()` | 将同研究多个相关效应量合并为一个。 |
| `m3bias()` | 运行 Egger、PET-PEESE 及补充小样本效应诊断。 |
| `m3leave()` | 运行 leave-one-effect/study-out。 |
| `m3run()` | 一次完成主效应和指定的全部分析。 |
| `m3plot()` | 自动绘制森林图、调节图、样条图、漏斗图或敏感性图。 |
| `m3report()` | 在控制台重新打印完整结果。 |
| `m3code()` | 生成可审查的底层软件包 R 代码。 |
| `m3source()` | 查看或保存安装包中的真实函数定义。 |

## 3. 逐函数说明

### `m3read()` - 读取编码文件

**调用格式：** `m3read(file, sheet = 1, encoding = "auto", decimal = ".", ...)`

```r
raw <- m3read("编码文件.xlsx", sheet = 1)
```

常用参数为 `file`、`sheet`、`encoding` 和 `decimal`。`encoding = "auto"`
会尝试常见 UTF-8 与中文编码，并自动识别逗号、分号或制表符。返回数据框，来源
信息保存在 `attr(raw, "meta3_source")`。读取后必须检查 `names(raw)`，尤其是
原文件存在重复表头时。

### `m3prep()` - 准备效应量

**调用格式：** `m3prep(data, measure, study, effect = NULL, value = NULL,
n = NULL, n1 = NULL, n2 = NULL, vi = NULL, se = NULL, lower = NULL,
upper = NULL, cellA = NULL, cellB = NULL, cellC = NULL, cellD = NULL,
conf = 0.95, correction = 0.5, design = "independent", variance = "known",
decimal = NULL)`

```r
dat <- m3prep(
  raw,
  measure = "r",
  study = "studyID",
  effect = "effectID",
  value = "r",
  n = "n"
)
```

`measure` 可为 `"r"`、`"d"`、`"g"`、`"or"` 或 `"custom"`。根据效应量
类型提供 `n`、`n1/n2`、`vi`、`se`、置信区间或四格表。返回包含标准化
`studyID`、`effectID`、`yi`、`vi` 的模型数据。相关系数转 Fisher z，d 转
Hedges' g，OR 转 log(OR)。`vi` 必须是方差而不是标准误。

### `m3fit()` - 拟合主模型或自定义模型

**调用格式：** `m3fit(data, mods = NULL, method = "REML", f = TRUE,
sigma2 = c(NA, NA), warn = TRUE, level = "three", rho = 0.60, ...)`

```r
model <- m3fit(dat, level = "three", method = "REML", f = TRUE)
age_model <- m3fit(dat, mods = ~ age, f = TRUE)
```

`level = "three"` 使用研究/效应量嵌套；`level = "single"` 先按 `rho` 合并
研究内效应量，再运行普通随机效应模型。`f = TRUE` 时系数采用 t 推断，调节
变量整体检验采用 F 参考分布。对象内部仍可能沿用 `$QM` 字段名称。

### `m3effect()` - 提取总体效应

**调用格式：** `m3effect(model, back = TRUE)`

```r
m3effect(model)
```

返回估计、SE、p 值和置信区间，并按需把 Fisher z 转回 r、log(OR) 转回 OR。
若模型包含调节变量，第一项是截距，不是无条件总体效应。

### `m3ftest()` - 提取 F 检验

**调用格式：** `m3ftest(model)`

```r
m3ftest(age_model)
```

返回调节效应的 F 值、分子自由度、分母自由度和 p 值。前提是模型确实使用
t/F 推断。

### `m3i2()` - 异质性分解

**调用格式：** `m3i2(model)`

```r
m3i2(model)
```

三水平模型返回 Level 3、Level 2 与总 I²；普通模型返回常规异质性指标。方差
估计为 0 是允许的边界估计，不能手工修改。

### `m3lrt()` - 方差成分单侧 LRT

**调用格式：** `m3lrt(model, data = model$meta3_data)`

```r
m3lrt(model)
```

三水平模型分别检验 Level 3 与 Level 2 方差。该检验回答异质性方差问题，不能
替代总体效应或调节效应显著性检验。

### `m3cont()` - 连续调节变量

**调用格式：** `m3cont(data, var, name = var, method = "REML",
level = "three", rho = 0.60)`

```r
age_result <- m3cont(dat, var = "age", name = "平均年龄")
```

程序按该变量的完整案例均值中心化，只拟合有截距模型。主要结果为 `$center`、
`$coefficients`、`$f_test`、`$i2` 和 `$lrt`。r 模型斜率位于 Fisher-z 尺度，
OR 模型斜率位于 log(OR) 尺度，不能简单把斜率反变换后称为每单位 r/OR 变化。

### `m3group()` - 分类调节变量

**调用格式：** `m3group(data, var, ref, name = var, method = "REML",
level = "three", rho = 0.60)`

```r
design_result <- m3group(
  dat,
  var = "design",
  ref = "cross-sectional",
  name = "研究设计"
)
```

同时拟合有截距参照组对比模型和无截距各组合并效应模型。主要结果为
`$counts_effects`、`$counts_studies`、`$contrasts`、`$group_effects` 和
`$f_test`。`ref` 必须与清洗后的实际类别完全一致。

### `m3spline()` - 样条非线性比较

**调用格式：** `m3spline(data, var, df = 1:3, linear = TRUE, name = var,
level = "three", rho = 0.60)`

```r
curve_result <- m3spline(dat, var = "age", df = 1:3, linear = TRUE)
```

所有候选模型使用同一完整案例和 ML，比较 logLik、AIC、AICc、BIC 与 delta。
主要结果为 `$comparison`、`$minimum_ic_model`、`$best_model` 和 `$models`。
不能为了寻找显著结果不断提高 df。

### `m3study()` - 研究内合并

**调用格式：** `m3study(data, rho = 0.60, keep = character())`

```r
study_dat <- m3study(dat, rho = 0.60, keep = c("age", "design"))
```

按假设的研究内抽样相关 `rho`，把同研究效应量合并为一个。`rho` 应进行敏感性
分析。`keep` 只能包含研究内恒定变量；发现冲突时函数会停止而非擅自平均。

### `m3bias()` - 发表偏误/小样本效应诊断

**调用格式：** `m3bias(data, rho = 0.60, extra = TRUE,
direction = "auto", level = "three")`

```r
bias_result <- m3bias(dat, rho = 0.60, extra = TRUE, level = "three")
```

核心结果包含 PET、PEESE 的系数与 F 检验、选择规则和校正截距。`extra = TRUE`
时还会在满足包与数据条件时尝试研究级 Egger、trim-and-fill、Begg、fail-safe N、
选择模型、Copas、p-uniform、p-curve 等。Egger 显著表示小样本效应或漏斗图
不对称，不等于已经证明发表偏误；不同方法出现分歧并不必然是代码错误。

### `m3leave()` - leave-one-out

**调用格式：** `m3leave(data, by = "effect", method = "REML",
level = "three", rho = 0.60)`

```r
effect_loo <- m3leave(dat, by = "effect")
study_loo <- m3leave(dat, by = "study")
```

`$full_effect` 保存完整模型效应，`$results` 保存每次删除的 ID、删除/剩余效应量
数、剩余研究数、合并效应、p 值、置信区间和拟合错误。

### `m3run()` - 一键完整流程

**调用格式：** `m3run(data, cont = NULL, groups = NULL, spline = NULL,
bias = TRUE, leave = TRUE, rho = 0.60, level = "three", show = TRUE,
keep = TRUE, code = FALSE)`

```r
result <- m3run(
  dat,
  cont = c("age", "year"),
  groups = list(
    list(var = "design", ref = "cross-sectional", name = "研究设计")
  ),
  spline = list(
    list(var = "age", df = 1:3, name = "年龄曲线")
  ),
  bias = TRUE,
  leave = TRUE,
  level = "three",
  show = TRUE,
  keep = TRUE
)
```

顶层结果为 `$main`、`$cont`、`$groups`、`$spline`、`$bias`、`$effectleave` 和
`$studyleave`。`show = TRUE` 在控制台显示全部结果；`keep = TRUE` 允许某个可选
组件失败后继续运行，主模型失败仍会停止。

### `m3plot()` - 自动作图

**调用格式：** `m3plot(x, what = NULL, index = 1, name = NULL, ...)`

```r
m3plot(result, "forest")
m3plot(result, "cont", name = "age")
m3plot(result, "spline", name = "年龄曲线")
m3plot(result, "bias")
m3plot(result, "effect")
m3plot(result, "study")
```

根据结果类型绘制森林图、线性调节图、样条图、漏斗图或敏感性折线图。存在多个
调节变量时使用 `name` 或 `index` 选择，其他作图选项通过 `...` 传入。

### `m3report()` - 重新显示结果

**调用格式：** `m3report(x, code = FALSE, ...)`

```r
m3report(result)
m3report(result, code = TRUE)
```

把已有结果重新打印到控制台；`code = TRUE` 时在结果后附底层审计代码。

### `m3code()` - 生成可审查底层代码

**调用格式：** `m3code(x, print = TRUE, file = NULL)`

```r
m3code(result)
m3code(result, file = "analysis-audit.R")
```

生成直接调用依赖包、而不依赖 `meta3level` 分析封装的可执行 R 代码。保存文件时
同时生成同名 `_data.rds` 快照，脚本与数据应一起保留，公开前须检查快照内容。

### `m3source()` - 查看真实函数实现

**调用格式：** `m3source(fun = "all", print = TRUE, file = NULL)`

```r
m3source("m3bias")
m3source("all", print = FALSE, file = "meta3level-source.R")
```

`fun` 可为一个函数名、多个函数名或 `"all"`，用于审查安装版本实际执行的函数
定义。

## 4. 获取帮助与审计

```r
help(package = "meta3level")
?m3prep
args(m3prep)
m3source("m3prep")
packageVersion("meta3level")
sessionInfo()
```

提交问题时应提供包版本、完整错误、函数调用、效应量定义和最小脱敏示例。
