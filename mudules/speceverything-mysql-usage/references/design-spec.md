# MySQL Schema 设计规范

> 来源：阿里巴巴Java开发手册 MySQL数据库规约 + MySQL官方文档 + 数据库设计范式

## 一、命名规范（来源：阿里规约 建表规约）

| # | 规则 | 正例 | 反例 |
|---|------|------|------|
| 1 | 表名/字段名小写+下划线，禁止大写/数字开头 | `user_info` | `UserInfo` / `user1_info` |
| 2 | 表名不使用复数名词 | `user` | `users` |
| 3 | 禁用保留字（desc/range/match/key 等） | `description` | `desc` |
| 4 | 表名：业务名_表作用 | `trade_order` | `order` |
| 5 | 索引命名：pk_/uk_/idx_ | `uk_user_email` | `index_email` |
| 6 | 布尔字段 is_xxx (TINYINT UNSIGNED) | `is_deleted` | `deleted` |
| 7 | 小数类型 is_xxx 命名（1=是/0=否） | `is_vip` | `vip_flag` |
| 8 | 禁止同名不同类型字段 | 全局一致 | `id` INT vs `id` VARCHAR |
| 9 | 长度不要超 30 字符 | `user_profile` | `user_profile_and_settings_table` |

## 二、字段设计规范（来源：阿里规约 建表规约 + MySQL官方文档）

### 必备三字段

```sql
`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
`create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
`update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
PRIMARY KEY (`id`)
```

### 数据类型选择决策树

```
需要存什么？
├── 整数 → 范围多大？
│   ├── 0~255 → TINYINT UNSIGNED
│   ├── 0~65535 → SMALLINT UNSIGNED
│   ├── 0~1677万 → MEDIUMINT UNSIGNED
│   ├── 0~42亿 → INT UNSIGNED
│   └── 更大 → BIGINT UNSIGNED
├── 小数 → 精确？
│   ├── 是（金额等）→ DECIMAL(M,D)
│   └── 否（科学计算）→ DOUBLE（仅此场景允许）
├── 字符串 → 多长？
│   ├── <256字符 → VARCHAR(n)
│   ├── 256~5000 → VARCHAR(n)（考虑拆表）
│   └── >5000 → TEXT（必须拆表）
├── 定长 → CHAR(n)（如 MD5=CHAR(32)）
├── 时间 → DATETIME（范围大）/ TIMESTAMP（4字节，范围小）
├── 布尔 → TINYINT UNSIGNED (0/1)
└── 状态/枚举 → TINYINT UNSIGNED + COMMENT
```

### 字段规范清单

1. **小数用 DECIMAL，禁 FLOAT/DOUBLE** — 浮点精度丢失
2. **VARCHAR ≤ 5000**，超长用 TEXT 且必须拆表
3. **定长字符串用 CHAR** — 如 UUID(36)、MD5(32)、手机号(11)
4. **逻辑删除 is_deleted**，禁止物理删除
5. **合适的存储长度** — UNSIGNED 优先，节约空间和索引
6. **禁止 ENUM** — 用 TINYINT + COMMENT 替代，ENUM 修改需 DDL
7. **TEXT/BLOB 独立拆表** — 避免主表行过大影响查询性能
8. **金额字段 DECIMAL(18,2)** — 整数部分16位够全球GDP，小数2位够精度
9. **状态字段必须有 COMMENT 说明含义** — `status TINYINT UNSIGNED COMMENT '0-待支付 1-已支付 2-已取消'`

## 三、索引设计规范（来源：阿里规约 索引规约）

### 必须建索引的场景

1. **唯一特性字段必须建唯一索引** — 即使是业务唯一键
2. **WHERE 条件字段** — 高频查询过滤字段
3. **ORDER BY / GROUP BY 字段** — 利用索引有序性
4. **JOIN 关联字段** — 关联字段必须索引，且类型一致
5. **区分度高的字段优先** — 组合索引区分度高的在左

### 索引禁止/限制

1. **超三表禁止 JOIN** — 在应用层组装数据
2. **VARCHAR 索引必须指定长度** — `idx_name(name(20))`
3. **禁止左模糊/全模糊查询** — 无法使用索引
4. **单表索引数 ≤ 5 个** — 个别不超过 6 个
5. **组合索引字段数 ≤ 5 个**
6. **禁止在区分度低的字段上建索引** — 如 `is_deleted` 区分度太低

### 索引优化技巧

1. **覆盖索引** — 将查询字段纳入索引，避免回表
2. **延迟关联** — 超多分页时先查主键再关联
3. **ORDER BY 利用索引有序性** — 避免 filesort
4. **避免索引失效** — 函数/隐式转换/左模糊/OR/!= 都会使索引失效

## 四、范式与反范式

### 第三范式核心原则
- 每个非主属性不传递依赖于主键
- 消除冗余，保证数据一致性

### 何时适当反范式

| 场景 | 策略 |
|------|------|
| 高频读取，低频修改 | 冗余字段减少 JOIN |
| 一致性要求不高 | 缓存/冗余提高读性能 |
| 统计/报表 | 预计算/汇总表 |

### 冗余字段三原则（来源：阿里规约）

1. **不频繁修改** — 避免一致性问题
2. **不超长** — 不增加存储负担
3. **非唯一索引字段** — 冗余不是为索引服务

## 五、字符集与排序规则

| 配置项 | 推荐 | 原因 |
|--------|------|------|
| 字符集 | `utf8mb4` | utf8 仅3字节，无法存emoji和特殊字符 |
| 排序规则（通用） | `utf8mb4_unicode_ci` | 不区分大小写，多语言友好 |
| 排序规则（精确） | `utf8mb4_bin` | 区分大小写，精确匹配 |
| JOIN collation | 必须一致 | 不一致导致索引失效 |