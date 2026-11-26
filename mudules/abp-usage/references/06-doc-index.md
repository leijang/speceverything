# ABP 官方文档索引

> 基址：https://abp.io/docs/latest/ （本 Skill 从该文档提炼；引用时直接打开对应链接）。以下列出框架核心文档；其余主题（UI 各框架、测试、CLI、部署、Solution Templates、Modules 预构建模块文档）按官方文档目录浏览。

## Framework / Architecture（分层与最佳实践）

- [Best Practices（总入口）](https://abp.io/docs/latest/framework/architecture/best-practices)
- [Entities](https://abp.io/docs/latest/framework/architecture/best-practices/entities) — 实体
- [Repositories](https://abp.io/docs/latest/framework/architecture/best-practices/repositories) — 仓储
- [Domain Services](https://abp.io/docs/latest/framework/architecture/best-practices/domain-services) — 领域服务
- [Application Services](https://abp.io/docs/latest/framework/architecture/best-practices/application-services) — 应用服务
- [Data Transfer Objects](https://abp.io/docs/latest/framework/architecture/best-practices/data-transfer-objects) — DTO
- [Data Access](https://abp.io/docs/latest/framework/architecture/best-practices/data-access-overview) / [EF Core Integration](https://abp.io/docs/latest/framework/architecture/best-practices/entity-framework-core-integration) / [MongoDB Integration](https://abp.io/docs/latest/framework/architecture/best-practices/mongodb-integration) — 数据访问
- [Module Architecture](https://abp.io/docs/latest/framework/architecture/best-practices/module-architecture) — 模块架构
- [Domain-Driven Design](https://abp.io/docs/latest/framework/architecture/domain-driven-design) — DDD 教程全篇（entities、value-objects、domain-services、repositories、specifications、unit-of-work、application-services、data-transfer-objects）
- [Modularity Basics](https://abp.io/docs/latest/framework/architecture/modularity/basics) / [Plugin Modules](https://abp.io/docs/latest/framework/architecture/modularity/plugin-modules) / [Customizing Modules](https://abp.io/docs/latest/framework/architecture/modularity/extending/customizing-application-modules-guide)（扩展实体、重写服务、替换 UI）
- [Multi-Tenancy](https://abp.io/docs/latest/framework/architecture/multi-tenancy) — 多租户
- [Microservices](https://abp.io/docs/latest/framework/architecture/microservices)

## Framework / Fundamentals

[Application Startup](https://abp.io/docs/latest/framework/fundamentals/application-startup) · [Dependency Injection](https://abp.io/docs/latest/framework/fundamentals/dependency-injection) · [Autofac](https://abp.io/docs/latest/framework/fundamentals/autofac-integration) · [Options](https://abp.io/docs/latest/framework/fundamentals/options) · [Configuration](https://abp.io/docs/latest/framework/fundamentals/configuration) · [Authorization](https://abp.io/docs/latest/framework/fundamentals/authorization)（+ [Resource-Based](https://abp.io/docs/latest/framework/fundamentals/authorization/resource-based-authorization)）· [Validation](https://abp.io/docs/latest/framework/fundamentals/validation) · [FluentValidation](https://abp.io/docs/latest/framework/fundamentals/fluent-validation) · [Exception Handling](https://abp.io/docs/latest/framework/fundamentals/exception-handling) · [Localization](https://abp.io/docs/latest/framework/fundamentals/localization) · [URL-Based Localization](https://abp.io/docs/latest/framework/fundamentals/url-based-localization) · [Caching](https://abp.io/docs/latest/framework/fundamentals/caching) · [Redis Cache](https://abp.io/docs/latest/framework/fundamentals/redis-cache) · [Logging](https://abp.io/docs/latest/framework/fundamentals/logging) · [Connection Strings](https://abp.io/docs/latest/framework/fundamentals/connection-strings) · [Dynamic Claims](https://abp.io/docs/latest/framework/fundamentals/dynamic-claims) · [Object Extensions](https://abp.io/docs/latest/framework/fundamentals/object-extensions)

## Framework / Infrastructure

[Event Bus](https://abp.io/docs/latest/framework/infrastructure/event-bus)（[Local](https://abp.io/docs/latest/framework/infrastructure/event-bus/local) / [Distributed](https://abp.io/docs/latest/framework/infrastructure/event-bus/distributed) + [RabbitMQ](https://abp.io/docs/latest/framework/infrastructure/event-bus/distributed/rabbitmq) / [Kafka](https://abp.io/docs/latest/framework/infrastructure/event-bus/distributed/kafka) / [Rebus](https://abp.io/docs/latest/framework/infrastructure/event-bus/distributed/rebus) / [Azure](https://abp.io/docs/latest/framework/infrastructure/event-bus/distributed/azure)）· [Background Jobs](https://abp.io/docs/latest/framework/infrastructure/background-jobs)（+ [Quartz](https://abp.io/docs/latest/framework/infrastructure/background-jobs/quartz) / [Hangfire](https://abp.io/docs/latest/framework/infrastructure/background-jobs/hangfire) / [RabbitMQ](https://abp.io/docs/latest/framework/infrastructure/background-jobs/rabbitmq) / [TickerQ](https://abp.io/docs/latest/framework/infrastructure/background-jobs/tickerq)）· [Background Workers](https://abp.io/docs/latest/framework/infrastructure/background-workers)（+ [Quartz](https://abp.io/docs/latest/framework/infrastructure/background-workers/quartz) / [Hangfire](https://abp.io/docs/latest/framework/infrastructure/background-workers/hangfire)）· [Data Seeding](https://abp.io/docs/latest/framework/infrastructure/data-seeding) · [Data Filtering](https://abp.io/docs/latest/framework/infrastructure/data-filtering) · [Audit Logging](https://abp.io/docs/latest/framework/infrastructure/audit-logging) · [Settings](https://abp.io/docs/latest/framework/infrastructure/settings) · [Text Templating](https://abp.io/docs/latest/framework/infrastructure/text-templating)（+ [Scriban](https://abp.io/docs/latest/framework/infrastructure/text-templating/scriban) / [Razor](https://abp.io/docs/latest/framework/infrastructure/text-templating/razor)）· [Blob Storing](https://abp.io/docs/latest/framework/infrastructure/blob-storing)（+ [File System](https://abp.io/docs/latest/framework/infrastructure/blob-storing/file-system) / [Database](https://abp.io/docs/latest/framework/infrastructure/blob-storing/database) / [MinIO](https://abp.io/docs/latest/framework/infrastructure/blob-storing/minio) / [Custom](https://abp.io/docs/latest/framework/infrastructure/blob-storing/custom-provider) 等）· [GUID Generation](https://abp.io/docs/latest/framework/infrastructure/guid-generation) · [Concurrency Check](https://abp.io/docs/latest/framework/infrastructure/concurrency-check) · [Current User](https://abp.io/docs/latest/framework/infrastructure/current-user) · [Emailing](https://abp.io/docs/latest/framework/infrastructure/emailing) · [MailKit](https://abp.io/docs/latest/framework/infrastructure/mail-kit) · [SMS Sending](https://abp.io/docs/latest/framework/infrastructure/sms-sending) · [JSON](https://abp.io/docs/latest/framework/infrastructure/json) · [Object Mapping](https://abp.io/docs/latest/framework/infrastructure/object-to-object-mapping) · [Virtual File System](https://abp.io/docs/latest/framework/infrastructure/virtual-file-system) · [Distributed Locking](https://abp.io/docs/latest/framework/infrastructure/distributed-locking) · [Timing](https://abp.io/docs/latest/framework/infrastructure/timing) · [Correlation ID](https://abp.io/docs/latest/framework/infrastructure/correlation-id) · [Entity Cache](https://abp.io/docs/latest/framework/infrastructure/entity-cache) · [Interceptors](https://abp.io/docs/latest/framework/infrastructure/interceptors) · [Features](https://abp.io/docs/latest/framework/infrastructure/features) · [Global Features](https://abp.io/docs/latest/framework/infrastructure/global-features) · [Image Manipulation](https://abp.io/docs/latest/framework/infrastructure/image-manipulation) · [String Encryption](https://abp.io/docs/latest/framework/infrastructure/string-encryption) · [CSRF Anti-Forgery](https://abp.io/docs/latest/framework/infrastructure/csrf-anti-forgery) · [Cancellation Token Provider](https://abp.io/docs/latest/framework/infrastructure/cancellation-token-provider) · [App URLs](https://abp.io/docs/latest/framework/infrastructure/app-urls) · [Simple State Checker](https://abp.io/docs/latest/framework/infrastructure/simple-state-checker)

## Framework / Data

- [EF Core](https://abp.io/docs/latest/framework/data/entity-framework-core) 及子页：[Migrations](https://abp.io/docs/latest/framework/data/entity-framework-core/migrations) 、[MySQL](https://abp.io/docs/latest/framework/data/entity-framework-core/mysql) 、[PostgreSQL](https://abp.io/docs/latest/framework/data/entity-framework-core/postgresql) 、[SQLite](https://abp.io/docs/latest/framework/data/entity-framework-core/sqlite) 、[Oracle](https://abp.io/docs/latest/framework/data/entity-framework-core/oracle) 、[Other DBMS](https://abp.io/docs/latest/framework/data/entity-framework-core/other-dbms)
- [MongoDB](https://abp.io/docs/latest/framework/data/mongodb) 、[Dapper](https://abp.io/docs/latest/framework/data/dapper) 、[MemoryDB](https://abp.io/docs/latest/framework/data/memorydb)

## Framework / API Development

- [Auto Controllers](https://abp.io/docs/latest/framework/api-development/auto-controllers) 、[Swagger](https://abp.io/docs/latest/framework/api-development/swagger) 、[Versioning](https://abp.io/docs/latest/framework/api-development/versioning)
- [Standard APIs](https://abp.io/docs/latest/framework/api-development/standard-apis)（+ configuration / localization）
- [Static C# Clients](https://abp.io/docs/latest/framework/api-development/static-csharp-clients) 、[Dynamic C# Clients](https://abp.io/docs/latest/framework/api-development/dynamic-csharp-clients) 、[IdentityModel Clients](https://abp.io/docs/latest/framework/api-development/identitymodel-clients)
- [Integration Services](https://abp.io/docs/latest/framework/api-development/integration-services) — 跨模块集成服务

## 预构建模块（Modules）

文档覆盖：Account、Identity、IdentityServer/OpenIddict、PermissionManagement、SettingManagement、AuditLogging、TenantManagement、FeatureManagement、TextTemplateManagement、BlobStoring Database、BackgroundJobs、Chat、CMS Kit、FileManagement、Forms、Docs、Payment、Blog 等（基址 `https://abp.io/docs/latest/modules/<模块名>`）。用于"复用现成模块而不是重造"的判断与集成方式。

## 其他（按需）

- [Testing](https://abp.io/docs/latest/testing/overall) — ABP 测试基础设施（unit-tests / integration-tests / ui-tests）
- [CLI](https://abp.io/docs/latest/cli/index) — ABP CLI（`abp new`、`abp add-package`、`abp generate-proxy` 等）
- [Deployment](https://abp.io/docs/latest/deployment/configuring-production) 、[Solution Templates](https://abp.io/docs/latest/solution-templates/index)
- [UI](https://abp.io/docs/latest/framework/ui/index)（Angular/Blazor/MVC/React 等前端文档）
- [SignalR](https://abp.io/docs/latest/framework/real-time/signalr) 、[Dapr](https://abp.io/docs/latest/framework/dapr)

## 检索技巧

1. 官方文档 URL 与原文档目录结构一致：`https://abp.io/docs/latest/framework/<大类>/<小节>`，英文小写连字符命名。
2. 侧边栏面包屑可定位层级；best-practices 页开头会链接对应的 DDD 教程页（"Ensure you've read ... first"），先读教程再看最佳实践。
3. 需要精确到某个类/API 时，可在官方文档站右上角搜索。

注：本文档 URL 与文件名对照由原文档 frontmatter 的 `source` 字段提炼，与官方文档同步；如发现 404，按站内搜索找对应最新页面。
