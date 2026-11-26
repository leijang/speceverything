# MySQL 场景化使用指南

> 面向 Agent 执行的场景化操作指引，不是语法手册

## 场景1：从需求到建表

### 步骤

1. **分析业务实体** → 识别表/字段/关系
2. **按命名规范设计** → 表名/字段名
3. **按字段规范选择数据类型** → 参见 design-spec.md 数据类型决策树
4. **设计主键/唯一键/索引** → 参见 design-spec.md 索引规范
5. **输出完整 CREATE TABLE** → 含 COMMENT
6. **输出索引创建语句**

### 示例：设计用户表

```sql
CREATE TABLE `user_account` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_name` VARCHAR(64) NOT NULL COMMENT '用户名',
  `email` VARCHAR(128) NOT NULL COMMENT '邮箱',
  `password_hash` CHAR(60) NOT NULL COMMENT '密码哈希(bcrypt)',
  `phone` VARCHAR(20) DEFAULT NULL COMMENT '手机号',
  `avatar_url` VARCHAR(512) DEFAULT NULL COMMENT '头像URL',
  `status` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '状态: 0-禁用 1-正常',
  `is_deleted` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '是否删除: 0-否 1-是',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_email` (`email`),
  UNIQUE KEY `uk_user_name` (`user_name`),
  KEY `idx_user_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户账号表';
```

## 场景2：Schema 变更（DDL）

### 安全变更优先级

| 优先级 | 变更类型 | 风险 | 建议 |
|--------|---------|------|------|
| ✅ 安全 | ADD COLUMN | 低 | 直接执行 |
| ✅ 安全 | ADD INDEX | 低 | 使用 ONLINE DDL |
| ⚠️ 注意 | MODIFY COLUMN TYPE | 中 | 需双写迁移 |
| ⚠️ 注意 | DROP COLUMN | 高 | 先标记废弃，下个版本删 |
| ❌ 高危 | RENAME COLUMN | 高 | 需双写过渡 |
| ❌ 高危 | CHANGE CHARSET | 高 | 全表重建 |

### 大表变更操作流程

1. **评估变更影响** — 锁表风险/数据量/执行时间
2. **优先使用 ADDITIVE 变更** — 加列/加索引
3. **避免破坏性变更** — 删列/改类型需双写迁移
4. **大表使用 pt-online-schema-change**
5. **变更后验证** — 数据一致性/索引有效性

```bash
# pt-online-schema-change 示例
pt-online-schema-change \
  --alter "ADD COLUMN nickname VARCHAR(64) DEFAULT NULL COMMENT '昵称'" \
  --host=127.0.0.1 --port=3306 --user=root \
  D=mydb,t=user_account \
  --execute --max-load=Threads_running=100
```

## 场景3：查询优化

### 优化流程

1. **EXPLAIN 分析执行计划**
2. **识别问题** — type=index / ALL / Using filesort / Using temporary
3. **按索引规范调整** — 添加/修改索引
4. **验证优化效果**

### EXPLAIN 关键指标

| type 值 | 含义 | 优先级 |
|---------|------|--------|
| system/const | 最优 | ✅ |
| eq_ref | 唯一索引扫描 | ✅ |
| ref | 非唯一索引扫描 | ✅ |
| range | 索引范围扫描 | ✅ |
| index | 全索引扫描 | ⚠️ |
| ALL | 全表扫描 | ❌ 必须优化 |

### Extra 关键指标

| Extra 值 | 含义 | 建议 |
|-----------|------|------|
| Using index | 覆盖索引 | ✅ 理想 |
| Using where | WHERE 过滤 | 正常 |
| Using filesort | 额外排序 | ❌ 需优化 |
| Using temporary | 临时表 | ❌ 需优化 |
| Using index condition | ICP 下推 | ✅ 优化 |

### 延迟关联优化分页

```sql
-- ❌ 深分页性能差
SELECT * FROM trade_order ORDER BY id DESC LIMIT 100000, 10;

-- ✅ 延迟关联：先查主键再关联
SELECT o.* FROM trade_order o
INNER JOIN (
  SELECT id FROM trade_order ORDER BY id DESC LIMIT 100000, 10
) tmp ON o.id = tmp.id;
```

## 场景4：数据迁移

### 迁移方案选择

| 数据量 | 停机窗口 | 方案 |
|--------|---------|------|
| < 10万 | 有 | mysqldump + 导入 |
| < 100万 | 无 | 双写 + 增量同步 |
| > 100万 | 无 | Canal + 增量同步 |

### 双写迁移流程

1. **新表建好**，旧表不变
2. **应用双写** — 同时写旧表和新表
3. **历史数据迁移** — 分批导入（每批 5000 行）
4. **数据一致性校验** — COUNT + CHECKSUM
5. **读切到新表**
6. **停止双写**
7. **下线旧表**

## 场景5：分库分表

### 分表判定

| 指标 | 阈值 | 行动 |
|------|------|------|
| 单表行数 | > 500万 | 考虑分表 |
| 单表大小 | > 2GB | 考虑分表 |
| 慢查询占比 | > 10% | 必须分表 |

### 分片键选择原则

1. **高区分度** — 避免数据倾斜
2. **高频查询字段** — 尽量让查询落在一个分片
3. **避免跨片查询** — 关联数据尽量在同一分片

### 分片策略

| 策略 | 优点 | 缺点 | 适用场景 |
|------|------|------|---------|
| 范围分片 | 范围查询友好 | 热点问题 | 按时间分表 |
| 哈希分片 | 数据均匀 | 范围查询差 | 按用户ID分表 |

### 分布式 ID 方案

```sql
-- Snowflake ID：64位 = 1位符号 + 41位时间戳 + 10位机器 + 12位序列
-- 号段模式：从数据库批量获取 ID 段，本地分配
```