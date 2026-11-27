# Vendored third-party skill packages（provenance 台账）

| 项 | 值 |
|---|---|
| 上游 | github.com/ibelick/ui-skills（Skills for Design Engineers，11.5k star） |
| 锁定 commit | `4b5bf7bbde7852d2904aa2bcd1d6bcc62823f721`（2026-11-27 vendor） |
| 许可证 | **MIT**——全文见同目录 `ui-skills-LICENSE.txt` |
| 包（11 个） | baseline-ui · component-canvas · create-canvas · create-design-md · device-frames · fixing-accessibility · fixing-metadata · fixing-motion-performance · improve-ui · photographing-software · ui-skills-root |
| 更新方式 | 重新下载 `codeload.github.com/ibelick/ui-skills/tar.gz/<新SHA>`，逐包替换本目录同名目录，更新本文件 SHA 行后提交——vendor 内容必须永远可复现到具体 commit |
| 与仓库的关系 | 位于 Agent Skills 标准项目发现路径（`.agents/skills/`），随 git 克隆分发给任何按标准扫描的工具（Claude Code/Codex/Cursor/OpenCode 等）；**不入 `skills/` 与 `mudules/`**——预算与审计门禁只治理自有库，审计有意排除 `.agents/` |
| 自主调用 | 各包 description 即触发层：UI 设计（create-design-md 等）、UI 修复（improve-ui + fixing-* 三件）、UI 证据（device-frames/photographing-software）、上下文路由（ui-skills-root） |
