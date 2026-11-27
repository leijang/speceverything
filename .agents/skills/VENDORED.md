# Vendored third-party skill packages（provenance 台账）

## ibelick/ui-skills（UI 设计包）

| 项 | 值 |
|---|---|
| 上游 | github.com/ibelick/ui-skills（Skills for Design Engineers，11.5k star） |
| 锁定 commit | `4b5bf7bbde7852d2904aa2bcd1d6bcc62823f721`（2026-11-27 vendor） |
| 许可证 | **MIT**——全文见同目录 `ui-skills-LICENSE.txt` |
| 包（11 个） | baseline-ui · component-canvas · create-canvas · create-design-md · device-frames · fixing-accessibility · fixing-metadata · fixing-motion-performance · improve-ui · photographing-software · ui-skills-root |
| 更新方式 | 重新下载 `codeload.github.com/ibelick/ui-skills/tar.gz/<新SHA>`，逐包替换本目录同名目录，更新本文件 SHA 行后提交——vendor 内容必须永远可复现到具体 commit |
| 与仓库的关系 | 位于 Agent Skills 标准项目发现路径（`.agents/skills/`），随 git 克隆分发给任何按标准扫描的工具（Claude Code/Codex/Cursor/OpenCode 等）；**不入 `skills/` 与 `mudules/`**——预算与审计门禁只治理自有库，审计有意排除 `.agents/` |
| 自主调用 | 各包 description 即触发层：UI 设计（create-design-md 等）、UI 修复（improve-ui + fixing-* 三件）、UI 证据（device-frames/photographing-software）、上下文路由（ui-skills-root） |

## cathrynlavery/diagram-design（架构/流程图包）

| 项 | 值 |
|---|---|
| 上游 | github.com/cathrynlavery/diagram-design（Editorial diagram design，52 种图形类型） |
| 锁定 commit | `795eec47fd376e5dda0b9e056a49520060cd2f13`（v2.6.181，2026-11-27 vendor） |
| 许可证 | **MIT**——全文见同目录 `diagram-design-LICENSE.txt` |
| 包（1 个） | diagram-design：架构图/流程图/时序图/ER 图/泳道图等 52 种，输出自包含 HTML+SVG（SKILL.md + references/ 按需加载 + scripts/ 导出） |
| 更新方式 | 重新下载 `codeload.github.com/cathrynlavery/diagram-design/tar.gz/<新SHA>`，取其中 `skills/diagram-design/` 整目录替换本目录同名目录，更新本文件 SHA 行后提交——vendor 内容必须永远可复现到具体 commit |
| 与仓库的关系 | 位于 Agent Skills 标准项目发现路径（`.agents/skills/`），随 git 克隆分发；**不入 `skills/` 与 `mudules/`**。规格内 Mermaid 图（spec-standards §9、tech-design 三要素）仍是唯一事实源——本包只做**呈现级增强**（对外评审/汇报的高保真稿，一律为中间态，不回写替换规格内 Mermaid） |
| 自主调用 | description 即触发层：用户要求绘制高保真架构图/流程图/时序图等时使用；工作流内由 tech-design（三要素图）与 project-structure（全局架构）步骤按需提醒调用 |
