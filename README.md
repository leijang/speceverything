# SpecEverything V1.0

规格驱动的 AI 协作工作区。核心理念：**每一个结论都有可核对的证据，每一步交付都可追溯、可复现**。

## 这套 skill 的特点与优势

### 1. 每步有主导——不会走偏

一个需求十个阶段（需求→设计→技术→拆解→TDD→复核→验收→发布→复盘→落库），每个阶段**只有一个 skill 主导**：它独占定义该步骤的产出物格式与质量门禁。横切纪律（编号/目录/命名）由唯一定义处持有，冲突以它为准。第三方过程工具只做受约束参与（中间态，不替代产出物）——**AI 不会在错误的阶段做错误的事**。

### 2. 默认连续推进——不需要反复说"继续"

阶段间衔接**不设节奏门**——skill 完成即报告即进入，把人的参与留给真正需要判断的时刻（设计定稿、验收结论、方案级问题裁决）。一次全流程交付只需 3 次人工介入，而非 10 次。

### 3. 十节机械门禁——每条规则都有可伪造的验证

| 检查 | 拦什么 |
|---|---|
| §1 引用完整性 | 跨 skill 引用断链 |
| §2 模板存在性 | 引用了不存在的文档模板 |
| §3 路径约定 | `spec/` 单数路径混入 |
| §4 预算门禁 | SKILL 库篇幅失控 |
| §5 mudules 目录树 | 技术实践库缺必需文件 |
| §6 双定义检测 | 同一条规范句写了两个文件（漂移前夜） |
| §7 CJK 脚本编码 | PS 5.1 静默劣化中文字面量 |
| §8 索引状态枚举 | 状态名不在合法集合内 |
| §9 提交信息规范 | 非 Conventional Commits |
| §10 Agent Skills 合规 | frontmatter 字段/name/description 违反开放标准 |

全部确定性、任何人复跑同结果——**审计本身也被变异测试验证**（11 处植入缺陷全捕获）。

### 4. 领号制——多会话并行不撞号

编号不靠"查快照取最大"（竞态），靠**登记册领号**：`git fetch` → 在 `specs/编号登记册.md` 登记 → 立即推送 origin/develop → 推送成功即持有。两会话同时领号？后推方跳号顺延，不冲突、不覆盖。

### 5. 发布互斥——多会话不互踩

发布执行前三查（分支一致/服务器前值/发布锁），任一不满足即停手报告——不会两会话同时备发布共享一个 swap 通道互踩。

### 6. 出处或删除——没有愿景式条款

每条规则要么挂**真实失灵事件**（git 台账、错题本、交付痕迹），要么挂**可伪造门禁**（机械检查、判读探针）。两者都不是的条款一律删除——执行密度 64/64 = 100%，零待审。

### 7. Agent Skills 开放标准——跨工具即插即用

- 23 个第一方 skill 位于标准发现路径 `.agents/skills/`（junction 指向 git 源，仓库一改全局即生效）
- 11 个第三方 UI skill 包（ibelick/ui-skills，MIT）vendor 入库随克隆分发
- 任何按标准扫描的工具（Claude Code / Codex / Cursor / OpenCode…）都能发现并按描述自主调用

### 8. 错题本有牙齿——同类问题不出现第三次

每条错题沉淀**可核对的预防措施**（默认规则、机械检查项、审计门禁），不只是记录个案。已被机械化的陷阱：PS 5.1 编码三坑（BOM / stderr / 控制台解码）、生成物易变字段、行列表同名遮蔽——全部有审计节拦截。

### 9. Token 经济——常驻成本核算到位

- 注册层（23 条 description）+ 协议层 + vendor 目录 ≈ 4,800 tokens/轮常驻
- 全部 skill 正文按需加载（progressive disclosure），单次触发成本最大 4,539 tokens
- 估算公式经实测校准：偏低系数 1.298，绝对值按 ×1.3 读数

### 10. 会话可定位——领号后标题即地址

