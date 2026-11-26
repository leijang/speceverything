# MySQL 重大版本特性

> 加载时机：模块被启用时加载，用于对比用户使用的 MySQL 版本，提示废弃/重大变更。

---

## 9.7.0 — LTS (2026-04-21)

### 废弃

- **Plugin API 整体弃用**：所有插件向 Component 框架迁移，Keyring Plugin、Enterprise Firewall Plugin 等逐步替换。
- **MD5() / SHA1() 弃用**：计划在未来版本中移除。

### 新增重要模块/功能

- **Hypergraph Optimizer 下放 Community Edition**：基于超图动态规划的 Join 优化器，默认关闭。EXPLAIN 仅支持 FORMAT=TREE 和 FORMAT=JSON。
- **Dynamic Data Masking（企业版）**：列级脱敏策略直接绑定基表列，无需视图。CURRENT_USER_IN() / CURRENT_ROLE_IN() 门禁。
- **JSON Duality Views 完整 DML（Community Edition）**：INSERT/UPDATE/DELETE 完整支持。
- **多重企业功能下放 Community Edition**：Replication Applier Metrics、Group Replication 流控统计、Telemetry、MLE WASM 库。
- **InnoDB Atomic I/O 生产就绪**：支持原子写入的 NVMe SSD 自动禁用 Doublewrite Buffer。
- **OpenID 认证插件**：标准 OpenID Connect 认证支持。

---

## 9.0.0 — Innovation (2024-07-01)

### 废弃

- **`mysql_native_password` 认证插件完全删除**：8.0 中已弃用，9.0 彻底移除。升级前必须将用户账户迁移至 `caching_sha2_password`。

### 新增重要模块/功能

- **VECTOR 数据类型**：原生向量列存储，支持固定维度向量和基本相似度计算函数（`STRING_TO_VECTOR`、`VECTOR_TO_STRING`）。不能用作键，只能与其他向量做相等比较。
- **JavaScript 存储程序（仅企业版/HeatWave）**：支持基于 JavaScript 编写存储过程和函数。

---

## 8.4.0 — LTS (2024-04-30)

### 废弃

- **`FLUSH HOSTS` 移除**：改用 `TRUNCATE TABLE performance_schema.host_cache`。

### 依赖变更

- **InnoDB 默认参数大幅调整**以适应现代硬件（SSD/大内存）：`innodb_io_capacity` 200→10000，`innodb_adaptive_hash_index` ON→OFF，`innodb_change_buffering` all→none，`innodb_log_buffer_size` 16MB→64MB，`innodb_flush_method`→O_DIRECT。

### 新增重要模块/功能

- **自动直方图更新**：`ANALYZE TABLE ... AUTO UPDATE`，优化器统计信息可自动维护。
- **GTID 标签**：允许为事务组打标签，改善复制事务跟踪与审计。
- **外键约束更严格**：父表被引用列必须有唯一键（`restrict_fk_on_non_standard_key` 默认 ON）。

---

## 8.0.0 (2018-04，持续更新至 8.0.34+ 仅修复)

### 废弃

- **`utf8mb3` 字符集逐步废弃** → 统一使用 `utf8mb4`。
- **自 8.0.34 起转入仅 Bug 修复模式**，不再引入新特性。

### 新增重要模块/功能

- **CTE / 递归 CTE**：WITH ... AS 命名子查询 + WITH RECURSIVE 处理树形层级数据。
- **Window Functions**：ROW_NUMBER / RANK / SUM OVER / LAG / LEAD 等分析函数。
- **JSON_TABLE()**：JSON 列转关系表参与标准 SQL 查询。
- **Roles（角色权限）**：CREATE ROLE 角色级权限管理。
- **原子 DDL**：数据字典统一为 InnoDB 事务表，DDL 支持原子回滚。
- **Resource Groups**：CPU 资源按连接/线程分配隔离。
- **默认字符集 utf8mb4 + utf8mb4_0900_ai_ci**：Unicode 9.0 排序规则为默认。

---

## 5.7.0 (2015-10-19)

### 废弃

- **`mysql_old_password` 认证插件移除** → 统一使用 `mysql_native_password`（后被 8.0+ 的 `caching_sha2_password` 替代）。
- **MyISAM 临时表** → 内部临时表默认使用 InnoDB。

### 新增重要模块/功能

- **Native JSON 数据类型**：二进制格式存储 JSON，自动校验 RFC 7159，`->` / `->>` 路径操作符，JSON_SET/JSON_EXTRACT 等函数族。
- **生成列（Generated Columns）**：`VIRTUAL` 列不占存储可建索引（函数索引），`STORED` 列物理存储。
- **InnoDB 缓冲池动态调整**：`innodb_buffer_pool_size` 在线调整无需重启。
- **多源复制**：一个从库同时从多个主库复制。
- **sys Schema**：内置性能诊断视图集（基于 Performance Schema）。
- **`ONLY_FULL_GROUP_BY` + SQL99 函数依赖检测**：默认启用，更严格的 GROUP BY 校验。

---

## 5.6.0 (2013-02-05)

### 新增重要模块/功能

- **GTID（全局事务标识符）**：每个事务唯一标识（server UUID + 递增计数），自动故障转移无需手动计算日志位点。
- **InnoDB 全文搜索**：InnoDB 表原生 FULLTEXT 索引（此前仅 MyISAM 支持）。
- **Online DDL**：`ALTER TABLE ... INPLACE` 不阻塞 DML。
- **Performance Schema 默认启用**：语句/阶段/表IO/表锁/用户级别的性能仪表盘。
- **多线程从库（MTS）**：按 Schema 并行应用 relay log 事件。
- **ICP / BKA / MRR**：索引条件下推、批量键访问、多范围读取三个优化器增强。
- **微秒精度时间**：TIME / TIMESTAMP / DATETIME 支持小数秒（`DATETIME(6)`）。
- **可传输表空间**：`FLUSH TABLES ... FOR EXPORT` 表空间文件跨服务器复制。
