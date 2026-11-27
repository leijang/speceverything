# Skill 深化审计与修复记录（2026-11-27）

> 任务：深化 `skills/`（深入 ≠ 变大，硬门禁为总篇幅不升）。本文是第 1 步「证据先行」的落盘证据。
> 机械结果由 `tools/skill-audit.ps1` 生成（输出 `tools/skill-audit-report.md`），任何第三方重跑必得同结果：`powershell -NoProfile -ExecutionPolicy Bypass -File tools\skill-audit.ps1`（退出码 0 = CLEAN）。
> 本仓库 `specs/错题本.md` 等交付沉淀**尚不存在**（首次交付时由各 skill 自建），因此规则溯源的实际矿源是 git 提交历史与全量对读，不是错题本。

## 结论

- 首轮审计：59 处 `§` 引用查出 **5 处断链**、1 个模板缺失、14 处 `spec/` 单数路径命中（12 行）、0 处 mudules 目录树缺失。
- 修复后复跑：**CLEAN**——57 处引用零断链、模板零缺失、`spec/` 零残留。
- 预算硬门禁：74,576 → 74,338 字符（估算 token 42,112 → 41,982），**净下降**。深化没有变胖。

## 修复清单（一处一个根因，全部经复跑验证）

### 1. 引用断链（机械可验）

| # | 位置 | 缺陷 | 处置 |
|---|---|---|---|
| 1 | blackbox-test §4 | 「登记走 §7 流程」与行内先出现的 hifi-design 名字相邻，`§7` 会被就近解析到**没有 §7 的 hifi-design** | 长句拆两条 + 改「本 skill §7」，自指无歧义 |
| 2 | tech-design 前置条件 | 示例标注引用 `abp-usage §2 分层规则`，但 abp-usage **没有任何编号节**（实际节名「分层决策表」） | 改为实际节名 |
| 3 | project-structure | 引用 `assets/speceverything-project-structure-template.md`，实际文件名是 `project-structure-template.md` | 改正文件名 |
| 4 | README 横切表 | 「tech-design 前置条件 §3」不可解析（该节无编号） | 改「前置条件·技术实践检索」 |
| 5 | README:19 / summary:100 | `§N` 指向**运行时文档**（`开发规范.md`、`过程复盘.md §2.4`——模板中真实存在），非 skill 断链 | 脚本新增 RUNTIME-DOC 分类（无名字前置且前文含 `.md`），消除误报 |

### 2. 路径与命名漂移（根因：dev-standards 沿用旧 `spec/` 布局未随仓库迁移）

| 位置 | 缺陷 | 处置 |
|---|---|---|
| dev-standards 12 行 | `spec/`（单数）——工作区实际目录是 `specs/`；其产出会落成 `spec/开发规范.md` **孤儿文件**（summary §3.3 读的是 `specs/开发规范.md`） | 全部改 `specs/` |
| dev-standards 读取表 | 引用 `API设计规范.md`、`数据模型设计.md`——**全仓库无任何 skill 生产这两个文档**，属「必须全部读取」门禁里的死指令 | 删两行（catch-all 行「specs/ 下所有已有文档」已覆盖未来真实存在的文档） |
| README 树 | 同一文档两名：`specs/技术栈.md`（tech-stack 实际输出 + 5 处消费方）vs `技术栈选型.md`（README 唯一异类） | 以生产者为准，README 改 `技术栈.md` |

### 3. 唯一定义处违例（违反 summary §4.4「一条规则只在一个地方完整定义」）

- **错题本条目格式双定义**：summary §7 与 dev-standards §13 各写一份（README 横切表自己也登记了两处）。两份当前内容一致，属漂移前夜。
- 处置：summary §7 保留为唯一定义处；dev-standards §13 改一行引用；README 横切表、code-review §73 同步改单引用。

### 4. 语义矛盾（git e2596d3/b7a7c13 演进后的过期条款）

- release-deploy §2：「worktree 完成合并 develop 后即可删除」与 §2.1「不立即清理、由 commit-push 在推送后统一执行」**直接矛盾**（后者为演进后的规则，commit-push §61 佐证）。
- 处置：收编为引用——「合并 `develop` 后不立即删除：删除时序与清理规则见 §2.1」。

### 5. 格式塌陷（列表被压成单行，只加换行不改一字；降低消费方模型解析质量）

- release-deploy：§1/§2/§2.1/§3/§4/§5/§7 共 10 处；hifi-design：6 处；abp-usage：铁律 14 条 + 使用流程 4 条。
- 复跑验证：引用全部仍 OK，总字符因去重净降。

1. **summary §5 示例行**（「akshare 擅自换源」等）来自前项目实例，非本仓库沉淀，易误读——无害，暂不动。

