# MySQL 最佳实践

> 来源：阿里规约 + MySQL官方文档 + 生产环境经验

## 索引策略

### 联合索引最左前缀原则

索引 `idx_abc(a, b, c)` 可生效的查询：
- ✅ `WHERE a = 1`
- ✅ `WHERE a = 1 AND b = 2`
- ✅ `WHERE a = 1 AND b = 2 AND c = 3`
- ✅ `WHERE a = 1 AND c = 3`（a 走索引，c 不走，MySQL 8.0 ICP 可部分优化）
- ❌ `WHERE b = 2 AND c = 3`（缺少最左列 a）
- ❌ `WHERE c = 3`（缺少最左列 a）

### 覆盖索引设计

```sql
-- 查询
SELECT user_id, order_status FROM trade_order WHERE user_id = 1001;

-- 覆盖索引（查询字段全在索引中，不需要回表）
KEY idx_user_status (user_id, order_status)
```

### 索引失效场景清单

| 场景 | 反例 | 正例 |
|------|------|------|
| 函数计算 | `WHERE YEAR(create_time) = 2024` | `WHERE create_time >= '2024-01-01' AND create_time < '2025-01-01'` |
| 隐式转换 | `WHERE varchar_col = 123` | `WHERE varchar_col = '123'` |
| 左模糊 | `WHERE name LIKE '%张'` | 全文索引或搜索引擎 |
| OR 条件 | `WHERE a = 1 OR b = 2` | 分别查 + UNION |
| != / NOT | `WHERE status != 0` | `WHERE status > 0` |
| 计算表达式 | `WHERE id + 1 = 10` | `WHERE id = 9` |

### 慢查询诊断流程

1. 开启慢查询日志：`SET GLOBAL slow_query_log = ON; long_query_time = 1;`
2. 分析慢查询：`mysqldumpslow -s t /var/log/mysql/slow.log`
3. EXPLAIN 分析执行计划
4. 添加/调整索引
5. 验证优化效果

## 事务与锁

### 事务隔离级别

| 级别 | 脏读 | 不可重复读 | 幻读 | InnoDB默认 |
|------|------|-----------|------|-----------|
| READ UNCOMMITTED | ✅ | ✅ | ✅ | |
| READ COMMITTED | ❌ | ✅ | ✅ | |
| REPEATABLE READ | ❌ | ❌ | ✅(InnoDB防) | ✅ |
| SERIALIZABLE | ❌ | ❌ | ❌ | |

### 乐观锁 vs 悲观锁

| 方式 | 适用场景 | 实现 |
|------|---------|------|
| 乐观锁 | 读多写少、冲突少 | `version` 字段 + `UPDATE ... WHERE version = ?` |
| 悲观锁 | 写多、冲突多 | `SELECT ... FOR UPDATE` |

```sql
-- 乐观锁示例
UPDATE account SET balance = balance - 100, version = version + 1
WHERE id = 1 AND version = 5;

-- 悲观锁示例
SELECT * FROM account WHERE id = 1 FOR UPDATE;
UPDATE account SET balance = balance - 100 WHERE id = 1;
```

### 死锁处理

1. **检测** — `SHOW ENGINE INNODB STATUS` 查看死锁日志
2. **重试** — 业务层捕获死锁错误并重试（1205 错误码）
3. **预防** — 按固定顺序访问表和行

### SKIP LOCKED 队列模式

```sql
-- 拉取待处理任务（跳过已被其他线程锁定的行）
SELECT * FROM task_queue
WHERE status = 'pending'
ORDER BY create_time ASC
LIMIT 1
FOR UPDATE SKIP LOCKED;
```

## 分库分表

### 何时分

| 指标 | 阈值 |
|------|------|
| 单表行数 | > 500万 |
| 单表大小 | > 2GB |
| 慢查询无法优化 | 持续存在 |

### 跨片 JOIN 处理

1. **全局表** — 小表每个分片一份（如字典表）
2. **ER 分片** — 关联数据按相同分片键（如订单+订单明细按 user_id）
3. **应用层组装** — 分别查询后在应用层合并

### 分布式 ID

| 方案 | 优点 | 缺点 |
|------|------|------|
| Snowflake | 趋势递增、无依赖 | 时钟回拨问题 |
| 号段模式 | 简单可靠 | 依赖数据库 |
| UUID | 无依赖 | 无序、索引效率低 |

## 主从与读写分离

### 从库延迟检测

```sql
-- 主库执行
SHOW MASTER STATUS;

-- 从库执行
SHOW SLAVE STATUS;
-- 关注 Seconds_Behind_Master
```

### 读写一致性方案

| 方案 | 一致性 | 复杂度 |
|------|--------|--------|
| 强制走主库 | 强一致 | 低 |
| 半同步复制 | 较强 | 中 |
| GTID + 判断同步位 | 强 | 高 |

### 半同步复制配置

```sql
-- 主库
INSTALL PLUGIN rpl_semi_sync_master SONAME 'semisync_master.so';
SET GLOBAL rpl_semi_sync_master_enabled = ON;
SET GLOBAL rpl_semi_sync_master_timeout = 1000; -- 1秒超时降级

-- 从库
INSTALL PLUGIN rpl_semi_sync_slave SONAME 'semisync_slave.so';
SET GLOBAL rpl_semi_sync_slave_enabled = ON;
```

## 运维

### 关键参数

| 参数 | 推荐值 | 说明 |
|------|--------|------|
| innodb_buffer_pool_size | 物理内存 70-80% | InnoDB 缓冲池 |
| innodb_flush_log_at_trx_commit | 1 | 每次事务刷盘（安全） |
| sync_binlog | 1 | 每次事务刷 binlog（安全） |
| max_connections | (内存-BufferPool)/5MB | 避免连接数过高 |

### 慢查询日志

```sql
SET GLOBAL slow_query_log = ON;
SET GLOBAL long_query_time = 1; -- 超过1秒记录
SET GLOBAL log_queries_not_using_indexes = ON; -- 未用索引也记录
```

### 连接池管理

```sql
SHOW PROCESSLIST;           -- 当前连接
SHOW STATUS LIKE 'Threads%'; -- 线程状态
SHOW STATUS LIKE 'Max_used_connections'; -- 历史最大连接数
```

### 定期维护

```sql
-- 分析表（更新统计信息）
ANALYZE TABLE trade_order;

-- 优化表（重建表，回收碎片）
OPTIMIZE TABLE trade_order;  -- 锁表！大表用 pt-online-schema-change
```