# meta3level 整套文件说明

本说明对应 `meta3level` 0.6.2。GitHub 仓库根目录包含 R 包源码、用户文档、
测试、示例、持续集成配置和一个不依赖本包的 AI Skill。真实研究数据不属于
仓库文件，不应提交到 GitHub。

## 1. 用户首先阅读的文件

| 文件 | 用途 |
|---|---|
| `README.md` | 中文首页、功能概览、快速安装和常用代码。 |
| `USER_MANUAL.zh-CN.md` | 完整中文使用说明书，涵盖全部公开函数和分析流程。 |
| `USER_MANUAL.en.md` | 完整英文使用说明书，涵盖全部公开函数和分析流程。 |
| `FUNCTION_REFERENCE.zh-CN.md` | 全部 18 个公开函数的中文简明速查。 |
| `FUNCTION_REFERENCE.en.md` | 全部 18 个公开函数的英文简明速查。 |
| `README.en.md` | 英文首页。 |
| `RELEASE_NOTES.zh-CN.md` | 当前版本中文发布说明。 |
| `RELEASE_NOTES.md` | 当前版本英文发布说明。 |
| `VALIDATION.md` | 软件测试、真实编码表兼容性和发布验证记录。 |
| `RELEASE_CHECKLIST.md` | 公开发布身份、质量门槛和 Release 检查清单。 |
| `CITATION.cff` | GitHub 的 Cite this repository 引用元数据。 |
| `NEWS.md` | 按版本记录功能与修复。 |
| `LICENSE`、`LICENSE.md` | R 包和 GitHub 仓库的 MIT 许可证。 |

## 2. R 包核心文件

| 路径 | 用途 |
|---|---|
| `DESCRIPTION` | 包名、版本、作者、依赖、许可证和功能描述。 |
| `NAMESPACE` | 导出的 `m3*` 函数以及 S3 打印方法。 |
| `R/api.R` | 简短公开 API：`m3read()` 到 `m3source()`。 |
| `R/io.R` | CSV、TSV、Excel、编码、分隔符和重复表头处理。 |
| `R/effect-sizes.R` | `r`、`d`、`g`、`OR` 与自定义效应量转换及数据校验。 |
| `R/model.R` | 三水平/单水平模型、总体效应、F 检验、I² 与 LRT。 |
| `R/moderators.R` | 连续、分类和自然样条调节效应。 |
| `R/publication-bias.R` | 研究内聚合、Egger、PET-PEESE 和补充发表偏误方法。 |
| `R/leave-one-out.R` | leave-one-effect-out 与 leave-one-study-out。 |
| `R/plots.R` | 森林图、调节图、样条图、漏斗图和敏感性折线图。 |
| `R/workflow.R` | 完整工作流调度、控制台输出和组件错误隔离。 |
| `R/audit-code.R` | 生成底层可复现 R 代码及查看真实函数源码。 |
| `R/utils.R` | 数值转换、百分比识别、警告、回转和通用工具。 |

`R/` 中除 `api.R` 定义的 `m3*` 函数外，其余长函数名主要是包内部实现，用户
日常分析应优先使用简短公开 API。

## 3. R 帮助页

| 文件 | 覆盖内容 |
|---|---|
| `man/core-functions.Rd` | 读取、效应量准备、模型、总体效应、F、I²、LRT。 |
| `man/moderator-functions.Rd` | 连续、分类、样条调节。 |
| `man/bias-sensitivity-functions.Rd` | 研究内合并、发表偏误、leave-one-out。 |
| `man/workflow-functions.Rd` | 一键运行和完整报告。 |
| `man/plot-functions.Rd` | 自动绘图。 |
| `man/audit-functions.Rd` | 审计代码与源码查看。 |
| `man/meta3level-package.Rd` | 包级帮助页。 |

安装后可在 R 中运行 `help(package = "meta3level")` 或 `?m3run` 查看。

## 4. 用户文档目录 `docs/`

| 文件 | 用途 |
|---|---|
| `docs/GETTING_STARTED.md` | 最短安装与首次运行步骤。 |
| `docs/DATA_REQUIREMENTS.md` | 各效应量和变量所需数据。 |
| `docs/STATISTICAL_WORKFLOW.md` | 模型、F 检验、中心化、样条与偏误规则。 |
| `docs/OUTPUT_AND_REPORTING.md` | 结果提取和论文报告要求。 |
| `docs/TROUBLESHOOTING.md` | 常见报错定位。 |
| `docs/AI_SKILL.md` | 独立 AI Skill 的安装和调用。 |
| `docs/PUBLISHING.md` | GitHub 仓库、标签和 Release 发布方法。 |

## 5. 可运行示例与模板

| 文件 | 用途 |
|---|---|
| `examples/01-correlation-three-level.R` | `r → Fisher z → r` 的三水平完整示例。 |
| `examples/02-independent-d-three-level.R` | 独立组 `d → g` 示例。 |
| `examples/03-odds-ratio-three-level.R` | 2×2 四格表 OR 示例。 |
| `examples/04-conventional-meta-analysis.R` | 研究内合并后的普通随机效应示例。 |
| `inst/templates/analysis-template.R` | 带“替换”标记的全流程代码模板。 |
| `inst/extdata/example_correlations.csv` | 合成测试数据，不是真实研究数据。 |

安装后模板与示例数据会随包安装，可通过 `system.file()` 查找。