领号后立即更新会话标题为「编号-名称-日期」（OpenCode 经 `session.rename`），多会话并行时侧边栏一眼定位每个会话在做什么需求、哪个变更、什么日期。

### 与常见 AI 编码工作流的区别

| 常见工作流 | SpecEverything |
|---|---|
| AI 直接写代码，事后补文档 | 先需求 AC → 再设计定稿 → 再技术方案 → 才写代码 |
| 写完说"搞定了" | 十阶段各产出物落盘，证据双轨（磁盘+会话展示），验收逐 AC 留证 |
| 改了就改了 | 变更走 CR 编号，行为与规格不符走 BUG 编号，两者不混用 |
| 门禁靠自觉 | 十节机械审计 + 变异自证 + 24 个 Pester 用例，任何人一条命令复验 |
| 说"下次注意" | 错题本带可核对预防措施，审计门禁机械化拦截 |
| 需求/方案/代码散落各处 | 一个需求一个规格目录，编号/状态/文档全部入索引 |
| 每步都要人说"继续" | 默认连续推进，只在不可替代的人工确认点停下 |

## 目录结构

> 下图为**运行后完整状态**：`specs/` 与 `docs/` 下除 PROJECT-CONTEXT.md、GUARDRAILS.md 外的文档均由各阶段 skill 在实际交付中生成。首个需求 **F001（审计变异测试）已于 2026-11-27 完成全流程交付**（证据：`specs/features/F001-审计变异测试-20261127/交付记录.md`）；树中其余示例路径仍为示意结构，由后续需求逐目录落成。

