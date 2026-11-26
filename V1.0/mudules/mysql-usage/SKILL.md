---
name: mysql-design
slug: mysql-design-adodo
displayName: MySQL 设计与使用助手
description: 帮助Agent为项目进行MySQL Schema设计、索引设计、查询设计，并提供场景化使用指南与技术目录树（数据库资产在仓库中的标准组织结构）。当用户需要设计数据库表结构、优化查询性能、规划分库分表方案、确定数据库脚本/迁移/种子的目录归属时触发。
version: 1.0.2
metadata:
  clawdbot:
    emoji: "🐬"
    requires:
      anyBins: ["mysql"]
    os: ["linux", "darwin"]
---

# MySQL 设计与使用助手

## 触发条件

当用户出现以下意图时激活本 Skill：
- 设计 MySQL 表结构 / Schema
- MySQL 索引优化 / 查询优化
- 分库分表方案
- 数据迁移方案
- "如何设计 xxx 的数据库"

## 设计流程（Agent 执行路径）

```
0. 版本检查 → 加载 references/version-major.md 对比用户版本，识别废弃项和重大变更。同时加载所有 version-X.Y.md（X.Y ≤ 用户目标版本），后续设计过程中 Agent 从已加载的上下文中自主匹配深度特性
1. 需求分析 → 理解业务实体和关系
2. 概念设计 → ER模型，识别实体/关系/属性
3. 规范约束 → 加载 references/design-spec.md，确保命名/字段/索引符合规范
4. 逻辑设计 → 表结构DDL，含索引/约束/注释
5. 物理设计 → 存储引擎/字符集/分区策略
6. 使用指引 → 加载 references/usage-guide.md，给出场景化操作
7. 优化建议 → 加载 references/best-practices.md，给出性能建议
8. 模板参考 → 加载 references/patterns.md，匹配业务模板
9. 目录归属 → 加载 references/directory-tree.md，确定迁移/种子/视图/文档的仓库目录与命名
```

## 快速参考

### 必备三字段

每张表必须包含：`id` (BIGINT UNSIGNED AUTO_INCREMENT) / `create_time` (DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP) / `update_time` (DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP)

### 命名铁律

| 对象 | 规范 | 示例 |
|------|------|------|
| 表名 | 小写+下划线，业务名_表作用 | `trade_order` |
| 字段名 | 小写+下划线 | `user_name` |
| 主键 | `pk_表名` | `pk_trade_order` |
| 唯一索引 | `uk_表名_字段` | `uk_user_email` |
| 普通索引 | `idx_表名_字段` | `idx_order_create_time` |
| 布尔字段 | `is_xxx` (TINYINT UNSIGNED) | `is_deleted` |

### 数据类型速查

| 场景 | 推荐 | 禁止 |
|------|------|------|
| 主键 | BIGINT UNSIGNED | INT 自增（范围不够） |
| 金额 | DECIMAL(18,2) | FLOAT / DOUBLE |
| 短字符串 (<256) | VARCHAR(n) | TEXT |
| 长文本 | TEXT（拆表） | 超长 VARCHAR |
| 定长字符串 | CHAR(n) | VARCHAR(1) |
| 布尔 | TINYINT UNSIGNED | BIT / BOOLEAN |
| 时间 | DATETIME / TIMESTAMP | VARCHAR 存时间 |
| 状态/枚举 | TINYINT UNSIGNED + COMMENT | ENUM |

### 索引核心原则

1. **唯一特性字段必须建唯一索引**
2. **超三表禁止 JOIN** — 在应用层组装
3. **VARCHAR 索引必须指定长度** — `idx_name(name(20))`
4. **禁止左模糊/全模糊查询** — 用全文索引或搜索引擎
5. **组合索引区分度高的在左** — `idx_status_created(status, created_at)`，status 区分度高
6. **覆盖索引避免回表** — 将查询字段纳入索引
7. **延迟关联优化超多分页** — 先查主键再关联

### 字符集

- **必须使用 utf8mb4**（utf8 是3字节，无法存 emoji）
- 排序规则：`utf8mb4_unicode_ci`（通用）/ `utf8mb4_bin`（精确匹配）
- JOIN 时 collation 必须一致

## 渐进式加载

详细内容按需加载 references/：

| 主题 | 文件 | 何时加载 |
|------|------|---------|
| Schema 设计规范（命名/字段/索引/范式） | `references/design-spec.md` | Step 3 规范约束 |
| 场景化操作指南（建表/DDL/优化/迁移/分表） | `references/usage-guide.md` | Step 6 使用指引 |
| 最佳实践（索引/事务/分库/主从/运维） | `references/best-practices.md` | Step 7 优化建议 |
| 业务 Schema 模板（6类业务完整DDL） | `references/patterns.md` | Step 8 模板参考 |
| **重大版本特性**（废弃/依赖变更/新模块） | `references/version-major.md` | Step 0 版本检查（模块激活时即加载） |
| **深度版本特性 — 9.0**（VECTOR/Event预编译） | `references/version-9.0.md` | Step 0 版本检查时自动加载（版本 ≤ 用户目标版本时） |
| **深度版本特性 — 8.0/8.4**（CTE/窗口函数/InnoDB参数/GTID标签） | `references/version-8.0.md` | Step 0 版本检查时自动加载（版本 ≤ 用户目标版本时） |
| **深度版本特性 — 5.7**（Native JSON/生成列/多源复制/sys Schema） | `references/version-5.7.md` | Step 0 版本检查时自动加载（版本 ≤ 用户目标版本时） |
| **深度版本特性 — 5.6**（GTID/InnoDB全文搜索/Online DDL/MTS） | `references/version-5.6.md` | Step 0 版本检查时自动加载（版本 ≤ 用户目标版本时） |

## 版本参考文档启用规则

1. **模块激活时** — 始终加载 `references/version-major.md`，Agent 需主动对比用户使用的 MySQL 版本，若存在废弃项或重大变更，立即提示用户
2. **深度特性 Step 0 自动加载** — 版本检查时加载所有 version-X.Y.md（X.Y ≤ 用户目标版本）。设计过程中 Agent 从已加载的上下文中自主检索匹配相关特性，用户无需指定版本号
3. **深度特性按大版本拆分，小版本持续追加** — 如 `version-8.0.md` 包含该大版本下所有小版本的设计级特性。更新时在文件中新增 `## X.Y.Z` 版本节即可，不单开文件

## 硬规则

1. 设计规范内容来自权威资料（阿里规约/MySQL官方文档），不编造
2. 所有 CREATE TABLE 必须包含 COMMENT（表注释 + 字段注释）
3. 所有表必须有主键（BIGINT UNSIGNED AUTO_INCREMENT 或分布式ID）
4. 禁止物理删除，使用 `is_deleted` 逻辑删除
5. 小数禁止用 FLOAT/DOUBLE，必须 DECIMAL
6. 表必须有 `create_time` 和 `update_time`
7. 单表超过 500 万行或 2GB 时必须考虑分库分表