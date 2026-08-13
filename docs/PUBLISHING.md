# GitHub 发布指南

## 发布物

最终会生成下列文件：

- `meta3level-github-v0.6.2.zip`：完整 GitHub 仓库，包含源码、文档、CI、
  示例、Issue 模板和 AI Skill。
- `meta3level_0.6.2.tar.gz`：R 源码包，供 `install.packages()` 安装。
- `run-meta-analysis-r-skill-v1.0.0.zip`：不安装 R 包时使用的独立 AI
  Skill。
- `meta3level-user-manual-zh-CN-v0.6.2.docx` 和同名 PDF：完整中文手册。
- `meta3level-file-manifest-v0.6.2.txt`：精确文件树。

`SHA256SUMS.txt` 用于核对下载文件是否完整。

## 当前发布身份

本仓库已经使用下列公开发布信息：

- GitHub 所有者与软件作者：`awardtome`；
- 维护者邮箱：`awardtome@users.noreply.github.com`；
- 仓库：`https://github.com/awardtome/meta3level`。

`DESCRIPTION` 已包含：

```text
URL: https://github.com/awardtome/meta3level
BugReports: https://github.com/awardtome/meta3level/issues
```

不要把真实研究数据、未脱敏路径、临时日志、RStudio 历史或访问令牌提交到
GitHub。包内示例数据必须保持为合成数据。

## 创建仓库

1. 在 GitHub 创建空仓库 `meta3level`，不要自动生成 README 或许可证。
2. 解压 `meta3level-github-v0.6.2.zip`。
3. 将解压后的 `meta3level` 目录作为仓库根目录。
4. 完成身份替换并运行下列检查。

```powershell
Rscript tools/check-repository.R
Rscript tools/check-manual-code.R USER_MANUAL.zh-CN.md
Rscript tools/smoke-test-native-template.R
Rscript tools/smoke-test-user-manual.R .
R CMD build .
R CMD check --as-cran --no-manual ..\meta3level_0.6.2.tar.gz
```

5. 提交并推送到 `main`，等待 GitHub Actions 的全部矩阵任务通过。

## 建议的 Git 命令

```sh
git init
git add .
git commit -m "Release meta3level 0.6.2"
git branch -M main
git remote add origin https://github.com/awardtome/meta3level.git
git push -u origin main
```

提交前用 `git status --short` 核对文件，不要提交任何研究数据或凭据。

## 创建 GitHub Release

1. 在检查全部通过后创建标签 `v0.6.2`。
2. 以 `NEWS.md` 为基础撰写 Release Notes。
3. 附加 R 源码包、独立 Skill ZIP、中文 DOCX/PDF 手册、精确文件树和
   `SHA256SUMS.txt`。
4. 在 Release Notes 中注明 R 版本、`R CMD check` 状态和已测试的效应量。

## 用户安装 R 包

从 GitHub 仓库安装：

```r
install.packages("remotes")
remotes::install_github("awardtome/meta3level", dependencies = NA,
                        upgrade = "never")
library(meta3level)
```

从 Release 附件安装：

```r
install.packages("metafor")
install.packages("meta3level_0.6.2.tar.gz", repos = NULL, type = "source")
library(meta3level)
```

## 用户安装 AI Skill

完整安装方法见 [AI Skill 使用说明](AI_SKILL.md)。独立 ZIP 解压后必须保留
整个 `run-meta-analysis-r` 目录，不能只复制 `SKILL.md`，因为分析规则、质量
门槛和原生 `metafor` 模板位于其子目录中。

## 版本更新规则

- 修复不改变公开接口的错误：递增补丁版本，例如 `0.6.2` 到 `0.6.3`。
- 向后兼容的新功能：递增次版本，例如 `0.6.x` 到 `0.7.0`。
- 不兼容的公开接口变化：进入稳定版本后递增主版本。
- 每次发布同步修改 `DESCRIPTION`、`NEWS.md`、`CITATION.cff`、README 中的
  版本号和 Release 文件名，并重新生成校验和。