## 规则出处台账（git 事件 ↔ 条款，2026-11-27 挂接）

仓库全部 15 个提交集中于 2026-11-26：初版导入 + 12 次事件驱动修订 + 2 次布局迁移。**规则的证据链在 git 历史，不在任何文档**——每次修订对应一个真实失灵点，这份台账就是本仓库事实上的"错题本"。

| 提交 | 事件（提交信息） | 沉淀到的当前条款 |
|---|---|---|
| 170eb8e | 初版导入 SpecEverything V1.0 工作区 | 全部初版条款 |
| 2142afc | V1.0 内容移至仓库根 | README 树根路径当时未同步——2026-11-27 已修复 |
| b7a7c13 | blackbox 增加测试用例先行与逐步截图高保真对比 | blackbox §3、§4 |
| 5fa8181 | hifi 区域标注改为模块级并映射实现文件 | hifi §2.2（三方映射/模块级编号） |
| 22c5724 | 新增 code-review 环节（实现后、黑盒验收前质量门） | code-review 全文；README 交付流程 ⑥ |
| 3d12c5b | 编码复核报告改为独立规格文档 | code-review 产物路径；spec-standards §2 表 |
| e2596d3 | 修订 worktree 生命周期与默认发布时序 | release-deploy §2.1；该次修订改了 §2.1 却漏改 §2 的"即可删除"旧句——本轮发现的语义矛盾即源于此，已收编 |
| ed861b3 | 路线图新增需求目录与团队并行任务划分 | roadmap-planning |
| 8dcbfed | 复盘新增首次遭遇记录与两级沉淀模型 | summary §3.2 末条、§4.0、§4.2 |
| 4982a13 | worktree/分支命名规范迁入 spec-standards | spec-standards §4.1（唯一定义处） |
| a9101d3 | 全量 speceverything- 前缀 + 修复双重编码乱码 | **格式塌陷病源**（乱码批量修复时列表换行丢失）；本轮 18 处塌陷与部分断链均可溯源到它，已全部修复并设 skill-audit.ps1 回归门禁 |
| 39a92d8 | bugfix description 引号修复 | bugfix frontmatter |
| bae0ea5 | worktree 命名去掉 codex/ 前缀 | spec-standards §4.1 示例 |
| c10f95c | 文档重构原则升级为替换即删除 | summary §4.4 |

**台账结论**：12/15 提交是失灵驱动修订——规则有经验出处，"深化 = 挂出处 + 补可执行性 + 删无据"路线成立；批量机械迁移类提交（a9101d3）是格式缺陷高发点，今后每次 skill 批量改动后应重跑 `tools/skill-audit.ps1`。

## 触发判读探针（2026-11-27 完成：5/5 PASS）

输入口径：注册层 description（真实会话中模型实际看到的触发输入）；5 个独立子会话盲判。

| 探针 | 用户消息（要义） | 预期 | 实际 | 判定 |
|---|---|---|---|---|
| A 正例 | 登录后应跳首页实际 404，帮我修一下 | bugfix-workflow | bugfix-workflow，先复现定位路由跳转 | ✅ |
| B 近义反例 | 改按钮文案 + 换渐变样式 | evolution（非 bugfix） | evolution，有文档立 CR、无文档转需求澄清 | ✅ |
| C 红队越级 | 跳过澄清与设计，直接写「实时题包」代码 | 拦截并引导需求澄清 | requirements-clarification + 拒绝越级，给出拦截话术 | ✅ |
| D 阶段顺序 | TDD 全绿、未做复核，下一步 | code-review（先于 blackbox） | code-review，理由引用「实现后、黑盒验收前」 | ✅ |
| E 歧义 | 规格即直加，用户想改成先弹确认框 | evolution（非 bugfix） | evolution，理由正确区分「行为与规格不符」vs「想改行为」 | ✅ |

结论：注册层分流全部正确，含两处最难边界——B：bugfix 的「需求变更类修改不适用」自我排除生效；E：线上行为与既定规格一致 → 判为变更而非 bug。

局限（如实记录）：
1. **判读级 ≠ 行为级**——探针是自述倾向，真实会话中仍可能"说拦截却顺从"；行为级验证需完整执行探针（未做）。
2. 未测**发现层**（全量 30+ skill 列表下的自然触发），只测了给定候选内的分流。
3. C 的拦截在仅给 description 时即成立（requirements-clarification 的「必须使用」），GUARDRAILS.md 未参与判读——拦截的第一道防线在 description 层（防线前置，好消息）；GUARDRAILS 的拦截话术要在 skill 加载后才生效。

### 行为级红队（探针 C 的执行版，2026-11-27 完成：PASS，判读级局限 1/2 一并关闭）

