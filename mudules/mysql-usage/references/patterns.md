# 常见业务 Schema 模板

> Agent 可直接参考修改的完整 DDL 模板

## 1. 用户系统

```sql
-- 用户账号表
CREATE TABLE `user_account` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_name` VARCHAR(64) NOT NULL COMMENT '用户名',
  `email` VARCHAR(128) NOT NULL COMMENT '邮箱',
  `password_hash` CHAR(60) NOT NULL COMMENT '密码哈希(bcrypt)',
  `phone` VARCHAR(20) DEFAULT NULL COMMENT '手机号',
  `status` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '状态: 0-禁用 1-正常',
  `is_deleted` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '是否删除: 0-否 1-是',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_email` (`email`),
  UNIQUE KEY `uk_user_name` (`user_name`),
  KEY `idx_user_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户账号表';

-- 用户资料表
CREATE TABLE `user_profile` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
  `nickname` VARCHAR(64) DEFAULT NULL COMMENT '昵称',
  `avatar_url` VARCHAR(512) DEFAULT NULL COMMENT '头像URL',
  `gender` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '性别: 0-未知 1-男 2-女',
  `birthday` DATE DEFAULT NULL COMMENT '生日',
  `bio` VARCHAR(500) DEFAULT NULL COMMENT '个人简介',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_profile_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户资料表';

-- 用户认证表（多方式登录）
CREATE TABLE `user_auth` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
  `auth_type` TINYINT UNSIGNED NOT NULL COMMENT '认证类型: 1-密码 2-微信 3-支付宝',
  `auth_id` VARCHAR(128) NOT NULL COMMENT '第三方标识(openid等)',
  `auth_token` VARCHAR(512) DEFAULT NULL COMMENT '认证令牌',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_auth_type_id` (`auth_type`, `auth_id`),
  KEY `idx_auth_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户认证表';
