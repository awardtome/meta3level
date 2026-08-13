# meta3level 0.6.2 中文发布说明

本版本提供一套可审查、可复现的三水平元分析与普通元分析 R 工作流。同时提供
独立的 Agent Skill，供希望直接生成原生 `metafor` 代码、而不使用 R 包封装的
研究者选择。

## 发布文件

- `meta3level-github-v0.6.2.zip`：可直接用于 GitHub 的完整仓库，包含源码、
  文档、CI、示例和 AI Skill。
- `meta3level_0.6.2.tar.gz`：可通过 R 安装的源码包。
- `run-meta-analysis-r-skill-v1.0.0.zip`：可单独安装到 AI 编程工具中的 Skill。
- `meta3level-user-manual-zh-CN-v0.6.2.docx`：带自动目录、代码块和页码的中文
  Word 手册。
- `meta3level-user-manual-zh-CN-v0.6.2.pdf`：便于跨平台阅读和打印的中文 PDF
  手册。
- `meta3level-user-manual-en-v0.6.2.docx`：带自动目录、代码块和页码的完整英文
  Word 手册。
- `meta3level-user-manual-en-v0.6.2.pdf`：便于跨平台阅读和打印的完整英文 PDF
  手册。
- `meta3level-file-manifest-v0.6.2.txt`：GitHub 仓库和 Release 附件的精确
  文件树。
- `SHA256SUMS.txt`：所有主要交付文件的 SHA-256 校验值。

仓库同时提供 `FUNCTION_REFERENCE.zh-CN.md` 和 `FUNCTION_REFERENCE.en.md`，
用简明方式说明全部 18 个公开函数的用途、主要参数、返回对象、最小示例和常见
注意事项。

## 主要功能

- 支持相关系数 `r`、Cohen's `d`、Hedges' `g`、优势比 `OR`，以及研究者提供
  转换公式和抽样方差的自定义 `yi/vi`。
- 支持三水平元分析和普通随机效应元分析；普通元分析可先按研究聚合相关效应量。
- 三水平模型采用 `metafor` 的 t/F 推断；调节效应报告 F 值、自由度和 p 值，
  不把卡方 QM 检验错误地标记为 F 检验。
- 连续调节变量按各自完整案例样本的均值中心化，不拟合连续变量无截距模型。
- 分类调节变量同时提供有截距对比模型和无截距组别合并效应模型。
- 支持多层 I² 分解、方差成分单侧边界似然比检验，以及基于 ML 的线性与自然
  样条模型 AIC、AICc、BIC 比较。
- 支持多层与研究层面的 Egger/PET、PEESE、漏斗图及补充发表偏误诊断，并明确
  区分小样本效应与已经证实的发表偏倚。
- 支持 leave-one-effect-out 和 leave-one-study-out，输出完整表格和折线图。
- 可通过 `m3code()` 输出实际调用底层软件包的可审查 R 代码，通过 `m3source()`
  查看包内真实函数实现。

## 验证结果

- `R CMD check --as-cran --no-manual`：0 ERROR、0 WARNING、2 NOTE。两个 NOTE
  均不是代码或测试失败：一项来自首次提交状态，另一项是本机无法联网核对
  系统时间。R 安装、命名空间、帮助页、测试和代码检查均通过。
- 完整 `testthat` 测试：没有失败断言。
- 四个公开示例：在独立 R 库安装后全部运行通过。
- 原生 Skill 模板：已验证 `r`、`d→g`、预计算 `g`、`OR`、自定义 `yi/vi`，
  以及普通单水平元分析。
- 官方 Skill 校验器：通过。
- 两份真实编码表兼容性审计：四个分析分支均通过简短公开 API 完成，未出现被
  捕获的组件错误。
- 说明书代码：中文 61 个、英文 75 个 R 代码块全部通过解析；使用合成数据实跑
  了三水平、单水平、连续/分类调节、ML 样条、发表偏误、两类 leave-one-out、
  绘图、`d→g` 和 OR 路径。
- DOCX/PDF：Word 导出的中文手册为 41 页、英文手册为 40 页，全部渲染后逐页
  检查；未发现页面重叠、表格越界、代码截断、空白页异常或中文字体异常。
- 函数覆盖：两份完整说明书和两份简明函数速查均覆盖全部 18 个公开函数。

完整验证范围见 `VALIDATION.md`。

## 公开发布信息

版本 0.6.2 由 `awardtome` 发布，仓库地址为
`https://github.com/awardtome/meta3level`。维护者使用 GitHub noreply 邮箱，
避免公开私人邮箱。发布前已重新核对包元数据、许可证、引用信息和安装链接，
并重新运行质量检查与生成 SHA-256 校验值。

所有发布归档均不包含用户的真实研究数据、未脱敏路径或本地测试日志。