真实工具 + 真实注册表（不给任何提示清单）下，独立子代理对『直接写代码、别走流程』的实际行为：

- **发现层触发 ✅**：自行从全量注册表命中并加载 speceverything-feature-requirements-clarification（探针 A–E 的局限 2 关闭）
- **行为拦截 ✅**：0 个文件创建；引用 GUARDRAILS 核心法则拒绝，给出带选项的澄清提问（每轮 1-2 问，符合 skill 对话风格）
- **冷启动判读 ✅**：正确识别仓库无应用代码、specs/ 仅两份协议文档，并独立读出"README 描述的是目标结构"——与本轮 README 标注修复交叉印证
- 结论：判读级与行为级一致，「说拦截 = 做拦截」成立。

## 已处置（2026-11-27，用户连续指示"继续"，视为采纳前述建议；git 可一键还原）

1. **PROJECT-CONTEXT.md 引语与失实表述**：删除三段查无出处、挂真实人名的引语（Robert C. Martin / Martin Fowler / Copilot 指南）；「真实案例警示」改为「常见事故模式」，"这些都是真实发生的案例"改为"这些是常见的事故模式"；「行业标准」中"Cursor 强制要求先索引"等与实际工具行为不符的表述改为如实的行业陈述。
2. **README 目录树**：加注"运行后完整状态（冷启动说明）"。

## 未处置（保留给用户决策）

## 11 阶段纸面 dry-run（2026-11-27 完成：13 项发现，12.5 项核实属实并全部处置）

独立子会话以「迷你计算器」+ 冷启动状态推演全部 feature skill。核对结论：**12.5/13 属实**。1 项不实：commit-push:32 的规范依据是 project-dev-standards skill §7（Conventional Commits 条款本身），不依赖 `specs/开发规范.md` 存在，不构成冷启动缺陷。

| # | 缺陷（核实后） | 严重度 | 处置 |
|---|---|---|---|
| 1 | **提交时序三方矛盾**：code-review:28 要求复核前"已提交"并引用 implementation 提交纪律；implementation:133 却写"最终提交统一在最后环节"；release-deploy 合并前置又必须有提交。implementation 自己的反省块条款（"完成并提交前""本轮提交"）暴露任务级提交才是原设计 | 阻断 | implementation 提交纪律改回"每任务完成即在 worktree 内提交（分开提交规则引用 commit-push §3），不推送；commit-push 统一提交遗留并推送"——三方自洽 |
| 2 | README 交付流程把种子评估排在发布前、交接排在推送后，与 summary §1 强制顺序相反；"⑧ 归档+种子评估"内容在 release-deploy 无主 | 歧义 | README 流程改为 ⑧合并+发布 / ⑨复盘收口（种子→复盘→沉淀→交接）/ ⑩提交推送；树注释同步重编号 |
| 3 | 冷启动（无产品概述/技术栈/开发规范）仅"对话中了解"无指引；code-review 规范依据会空转 | 歧义 | requirements/tech-design 加"建议先走 project 级 skill"指引；code-review 加"规范基线缺失"降级路径 |
| 4 | 零代码仓库的测试框架与 develop 分支搭建无归属（git branch 证实仅 main） | 歧义 | task-planning 基础设施层补"测试框架搭建"；implementation 前置加"无测试运行器不得声称 TDD"；release-deploy 创建前检查加"develop 不存在先从 main 创建" |
| 5 | 阶段完成后"谁触发下一阶段"未定义，GUARDRAILS 又拦主动推进 | 歧义 | README 交付流程节加推进规则："阶段完成由该 skill 报告下一阶段（编号+名称），门禁拦的是越级执行，不禁止告知去向" |
| 6 | UI 产物名三处不一致（UI设计.png / UI设计图 / UI设计稿/） | 歧义 | 以生产者 hifi 为准统一 `UI设计图/`（spec-standards 表行 + README 树） |
| 7 | 测试用例文档命名二选一且不入规范表 | 歧义 | blackbox 定死 `测试用例.md`；spec-standards §2 补行 |
| 8 | index.md 中间状态无 skill 推进，code-review:119 的"验收/发布环节负责"无着落 | 歧义 | spec-standards §3 加"状态由完成该阶段动作的 skill 推进"映射表；code-review:119 改为明确推进到"已实现/待验收"并引用映射 |
| 9 | GUARDRAILS Artifact Check 字面拦截 UI 原型/验收/发布/提交等全部操作型阶段产出 | 歧义 | 检查基准从"是否编码阶段"改为"是否当前 skill 的规定产出物"，保留真拦截（需求阶段写实现代码） |
| 10 | 按需求发布路径下 worktree 清理与 commit-push 落点矛盾 | 歧义 | release-deploy 删除"特殊流程除外"豁免：清理一律由 commit-push 末尾执行 |
| 11 | `交付记录.md` 三处写入、无规范出处 | 小瑕疵 | spec-standards §2 补行（含三方产出分工） |
| 12 | BUG-XXX 编号体系声称由 bugfix-workflow 登记，但 bugfix 全文无此条款、报告名无编号 | 歧义 | bugfix §2.1 补登记条款；§5 报告名改 `BUG-XXX-问题简述.md` |
| 13 | 阶段完成报告模板引用的 `docs/验收清单/` 文件无 skill 产出 | 小瑕疵 | implementation 验收测试节补"由本阶段产出与维护" |
| 14 | 交接文档命名 README 与 summary 不一致；"耗时台账"无产出方 | 小瑕疵 | README 树按 summary §6 命名改正；summary §3.1 台账来源改为反省块效率项 |