```

## 2. 订单系统

```sql
-- 订单主表
CREATE TABLE `trade_order` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `order_no` VARCHAR(32) NOT NULL COMMENT '订单号',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT '下单用户ID',
  `total_amount` DECIMAL(18,2) NOT NULL COMMENT '订单总金额',
  `discount_amount` DECIMAL(18,2) NOT NULL DEFAULT 0.00 COMMENT '优惠金额',
  `pay_amount` DECIMAL(18,2) NOT NULL COMMENT '实付金额',
  `status` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '状态: 0-待支付 1-已支付 2-已发货 3-已完成 4-已取消 5-已退款',
  `pay_time` DATETIME DEFAULT NULL COMMENT '支付时间',
  `deliver_time` DATETIME DEFAULT NULL COMMENT '发货时间',
  `complete_time` DATETIME DEFAULT NULL COMMENT '完成时间',
  `remark` VARCHAR(500) DEFAULT NULL COMMENT '备注',
  `is_deleted` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '是否删除: 0-否 1-是',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  KEY `idx_order_user` (`user_id`),
  KEY `idx_order_status_created` (`status`, `create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单主表';

-- 订单明细表
CREATE TABLE `trade_order_item` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `order_id` BIGINT UNSIGNED NOT NULL COMMENT '订单ID',
  `product_id` BIGINT UNSIGNED NOT NULL COMMENT '商品ID',
  `product_name` VARCHAR(256) NOT NULL COMMENT '商品名称(冗余)',
  `product_price` DECIMAL(18,2) NOT NULL COMMENT '商品单价(冗余)',
  `quantity` INT UNSIGNED NOT NULL DEFAULT 1 COMMENT '购买数量',
  `subtotal` DECIMAL(18,2) NOT NULL COMMENT '小计金额',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_item_order` (`order_id`),
  KEY `idx_item_product` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单明细表';

-- 支付记录表
CREATE TABLE `trade_payment` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `order_id` BIGINT UNSIGNED NOT NULL COMMENT '订单ID',
  `pay_no` VARCHAR(64) NOT NULL COMMENT '支付流水号',
  `pay_method` TINYINT UNSIGNED NOT NULL COMMENT '支付方式: 1-微信 2-支付宝 3-银行卡',
  `pay_amount` DECIMAL(18,2) NOT NULL COMMENT '支付金额',
  `status` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '状态: 0-待支付 1-成功 2-失败 3-已退款',
  `pay_time` DATETIME DEFAULT NULL COMMENT '支付完成时间',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_pay_no` (`pay_no`),
  KEY `idx_payment_order` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='支付记录表';
```

> **分表建议**：`trade_order` 按 `user_id` 哈希分 16 表（order_0 ~ order_15），`trade_order_item` 随订单同分片

## 3. 内容管理

```sql
-- 文章表
CREATE TABLE `cms_article` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `title` VARCHAR(256) NOT NULL COMMENT '标题',
  `author_id` BIGINT UNSIGNED NOT NULL COMMENT '作者ID',
  `category_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '分类ID',
  `summary` VARCHAR(500) DEFAULT NULL COMMENT '摘要',
  `content` TEXT NOT NULL COMMENT '正文内容',
  `cover_url` VARCHAR(512) DEFAULT NULL COMMENT '封面图URL',
  `status` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '状态: 0-草稿 1-已发布 2-已下架',
  `view_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '浏览量',
  `like_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '点赞数',
  `is_deleted` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '是否删除: 0-否 1-是',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_article_author` (`author_id`),
  KEY `idx_article_category` (`category_id`),
  KEY `idx_article_status_created` (`status`, `create_time`),
  FULLTEXT KEY `ft_article_title_content` (`title`, `content`) WITH PARSER ngram
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='文章表';

-- 分类表
CREATE TABLE `cms_category` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `parent_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '父分类ID(0=顶级)',
  `name` VARCHAR(64) NOT NULL COMMENT '分类名称',
  `sort_order` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '排序值',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_category_parent` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='分类表';

-- 标签表
CREATE TABLE `cms_tag` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` VARCHAR(64) NOT NULL COMMENT '标签名称',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_tag_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='标签表';

-- 文章-标签关联表
CREATE TABLE `cms_article_tag` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `article_id` BIGINT UNSIGNED NOT NULL COMMENT '文章ID',
  `tag_id` BIGINT UNSIGNED NOT NULL COMMENT '标签ID',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_article_tag` (`article_id`, `tag_id`),
  KEY `idx_tag_article` (`tag_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='文章-标签关联表';
```

## 4. 配置系统

```sql
-- 系统配置表
CREATE TABLE `sys_config` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `config_key` VARCHAR(128) NOT NULL COMMENT '配置键',
  `config_value` VARCHAR(2048) NOT NULL COMMENT '配置值',
  `config_type` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '值类型: 0-字符串 1-数字 2-JSON 3-布尔',
  `description` VARCHAR(256) DEFAULT NULL COMMENT '配置说明',
  `is_deleted` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '是否删除: 0-否 1-是',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_config_key` (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统配置表';

-- 功能开关表
CREATE TABLE `sys_feature_flag` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `flag_key` VARCHAR(128) NOT NULL COMMENT '开关键',
  `is_enabled` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '是否启用: 0-否 1-是',
  `description` VARCHAR(256) DEFAULT NULL COMMENT '开关说明',
  `rollout_percent` TINYINT UNSIGNED NOT NULL DEFAULT 100 COMMENT '灰度百分比: 0-100',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_flag_key` (`flag_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='功能开关表';
```

> **缓存策略**：配置表数据全量缓存到 Redis，变更时主动失效

## 5. 日志审计

```sql
-- 操作日志表（按月分区）
CREATE TABLE `sys_audit_log` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '操作人ID',
  `user_name` VARCHAR(64) DEFAULT NULL COMMENT '操作人姓名(冗余)',
  `action` VARCHAR(64) NOT NULL COMMENT '操作类型(如 CREATE_USER/DELETE_ORDER)',
  `resource_type` VARCHAR(64) NOT NULL COMMENT '资源类型',
  `resource_id` VARCHAR(64) DEFAULT NULL COMMENT '资源ID',
  `detail` TEXT DEFAULT NULL COMMENT '操作详情(JSON)',
  `ip` VARCHAR(45) DEFAULT NULL COMMENT 'IP地址(兼容IPv6)',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_audit_user` (`user_id`),
  KEY `idx_audit_action` (`action`),
  KEY `idx_audit_resource` (`resource_type`, `resource_id`),
  KEY `idx_audit_created` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='操作日志表'
PARTITION BY RANGE (TO_DAYS(create_time)) (
  PARTITION p202601 VALUES LESS THAN (TO_DAYS('2026-02-01')),
  PARTITION p202602 VALUES LESS THAN (TO_DAYS('2026-03-01')),
  PARTITION p202603 VALUES LESS THAN (TO_DAYS('2026-04-01')),
  PARTITION p_future VALUES LESS THAN MAXVALUE
);
```

> **归档方案**：超过 6 个月的分区使用 `ALTER TABLE ... DROP PARTITION` 归档到归档库

## 6. 社交关系

```sql
-- 好友关系表
CREATE TABLE `social_friendship` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
  `friend_id` BIGINT UNSIGNED NOT NULL COMMENT '好友ID',
  `status` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '状态: 0-待确认 1-正常 2-已拉黑',
  `remark` VARCHAR(64) DEFAULT NULL COMMENT '好友备注',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_friendship` (`user_id`, `friend_id`),
  KEY `idx_friend_user` (`friend_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='好友关系表';

-- 关注关系表
CREATE TABLE `social_followship` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `follower_id` BIGINT UNSIGNED NOT NULL COMMENT '关注者ID',
  `followee_id` BIGINT UNSIGNED NOT NULL COMMENT '被关注者ID',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_follow` (`follower_id`, `followee_id`),
  KEY `idx_follow_followee` (`followee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='关注关系表';
```

> **分库建议**：按 `user_id` 哈希分库，确保同一用户的好友/关注数据在同一库