# MySQL 9.0 深度版本特性

> 加载时机：Step 0 版本检查时自动加载（本文件版本 ≤ 用户目标版本时加载）。

---

## 9.0.0 (2024-07-01)

- **VECTOR 数据类型**：原生向量存储，支持固定维度向量（如 `VECTOR(5000)`）和 `STRING_TO_VECTOR` / `VECTOR_TO_STRING` 转换函数。向量只能与向量做相等比较，不能用作任何类型的键。 → 向量检索需求不大的场景可直接用 MySQL 而非引入专用向量数据库；向量列应与业务表放在一起避免跨库 JOIN；大规模（>100 万）或低延迟（<10ms）场景仍需专用向量数据库。[[ref]](https://dev.mysql.com/doc/refman/9.0/en/vector.html)

- **Event 预编译支持**：CREATE EVENT / ALTER EVENT / DROP EVENT 支持 PREPARE 预编译语句。 → 定时任务可通过参数化方式动态创建和修改，提升 SQL 注入防护和运行效率。

---

## 9.1.0 (2024-10-15)

- **EXPLAIN 增强**：EXPLAIN 输出更详细的查询执行信息。 → 新型查询的优化分析更精准，排查慢查询时参考 EXPLAIN 新字段。

---

## 9.7.0 — LTS (2026-04-21)

- **Hypergraph Optimizer 下放 Community Edition**：基于超图动态规划的 Join 优化器，支持 bushy join plans 和基于成本的 nested-loop vs hash join 选择。默认关闭，通过 `SET optimizer_switch='hypergraph_optimizer=on'` 开启。EXPLAIN 仅支持 FORMAT=TREE 和 FORMAT=JSON。 → 复杂多表 JOIN 场景可评估启用；简单 OLTP 查询可能回归，需基于实际 workload 测试；EXPLAIN 格式变更影响现有查询分析工具。[[ref]](https://dev.mysql.com/doc/refman/9.7/en/mysql-releases.html)

- **Dynamic Data Masking（企业版）**：列级数据脱敏策略直接绑定基表列，无需视图。CURRENT_USER_IN() / CURRENT_ROLE_IN() 作为门禁函数。 → 替代视图级脱敏方案，关闭基表直接查询侧信道；合规/隐私场景简化实现。[[ref]](https://blogs.oracle.com/mysql/dynamic-data-masking-in-mysql-protect-sensitive-data-without-app-changes)

- **JSON Duality Views 完整 DML（Community Edition）**：INSERT/UPDATE/DELETE + auto-increment 支持从企业版下放。 → JSON 文档视图的 CRUD 完整可用，文档+关系混合应用开发更便捷。[[ref]](https://blogs.oracle.com/mysql/the-hypergraph-optimizer-is-now-available-in-mysql-9-7-community-edition)

- **多重企业功能下放 Community Edition**：Replication Applier Metrics、Group Replication 流控统计、Telemetry Component、MLE WASM 库支持（CREATE LIBRARY ... LANGUAGE WASM）。 → Community Edition 功能显著增强，缩小与企业版差距。[[ref]](https://www.infoq.com/news/2026/05/mysql-97-lts/)

- **InnoDB Atomic I/O 生产就绪**：支持原子写入的 NVMe SSD 上自动禁用 Doublewrite Buffer，消除 100% 双写写放大。 → 新硬件上 InnoDB 存储效率大幅提升；评估硬件是否支持原子写入。[[ref]](https://dev.mysql.com/doc/refman/9.7/en/innodb-doublewrite-buffer.html)

- **OpenID 认证插件**：新增 OpenID Connect 认证支持。 → SSO 集成更标准化，替代自定义认证方案。[[ref]](https://dev.mysql.com/doc/refman/9.7/en/authentication-openid-connect.html)

- **Plugin API 弃用 → Component 框架迁移**：Plugin API 整体弃用，所有扩展向 Component 框架迁移。Keyring Plugin、Enterprise Firewall Plugin 等受影响。 → 评估现有插件依赖的迁移路径。[[ref]](https://dev.mysql.com/doc/refman/9.7/en/mysql-releases.html)

---

> 本文件仅收录影响 Schema/架构设计的特性。Bug 修复、安全补丁、底层优化等不在收录范围内。