```text
D:\Src\SpecEverything\
│
├── README.md                        # 本文件：工作区总览
│
├── specs/                           # 规格体系（唯一事实源）
│  ├── PROJECT-CONTEXT.md           #   项目上下文强制协议（每个 skill 必读）
│  ├── GUARDRAILS.md                #   边界守卫：阶段拦截规则与话术
│  ├── 产品概述.md                  #   产品愿景/用户/场景（project 阶段产出）
│  ├── 技术栈.md                    #   技术选型结论
│  ├── 项目结构.md              #   模块划分与依赖方向
│  ├── 开发路线图.md                #   开发顺序与里程碑
│  ├── 开发规范.md                  #   代码规范 + AI 协作协议（§3 含错题本机制）
│  ├── 错题本.md                    #   缺陷沉淀：现象/根因/修复/预防（可核对的拦截措施）
│  ├── design/
│  │  └── 架构.md                  #   全局架构图（Mermaid：模块职责 + 依赖方向（spec-standards §9）
│  └── features/
│      ├── index.md                 #   需求索引：编号/名称/状态（规划中→…→已完成）
│      ├── F001-实时题包-20261120/  #   每个需求一个独立目录（编号递增不复用）
│      │  ├── 需求说明.md          #     主文档：AC-XXX（GWT，三类场景）
│      │  ├── UI设计图/            #     高保真原型 + 区域标注图（feature-hifi-design）
│      │  ├── 技术方案.md          #     开发思路 + 架构图 + 数据流程图 + API/DB（tech-design）
│      │  ├── 任务规划.md          #     Task-XX 垂直切片 + 验证标准 + 执行反省块
│      │  ├── 变更任务_CR-001-XX.md#     变更登记（feature-evolution）
│      │  ├── 编码复核.md            #     代码复核三维度结论（feature-code-review）
│      │  ├── 验收截图/            #     F001-AC003-移动端选中状态.png（blackbox-test）
│      │  ├── 过程复盘.md          #     效率损失排查 + 改进闭环（feature-summary）
│      │  └── 交付记录.md          #     提交哈希/发布记录/种子评估结论
│      └── F002-…
│
├── docs/
│  ├── 初始化记录.md              #   项目初始化记录（project-initialization）
│  └── 开发记录/
│      └── F001-实时题包-20261120/  #   一需求一目录（与 specs/features 目录同名）
│          ├── F001_阶段1_完成报告.md    #   阶段完成报告（feature-implementation）
│          ├── F001_阶段2_完成报告.md
│          └── 交接-YYYYMMDD-F001清完.md          #   会话交接文档（feature-summary）
│
├── skills/                          # Skill 库（本文档 §Skill 一览）
│  ├── standard/
│  │  └── speceverything-spec-standards/          #   规格创建规范唯一定义处
│  │      └── SKILL.md
│  ├── speceverything-bugfix-workflow/
│  │  ├── SKILL.md                 #   Bug 修复：根因决策顺序、最小改动、不兜底
│  │  └── assets/
│  │      └── bugfix-report-template.md
│  ├── feature/                     #   功能级：一个需求从生到死的各阶段执行器
│  │  ├── speceverything-feature-requirements-clarification/  # ① 需求对话与 AC
│  │  ├── speceverything-feature-hifi-design/                 # ② UI 设计稿（原型 + 标注图）
│  │  ├── speceverything-feature-tech-design/                 # ③ 技术方案（三要素 + 全局架构同步）
│  │  ├── speceverything-feature-task-planning/               # ④ 任务拆分（垂直切片）
│  │  ├── speceverything-feature-implementation/              # ⑤ TDD 实现（七问反省块）
│  │  ├── speceverything-feature-code-review/                  # ⑥ 代码复核（过度设计/架构/规范三维度）
│  │  ├── speceverything-feature-blackbox-test/                # ⑦ 真实用户模拟验收（证据双轨）
│  │  ├── speceverything-feature-release-deploy/              # ⑧ 合并 + 发布（worktree 模型唯一定义处）
│  │  ├── speceverything-feature-summary/                     # ⑨ 复盘收口：复盘/沉淀/交接（含 2 个模板）
│  │  ├── speceverything-feature-commit-push/                 # ⑩ 提交与推送（最末环节）
│  │  └── speceverything-feature-evolution/                   # 变更流程（CR-XXX）
│  └── project/                     #   项目级：启动与技术治理
│      ├── speceverything-project-requirements-clarification/  # 启动需求澄清
│      ├── speceverything-project-product-overview/            # 产品概述
│      ├── speceverything-project-tech-stack/                  # 技术选型
│      ├── speceverything-project-structure/                   # 目录结构（顺带建立全局架构）
│      ├── speceverything-project-roadmap-planning/            # 路线图
│      ├── speceverything-project-dev-standards/               # 开发规范（AI 协作协议）
│      └── speceverything-project-initialization/              # 初始化执行
│
├── mudules/                         # 技术最佳实践库（约定见 mudules/README.md）
│  └── <tech>-usage/                #   SKILL.md + references/（必含技术目录树 *directory-tree*.md）
│      └── references/
│
└── tools/                           # 机械门禁与复用资产：skill-audit.ps1（十节审计）· skill-mutate.ps1（变异自证）· tests/（24 用例 + golden 锚点）· measure-tokens.py（token 实测校准）· 台账与审计证据；改动 skill 库后先跑审计再提交
└── .agents/                          # 双层 skills/：23 个指向仓库源目录的 junction（机器本地，不入库）+ 12 个 vendor 第三方 skill 包（11 个 UI + diagram-design 架构/流程图，**入库**，来源/SHA/许可证见 .agents/skills/VENDORED.md，随克隆分发给所有按标准扫描的工具）；worktrees/ = 代理工具临时工作区（内容全忽略）
```

## 交付流程（一个需求的完整生命周期）

```
① 需求分析 → ② UI 设计稿 → ③ 技术设计 → ④ 任务规划 → ⑤ 实现(TDD) → ⑥ 代码复核 → ⑦ 黑盒验收
→ ⑧ 合并 + 发布（worktree 合并 develop 后发布 develop）
→ ⑨ 复盘收口（种子数据评估 → 过程复盘 → 知识沉淀 → 会话交接）
→ ⑩ 提交与推送（统一提交遗留变更、推送、清理 worktree）
```

每个阶段由一个 feature skill 执行；跨阶段的横切纪律（规格目录与索引、worktree 模型、验收证据、收口门禁）由对应 skill 作为唯一定义处持有。

