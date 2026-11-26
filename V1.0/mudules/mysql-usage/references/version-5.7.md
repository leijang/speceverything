# MySQL 5.7 深度版本特性

> 加载时机：Step 0 版本检查时自动加载（本文件版本 ≤ 用户目标版本时加载）。

---

## 5.7.0 (2015-10-19)

- **Native JSON 数据类型**：二进制格式存储 JSON（非纯文本），自动校验 RFC 7159 合规性。支持 `->` / `->>` 路径操作符和 `JSON_EXTRACT()`、`JSON_SET()`、`JSON_ARRAY()`、`JSON_OBJECT()` 等函数族。 → 早期 JSON 存储方案可在 MySQL 内部直接实现；但缺少 JSON_TABLE()（需到 8.0），复杂 JSON 查询仍受限。[[ref]](https://dev.mysql.com/doc/refman/5.7/en/json.html)

- **生成列 + 函数索引（VIRTUAL / STORED）**：`GENERATED ALWAYS AS (expr) VIRTUAL` 列不占存储，定义表达式后可在其上建索引（即函数索引）。STORED 列物理存储可做主键/FULLTEXT。 → JSON 字段的常用路径可提取为 VIRTUAL 列并建索引加速查询；表达式索引无需应用层冗余。[[ref]](https://dev.mysql.com/doc/refman/5.7/en/create-table-generated-columns.html)

- **InnoDB 缓冲池在线调整**：`SET GLOBAL innodb_buffer_pool_size = ...` 动态调整无需重启。 → 云环境/容器环境按需伸缩缓冲池；监控内存使用后可实时优化。[[ref]](https://dev.mysql.com/doc/refman/5.7/en/innodb-buffer-pool-resize.html)

- **多源复制**：`CHANGE MASTER TO ... FOR CHANNEL 'channel_name'`，一个从库从多个主库汇聚复制。 → 数据聚合/分库合并到中心分析库场景；每个 channel 独立管理复制状态。[[ref]](https://dev.mysql.com/doc/refman/5.7/en/replication-multi-source.html)

- **sys Schema**：基于 Performance Schema 的内置诊断视图（`sys.schema_*`、`sys.statement_analysis` 等），提供可读性强的性能报告。 → 日常性能诊断不需手动查询 Performance Schema 原始表；慢查询分析、冗余索引检测开箱即用。[[ref]](https://dev.mysql.com/doc/refman/5.7/en/sys-schema.html)

- **`ONLY_FULL_GROUP_BY` 默认启用 + SQL99 函数依赖**：SELECT 列表中的非聚合列必须出现在 GROUP BY 中或与 GROUP BY 列函数依赖。 → 设计查询时必须遵循更严格的 SQL 标准；避免 "偷取随机行" 的常见 bug；MySQL 5.7+ 迁移时需检查遗留查询。[[ref]](https://dev.mysql.com/doc/refman/5.7/en/sql-mode.html)

- **Online DDL 扩展**：更多 ALTER TABLE 操作支持 `ALGORITHM=INPLACE`，包括 VARCHAR 扩展、重命名列等。 → 大表变更的停机窗口缩小；但仍需检查具体操作是否支持 INPLACE。[[ref]](https://dev.mysql.com/doc/refman/5.7/en/innodb-online-ddl.html)

---

> 本文件仅收录影响 Schema/架构设计的特性。Bug 修复、安全补丁、底层优化等不在收录范围内。