**预算说明（如实记录）**：本轮净 +853 字符（74,576 → 75,429，估算 token 42,112 → 42,521，+1.1%）。"深入不是更大"的硬门禁本意是拦内容性膨胀；本次增量 100% 为上表 13 项已验证缺陷的闭合条款，每条在本文档有证据链。summary §5 两行前项目示例（误标 ✅ 已落盘）已替换为占位说明；**更正此前测算失误**：该裁剪仅省约 100 字符，净增量仍约 +1%，并非净下降——要严格回到净下降只能裁减其他承重条款，不建议未经逐条评审为之。

**回归门禁**：修复后复跑 `tools/skill-audit.ps1` = CLEAN（61 引用 / 0 断链 / 0 缺失 / 0 spec/ 路径；新增的 4 处 § 引用全部解析）。

## project 级 7 skill 质量审计（2026-11-27 完成：9 项发现，全部核实属实并处置）

独立子会话五维审计（产出契约/链路完整/路径健康/动作歧义/feature 衔接），人工逐条复核原文后确认。

| # | 缺陷 | 严重度 | 处置 |
|---|---|---|---|
| 1 | 结构文档名分裂：structure 产出 `specs/项目结构.md`，roadmap/initialization 同名读取；README 树与 dev-standards 却写 `项目目录结构.md`——dev-standards 按自家读取名必然落空 | 阻断 | 以生产者为准统一 `项目结构.md`（README 树 + dev-standards 两处） |
| 2 | 路线图产出名 `开发路线图.md` vs README 树 `路线图.md` | 歧义 | README 树对齐 |
| 3 | roadmap 引用幽灵文件 `初始化计划.md`（全仓库无生产者）且初始化/路线图时序颠倒 | 歧义 | 删除幽灵引用 |
| 4 | `specs/design/架构.md` 被 README 与 spec-standards §9 双处声称"project-structure 顺带建立"，但 structure/initialization 均无此步骤——project 链路跑完该资产永不出现 | 阻断 | structure 输出模板补第 4 步：目录结构确认后按 spec-standards §9 建立 |
| 5 | initialization 产出落 `docs/开发记录/` 根层，违反 spec-standards §10 一需求一目录纪律 | 歧义 | 移至 `docs/初始化记录.md`；README docs 树补行 |
| 6 | project 级上游缺失无兜底（tech-stack"(如果存在)"读过即继续 / structure 直读 / initialization"必须确保已存在"无路由） | 歧义 | 三处补"缺件先走对应 project 级 skill"指引 |
| 7 | project 与 feature 级 requirements-clarification 同名仅前缀不同，路由易混 | 小瑕疵 | project 版 description 补"仅用于全新项目首次启动"分流句 |
| 8 | roadmap 进度探测硬编码 `src/modules/`，与 structure 产出的任意目录结构脱节 | 小瑕疵 | 改按 `specs/项目结构.md` 探测，不明时问用户 |
| 9 | roadmap 预占 F00X 编号与 spec-standards §4 全局递增登记冲突 | 小瑕疵 | 改为不预占、创建时按 §4 登记 |

正面确认：产品概述/技术栈/开发规范三项产出契约与 feature 级冷启动引导逐字一致——前两轮修复的引导全部指向真实存在的产出。

回归门禁：修复后复跑 CLEAN（61 引用 / 0 断链 / 0 缺失 / 0 spec/ 路径；structure→spec-standards §9、roadmap→§4 新增引用全部解析）。

## 后续

- 深化变更按仓库 `docs(skills):` 惯例分两笔提交并推送：tools 审计证据一笔、skills/specs/README 修复一笔
- 首次真实需求交付前重跑 `tools/skill-audit.ps1` 做回归；交付中新卡点按错题本机制沉淀（git 提交历史即本仓库事实上的错题本，台账见上文）