## 6. 自动测试

| 文件 | 测试范围 |
|---|---|
| `tests/testthat.R` | testthat 测试入口。 |
| `tests/testthat/helper-data.R` | 合成测试数据。 |
| `tests/testthat/test-core.R` | 效应量、主模型、F、I²、LRT。 |
| `tests/testthat/test-moderators.R` | 连续、分类和样条。 |
| `tests/testthat/test-sensitivity.R` | 研究内合并与 leave-one-out。 |
| `tests/testthat/test-single-level.R` | 普通元分析与 `rho`。 |
| `tests/testthat/test-workflow.R` | 一键流程、绘图分派和审计代码。 |
| `tests/testthat/test-failure-modes.R` | 非法输入、歧义比例和失败提示。 |

## 7. GitHub 配置

| 文件 | 用途 |
|---|---|
| `.github/workflows/R-CMD-check.yaml` | Windows、macOS、Ubuntu 和多版本 R CI。 |
| `.github/ISSUE_TEMPLATE/bug-report.yml` | Bug 报告模板。 |
| `.github/ISSUE_TEMPLATE/feature-request.yml` | 功能建议模板。 |
| `.github/ISSUE_TEMPLATE/config.yml` | Issue 模板配置。 |
| `.github/pull_request_template.md` | Pull Request 检查清单。 |
| `CONTRIBUTING.md` | 贡献与测试规则。 |
| `CODE_OF_CONDUCT.md` | 协作行为准则。 |
| `SECURITY.md` | 安全问题报告方式。 |
| `.gitignore` | Git 忽略本地日志、历史、构建包和检查目录。 |
| `.gitattributes` | 跨平台换行及二进制文件规则。 |
| `.Rbuildignore` | 构建 R 源码包时排除 GitHub/Skill/发布文档。 |

## 8. 独立 AI Skill

`skills/run-meta-analysis-r/` 可以脱离 `meta3level` R 包使用：

| 文件 | 用途 |
|---|---|
| `SKILL.md` | AI 的总工作流、触发条件和质量要求。 |
| `agents/openai.yaml` | Codex 的显示名称和默认调用提示。 |
| `assets/native-metafor-template.R` | 直接调用 `metafor` 的完整原生模板。 |
| `references/effect-sizes.md` | 各效应量转换规则。 |
| `references/models-and-tests.md` | 三水平/单水平、F、LRT、I² 与样条规则。 |
| `references/publication-bias.md` | 发表偏误和小样本效应规则。 |
| `references/output-contract.md` | 控制台、表格、图片和报告尺度要求。 |
| `references/quality-gates.md` | AI 交付代码前必须通过的检查。 |

## 9. 开发与发布工具

| 文件 | 用途 |
|---|---|
| `tools/check-repository.R` | 检查版本、R 语法、Markdown 链接和占位符。 |
| `tools/check-manual-code.R` | 逐个解析中英文说明书中的 R 代码块，防止发布不可复制的示例。 |
| `tools/smoke-test-user-manual.R` | 用合成数据执行手册覆盖的主要分析入口和效应量路径。 |
| `tools/build-user-manual-html.R` | 把中英文 Markdown 说明书转换为保留结构的 HTML 中间稿。 |
| `tools/build-user-manual.ps1` | 通过 Word 生成带目录、页眉页码和统一样式的 DOCX/PDF。 |
| `tools/render-user-manual.R` | 将 PDF 逐页渲染并生成联系表，用于发布前视觉校验。 |
| `tools/build-release.ps1` | 统一生成 GitHub ZIP、R 包、Skill ZIP、文件树和校验值。 |
| `tools/smoke-test-native-template.R` | 验证原生模板的六种分析场景。 |
| `tools/install-skill.ps1` | Windows 安装 AI Skill。 |
| `tools/install-skill.sh` | Linux/macOS 安装 AI Skill。 |

## 10. Release 附件

发布目录中应包含：

| 文件 | 用途 |
|---|---|
| `meta3level-github-v0.6.2.zip` | 完整 GitHub 仓库。 |
| `meta3level_0.6.2.tar.gz` | R 源码安装包。 |
| `run-meta-analysis-r-skill-v1.0.0.zip` | 独立 AI Skill。 |
| `RELEASE_NOTES.md` | 英文发布说明。 |
| `RELEASE_NOTES.zh-CN.md` | 中文发布说明。 |
| `SHA256SUMS.txt` | 主要交付文件的 SHA-256。 |
| `meta3level-user-manual-zh-CN-v0.6.2.docx` | 便于打印阅读的中文 Word 手册。 |
| `meta3level-user-manual-zh-CN-v0.6.2.pdf` | 便于跨平台阅读的中文 PDF 手册。 |
| `meta3level-user-manual-en-v0.6.2.docx` | 完整英文 Word 手册。 |
| `meta3level-user-manual-en-v0.6.2.pdf` | 完整英文 PDF 手册。 |
| `meta3level-file-manifest-v0.6.2.txt` | 仓库与 Release 附件的精确文件树。 |

当前版本的公开身份与仓库地址已经写入发布元数据。每次发布仍应按照
`RELEASE_CHECKLIST.md` 重新核对身份、构建归档与 SHA-256。不要将本机 R 库、
`.Rcheck`、测试日志、真实编码表或包含隐私的审计数据快照提交到 GitHub。
