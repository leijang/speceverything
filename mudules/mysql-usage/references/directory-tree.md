# MySQL 技术目录树（数据库资产组织）

> 来源：MySQL 官方文档（https://dev.mysql.com/doc/ ，Schema Object & Data Directory 章节）与社区迁移管理惯例。本文件规定**仓库侧**数据库资产的目录组织，与宿主项目 `specs/项目目录结构.md` 冲突时以项目定制为准。

## 1. 仓库内数据库资产树

```text
database/
├── migrations/                      # ① 版本化迁移脚本（唯一事实源，按序执行）
│   ├── V001__init_schema.sql        #   命名：V<三位序号>__<动作>_<对象>.sql
│   ├── V002__add_orders_table.sql
│   └── V003__alter_users_add_phone.sql
├── seeds/                           # ② 种子数据（环境划分，幂等可重放）
│   ├── common/                      #   所有环境：枚举字典、主数据
│   │   ├── S001_dict_colors.sql
│   │   └── S002_roles.sql
│   └── dev/                         #   仅开发/演示环境：示例数据
│       └── S001_demo_users.sql
├── routines/                        # ③ 存储过程 / 函数 / 触发器（按对象分文件）
│   ├── procedures/
│   ├── functions/
│   └── triggers/
├── views/                           # ④ 视图定义（一视图一文件）
├── baseline/
│   └── schema_<版本>.sql            # ⑤ 基线快照：全量 schema 导出，供新环境快速初始化
└── docs/
    ├── er.md                        # ER 图（Mermaid erDiagram）
    └── decisions.md                 # 库表设计决策记录（为何这样建索引/分区）
```

## 2. "放哪里"决策表

| 产物 | 归属 | 禁止位置 |
|---|---|---|
| 建表/改表/删表 DDL | `migrations/`（新版本化脚本） | 直接改 baseline、散落代码目录 |
| 字典表/主数据/权限初始化 | `seeds/common/`（幂等） | migrations 里混入业务演示数据 |
| 示例/演示数据 | `seeds/dev/`（不进生产） | seeds/common |
| 存储过程/函数/触发器 | `routines/` + 对应 migrations 注册 | 只存在于线上库无仓库副本 |
| 视图 | `views/` + migrations | 只在库端手工建 |
| 全量 schema 快照 | `baseline/`（工具导出，不手写） | 手工维护两份"真相" |
| ER 图/设计决策 | `database/docs/` | 聊天记录、本地便签 |
| 业务查询 SQL（应用内） | 应用代码的数据访问层 | database/ 目录 |

## 3. 版本与命名规范

- **迁移命名**：`V<三位递增序号>__<动词>_<对象>.sql`，如 `V012__add_index_orders_created_at.sql`；序号不复用、不回填。
- **种子命名**：`S<序号>_<内容>.sql`；必须幂等（`INSERT ... ON DUPLICATE KEY UPDATE` 或先删后插）。
- **迁移内禁止**：`DROP DATABASE`、明文口令、对生产数据的一次性手工修补（走 bugfix/变更流程）。
- **基线更新时机**：每完成一个里程碑（feature-release-deploy 发布后）重新导出，旧基线保留到 git 历史。

## 4. 与宿主项目的衔接

- ORM 管理的迁移（如 EF Core Migrations）以 ORM 机制为准，本树的 `migrations/` 存放**手工 SQL 与数据订正**；两者不可混用同一张表。
- 种子数据的实现约定（框架播种机制优先、禁止手工插一次性数据）见 feature-summary §2 / feature-implementation。
- Schema/索引/查询设计规范见 `design-spec.md` 与 `best-practices.md`。