每个阶段完成时，由该阶段 skill 报告下一阶段（编号 + 名称）并**直接进入**——门禁拦的是**内容越级**（在错误的阶段做错误的事），不是**节奏停顿**（每步等人推）。用户随时可说"停"中断。

**默认连续推进。** 仅在以下不可替代的人工确认点停下等用户点头：
- ② **设计定稿**——用户点头才能进技术设计（hifi-design 自身门禁）
- ⑦ **验收结论**——用户确认才能进合并发布（blackbox-test 自身门禁）
- 复盘中发现 **C2 方案性问题 / C3 行为与规格不符**——需用户裁决路由
- ③④⑥ 中发现**多种可行方案各有利弊**且影响核心行为——列出推荐继续，用户反对才停
- 用户明确说"停"

其余一切阶段间衔接**不设节奏门**——skill 完成即报告即进入，把人的参与留给真正需要判断的时刻。

**设计原则（主导权三层分工）**：每个开发步骤由一个对应的 skill **主导**——它是该步骤唯一的执行主导与产出物定义者；横切纪律由唯一定义处 skill 持有（见下表，冲突以它为准）；第三方过程工具（如 vendor 的 ui-skills、diagram-design 架构/流程图）只做受约束的**参与**（一律为中间态，见 hifi-design 产出物节与 tech-design 图示增强节）——参与不改变主导权、强制产出物与定稿门禁。

**无 UI 需求的路由**：阶段②（hifi-design）的适用门禁是其注册层 description「需求涉及 UI、界面、页面、交互、原型、设计稿」——纯 CLI/后端需求跳过②，跳过判定在会话中留痕，⑨ 复盘核对路由依据（出处：F001 试交付发现，README 线性流程曾未定义跳过路径）。

## Skill 一览

### 功能级（skills/feature/）

| Skill | 职责 | 关键条款 |
|---|---|---|
| speceverything-feature-requirements-clarification | 需求对话与 AC 产出 | AC 编号 + Given-When-Then；规格目录 `specs/features/XXX-功能名称-YYYYMMDD/` 与 `index.md` 索引状态；编号交流必须「编号 + 名称」。 |
| speceverything-feature-hifi-design | 高保真 UI 设计 | 设计稿先于技术方案；原型与标注图当即在会话中渲染展示，经用户定稿才可继续 |
| speceverything-feature-tech-design | 技术方案（含开发思路/架构图/数据流程图三要素） | 每条 AC 必须在方案中有着落（→ AC-XXX 追溯）。 |
| speceverything-feature-task-planning | 任务拆分 | 垂直切片；每个 AC 可追溯到至少一个任务。 |
| speceverything-feature-implementation | TDD 实现 | 无失败测试不写实现；每任务七问反省块；业务/测试分开提交；不推翻技术方案。 |
| speceverything-feature-code-review | 代码复核（黑盒验收前的质量门） | 三维度：过度设计逐项清点 / 架构符合性 / 规范符合性；C1 直接修、C2 回技术方案、C3 走 bugfix-workflow；不通过不得进入验收 |
| speceverything-feature-blackbox-test | 真实用户模拟验收 | 真实入口按 AC 操作；截图磁盘留证 + 会话展示双轨不可替代；多终端/交互流/多档位全覆盖 |
| speceverything-feature-evolution | 需求变更 | 变更走 CR 编号流程；行为与既定规格不符走 bugfix-workflow，两者不混用 |
| speceverything-feature-release-deploy | worktree 分支模型 + 上线发布 | 一需求一 worktree（含清理与需求数据库隔离，唯一定义处）；只从 main 发布；发布记录齐全才可声明上线完成。 |
| speceverything-feature-commit-push | 提交与推送（feature 最末环节，复盘沉淀之后落库） | 变更清单核对 + 秘密扫描；业务/测试分开提交（唯一定义处）；收口提交后**二次合并 develop**再清理 worktree；推送后核对远端；完成后才可宣告交付全部结束 |
| speceverything-feature-summary | 复盘与沉淀（流程收口） | 种子数据评估 → 过程复盘 → 知识沉淀 → 会话交接；四步未完成不得标记交付全部完成 |

