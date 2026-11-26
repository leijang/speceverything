# MySQL 5.6 深度版本特性

> 加载时机：Step 0 版本检查时自动加载（本文件版本 ≤ 用户目标版本时加载）。

---

## 5.6.0 (2013-02-05)

- **GTID（全局事务标识符）**：每事务分配唯一 ID（server UUID + 递增计数器），`CHANGE MASTER TO MASTER_AUTO_POSITION = 1` 替代手动指定 file + position。 → 主从切换不需手动计算日志位点；多层级复制拓扑管理简化；mysqldump 自动处理 GTID 状态；5.6 默认关闭需显式启用。[[ref]](https://dev.mysql.com/doc/refman/5.6/en/replication-gtids.html)

- **InnoDB 全文搜索**：InnoDB 表支持 `FULLTEXT` 索引（此前仅 MyISAM 支持），`MATCH ... AGAINST` 查询。 → 不再为全文搜索保留 MyISAM 表；InnoDB 的 ACID + FULLTEXT 可在同一张表共存。[[ref]](https://dev.mysql.com/doc/refman/5.6/en/innodb-fulltext-index.html)

- **Online DDL**：`ALTER TABLE ... ALGORITHM=INPLACE, LOCK=NONE` 在修改表结构时不阻塞读写。支持的操作：添加/删除二级索引、修改列默认值、修改 AUTO_INCREMENT 值等。 → 大表变更无需停机；但仍有有限操作需要表复制（如修改列类型、添加 FULLTEXT 索引）。[[ref]](https://dev.mysql.com/doc/refman/5.6/en/innodb-online-ddl.html)

- **Performance Schema 默认启用**：语句执行细节、阶段耗时、表IO/锁等待、用户/主机聚合统计。 → 性能问题诊断有开箱即用的仪表盘；Cloud 环境下可按用户/主机计费；开销可控（5.6 优化了 5.5 的 P_S 实现）。[[ref]](https://dev.mysql.com/doc/refman/5.6/en/performance-schema.html)

- **MTS（多线程从库）**：`slave_parallel_workers = N` 按 Schema（库）粒度并行应用 relay log。 → 多库场景从库延迟大幅降低；注意跨库事务/级联更新在 MTS 下需 `slave_preserve_commit_order`（5.7+）保证顺序。[[ref]](https://dev.mysql.com/doc/refman/5.6/en/replication-options-slave.html)

- **ICP / BKA / MRR 优化器增强**：索引条件下推（ICP）在存储引擎层过滤 WHERE 条件减少回表；批量键访问（BKA）批量收集 JOIN 键；多范围读取（MRR）排序后批量读取减少随机 IO。 → 联合查询/范围查询性能提升无需应用层改写；默认启用 ICP 和 MRR，BKA 通过 `optimizer_switch` 控制。[[ref]](https://dev.mysql.com/doc/refman/5.6/en/index-condition-pushdown-optimization.html)

- **微秒精度时间类型**：`DATETIME(6)`、`TIMESTAMP(6)`、`TIME(6)` 支持微秒精度。 → 高精度时间戳（如金融交易/日志顺序）存于单列而非拆分秒+微秒两列。[[ref]](https://dev.mysql.com/doc/refman/5.6/en/fractional-seconds.html)

- **可传输表空间**：`FLUSH TABLES t FOR EXPORT` 生成 `.cfg` 文件，配合 `.ibd` 文件跨服务器复制导入。 → 大表迁移不需要 mysqldump；表空间级恢复和 PITR 场景更高效；注意需 `innodb_file_per_table = ON`。[[ref]](https://dev.mysql.com/doc/refman/5.6/en/tablespace-copying.html)

---

> 本文件仅收录影响 Schema/架构设计的特性。Bug 修复、安全补丁、底层优化等不在收录范围内。
