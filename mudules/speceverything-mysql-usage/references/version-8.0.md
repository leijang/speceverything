# MySQL 8.0 / 8.4 深度版本特性

> 加载时机：Step 0 版本检查时自动加载（本文件版本 ≤ 用户目标版本时加载）。

---

## 8.4.0 LTS (2024-04-30)

- **InnoDB 默认参数现代化**：`innodb_io_capacity` 200→10000（反映 SSD 能力），`innodb_adaptive_hash_index` ON→OFF（现代负载下收益低下），`innodb_change_buffering` all→none（SSD 下不必要），`innodb_log_buffer_size` 16MB→64MB（减少日志写频率），`innodb_flush_method`→O_DIRECT（减少 OS 缓存），`innodb_doublewrite_pages`→128（行为可预测）。 → 新部署项目默认配置即适配现代 SSD 硬件；从 8.0 升级到 8.4 时重点审查这些参数是否需要回退到旧值（HDD/低内存环境）。[[ref]](https://dev.mysql.com/doc/refman/8.4/en/)

- **`SOURCE_RETRY_COUNT` 默认值 60→10**：复制重试次数大幅减少，缩短故障转移等待时间。 → 主从切换后的恢复时间显著缩短；对瞬时网络抖动敏感的环境可能需要调大。[[ref]](https://dev.mysql.com/doc/refman/8.4/en/replication-options-replica.html)

- **自动直方图更新**：`ANALYZE TABLE table_name UPDATE HISTOGRAM ... AUTO UPDATE` 支持优化器统计信息按需自动更新。 → 无需再用 cron/event 定时重建直方图；数据分布频繁变化的表优先启用。[[ref]](https://dev.mysql.com/doc/refman/8.4/en/analyze-table.html)

- **GTID 标签**：`SET gtid_label=...` 为事务组打标签。 → 复制链路上追踪特定来源的事务；审计和排障场景中快速定位事务来源。[[ref]](https://dev.mysql.com/doc/refman/8.4/en/replication-gtids.html)

- **外键约束严格化**：`restrict_fk_on_non_standard_key` 默认 ON，父表被引用列必须有唯一键。 → 设计表结构时必须确保外键引用列为唯一索引；从 8.0 升级时检查不满足此约束的现有外键。[[ref]](https://dev.mysql.com/doc/refman/8.4/en/create-table-foreign-keys.html)

---

## 8.0.0 (2018-04)

- **CTE / 递归 CTE（WITH ... AS / WITH RECURSIVE）**：命名临时结果集 + 递归查询，替代存储过程遍历树形结构。 → 复杂 JOIN 拆分为命名子查询；邻接表（parent_id）结构的层级查询用递归 CTE 作为标准方式，不需要引入"路径枚举"冗余字段。[[ref]](https://dev.mysql.com/doc/refman/8.0/en/with.html)

- **Window Functions（ROW_NUMBER / RANK / SUM OVER / LAG / LEAD）**：不分组情况下进行排名、累计、滑动计算。 → 排行榜、按分类取前 N 条无需应用层组装；财务报表累计/移动平均下推到 SQL 层；LAG/LEAD 简化连续登录天数、同比环比等场景。[[ref]](https://dev.mysql.com/doc/refman/8.0/en/window-functions.html)

- **JSON_TABLE()**：JSON 列转换为关系表格式，参与标准 SQL 查询（JOIN、WHERE、聚合）。 → 核心查询字段仍建议用关系列存储；可变属性/嵌套结构用 JSON 列 + JSON_TABLE() 展开查询；生成列 + 索引可作为 JSON 查询的性能加速。[[ref]](https://dev.mysql.com/doc/refman/8.0/en/json-table-functions.html)

- **Roles（CREATE ROLE）**：权限集合授予角色，角色授予用户，简化多用户权限管理。 → 定义角色体系（app_readonly / app_readwrite / app_admin）；应用账号按角色授权不要逐个配置；微服务中每个服务一个账号 + 仅授予所需角色。[[ref]](https://dev.mysql.com/doc/refman/8.0/en/roles.html)

- **原子 DDL**：数据字典统一为 InnoDB 事务表，DDL 操作支持原子回滚。 → 迁移脚本可将多个相关 DDL 放在一个事务中；降低迁移失败时数据库处于半变更状态的风险；注意并非所有 DDL 都支持原子操作，使用前需确认。[[ref]](https://dev.mysql.com/doc/refman/8.0/en/atomic-ddl.html)

- **Resource Groups（CPU 资源隔离）**：创建资源组分配 CPU 亲和性，不同连接/线程绑定到不同资源组。 → 多租户 SaaS：高优先级租户分配专用 CPU 资源组；读写分离：OLTP 查询和报表分配到不同资源组；仅控制 CPU 不控制 IO。[[ref]](https://dev.mysql.com/doc/refman/8.0/en/resource-groups.html)

- **字符集默认 utf8mb4_0900_ai_ci**：新默认排序规则基于 Unicode 9.0，区别于旧默认 utf8mb4_general_ci。 → 新项目直接使用默认值不需显式指定；迁移时注意排序行为差异；需要精确匹配时使用 utf8mb4_bin；JOIN 字段间排序规则必须一致。[[ref]](https://dev.mysql.com/doc/refman/8.0/en/charset-unicode-sets.html)

---

> 8.0.x 自 8.0.34 起仅接收 Bug 修复和安全补丁，不再引入新特性。8.4 LTS 为当前建议的生产版本。
> 本文件仅收录影响 Schema/架构设计的特性。Bug 修复、安全补丁、底层优化等不在收录范围内。