### 项目级（skills/project/）

| Skill | 职责 |
|---|---|
| speceverything-project-requirements-clarification | 项目启动需求澄清 |
| speceverything-project-product-overview | 产品概述文档 |
| speceverything-project-tech-stack | 技术选型 |
| speceverything-project-structure | 目录结构设计 |
| speceverything-project-roadmap-planning | 开发路线图 |
| speceverything-project-dev-standards | 开发规范（含 AI 协作协议与错题本机制） |
| speceverything-project-initialization | 项目初始化执行 |

### 其他

- **speceverything-spec-standards**：规格创建规范唯一定义处——规格目录 `specs/features/XXX-功能名称-YYYYMMDD/`、各阶段文档命名、`index.md` 索引状态、编号体系与编号交流规则。
- **speceverything-bugfix-workflow**：根因决策顺序、最小改动、无根因不兜底（记错题本「待查」）。

## 横切纪律的唯一定义处

| 纪律 | 定义处 |
|---|---|
| 规格目录结构与各阶段文档命名 | speceverything-spec-standards §1–§2 |
| 索引状态与编号体系、编号交流规则 | speceverything-spec-standards §3–§6 |
| AC 质量标准（编号/GWT/三类场景） | speceverything-feature-requirements-clarification |
| worktree 分支模型与命名 | speceverything-feature-release-deploy §2 |
| 开发记录目录（docs/开发记录：一需求一目录） | speceverything-spec-standards §10 |
| worktree 生命周期与需求数据库隔离 | speceverything-feature-release-deploy §2.1 / §2.2 |
| TDD 铁律、回归口径、任务反省块 | speceverything-feature-implementation |
| 代码复核三维度与处置路由（C1/C2/C3） | speceverything-feature-code-review |
| 提交纪律（业务/测试分开提交）与推送核对 | speceverything-feature-commit-push §3–§5 |
| 验收证据纪律（双轨：磁盘 + 会话展示） | speceverything-feature-blackbox-test §4 |
| 种子数据评估、过程复盘、会话交接、收口门禁 | speceverything-feature-summary |
| 错题本条目格式 | speceverything-feature-summary §7 |
| 阶段边界与越界拦截 | specs/GUARDRAILS.md + 各 skill 自带边界声明 |
| 全局架构资产（specs/design/架构.md）与同步义务 | speceverything-spec-standards §9 + speceverything-feature-tech-design 全局架构同步条款 |
| 项目上下文强制读取 | specs/PROJECT-CONTEXT.md |
| 技术最佳实践检索（mudules/*-usage，未命中则官方文档） | speceverything-feature-tech-design 前置条件·技术实践检索 |

## 关键约定

- **编号交流**：提及 F00X / CR-XXX / BUG-XXX / Task-XX / AC-XXX 时必须同时给出名称。
- **领号制**：选号 = 领号——在 `specs/编号登记册.md` 登记一行并**立即提交推送** origin/develop，推送成功即持有；选号前必须 `git fetch` 以登记册为准（详见 spec-standards 第 4.2 节）。领号后立即更新会话标题为「编号-名称-日期」。
- **默认连续推进**：阶段间衔接不设节奏门——skill 完成即报告即进入；仅在 ②设计定稿、⑦验收结论、C2/C3 路由点、用户说"停"时停下。
- **发布互斥**：发布执行前必须依次核对分支一致性/服务器前值/发布锁，任一不满足即停手报告（release-deploy 第 2.3 节）。
- **证据双轨**：验收截图既要落盘到规格目录 `验收截图/`，也要当即在会话中渲染给用户看。
- **收口门禁**：种子评估、复盘、交接文档未完成时，不得声明"交付流程全部完成"；禁止 force 删除等绕过手段。
- **错题本**：`specs/错题本.md`，条目**尾部追加**（禁止顶部插入），条目必须沉淀"可核对的预防措施"，同类问题第三次出现前必须有规则拦截。
