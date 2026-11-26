# 框架基础设施教程（Infrastructure）

> 官方文档：[Infrastructure](https://abp.io/docs/latest/framework/infrastructure)（各页链接见 `06-doc-index.md`）。项目最常用主题先行。

## 事件总线（event-bus/local.md、event-bus/distributed/index.md）

- 本地事件：

```csharp
// 发布（实体基类/领域服务内）
LocalEventBus.PublishAsync(new StockChangedEvent(product.Id, delta));

// 处理器
public class StockChangedHandler : ILocalEventHandler<StockChangedEvent>, ITransientDependency
{
    public async Task HandleEventAsync(StockChangedEvent eventData) { ... }
}
```

- 分布式事件：`IDistributedEventBus.PublishAsync(evt)`；事件类实现 `IEventBusEvent`…（实际为普通 POCO，建议实现 `Eto` 或自定义类）；处理器 `IDistributedEventHandler<T>`；生产端需配 Outbox（`AbpDistributedEventBusOptions` + `AddDistributedEventBus`），消费端 Inbox。
- RabbitMQ 集成：`Volo.Abp.EventBus.RabbitMQ`；另支持 Kafka / Rebus / Azure。
- 实体内直接 `AddLocalEvent / AddDistributedEvent`（聚合根事件集合），UoW 提交后自动发布。

## 后台任务（background-jobs/index.md 与 quartz/hangfire/rabbitmq/tickerq.md）

- 内置（默认 Hangfire 可换）：`IBackgroundJobManager.EnqueueAsync(args)`；参数类可序列化；Job 类实现 `AsyncBackgroundJobAsync<Args>`。

```csharp
public class EmailSendingJob : AsyncBackgroundJob<EmailSendingArgs>, ITransientDependency
{
    public override async Task ExecuteAsync(EmailSendingArgs args) { ... }
}
await _backgroundJobManager.EnqueueAsync(new EmailSendingArgs { ... });
```

- Quartz 集成：`Volo.Abp.BackgroundJobs.Quartz`；作业类继承 `QuartzJobBase`/`AsyncQuartzJobBase`。

## 后台 Worker（background-workers/index.md）

```csharp
public class MyWorker : AsyncPeriodicBackgroundWorkerBase, ISingletonDependency
{
    public MyWorker(AbpAsyncTimer timer, IServiceScopeFactory scopeFactory) : base(timer, scopeFactory) { }
    protected override async Task DoWorkAsync(PeriodicBackgroundWorkerContext ctx) { ... }
}
// 模块里注册：context.Services.AddHostedService<MyWorker>();
```

## 数据播种（data-seeding.md）

```csharp
public class MyDataSeedContributor : IDataSeedContributor, ITransientDependency
{
    private readonly IRepository<Product, Guid> _repository;
    public MyDataSeedContributor(IRepository<Product, Guid> repository) => _repository = repository;

    public async Task SeedAsync(DataSeedContext context)
    {
        if (await _repository.GetCountAsync() > 0) return;
        await _repository.InsertAsync(new Product(...), autoSave: true);
    }
}
```

- 贡献者自动发现并按顺序执行；`DataSeedContext` 带 TenantId（多租户种子）。**这是种子数据的唯一官方方式**，禁止手工 SQL 插数据。

## 数据过滤（data-filtering.md）

- 内置过滤：`ISoftDelete`（IsDeleted）、`IMultiTenant`（TenantId）自动过滤。
- 自定义过滤：实体实现接口（如 `IActive`），`AbpDbContext` 里重写 `ShouldFilterEntity` / `CreateFilterExpression`。
- 临时关闭过滤：`_unitOfWork.DisableFilter(AbpDataFilters.SoftDelete)`（`IUnitOfWork.DisableFilter`，作用范围 UoW 内）。

## 审计日志（audit-logging.md）

- 自动记录：实体变更（创建/更新/删除）、应用服务调用、登录等；`IAuditingStore` 可替换存储。
- 配置：`AbpAuditingOptions`（Enabled、Contributors、忽略成员等）。预构建 AuditLogging 模块提供查询 UI/API。

## 设置（settings.md）

- 定义 `SettingDefinitionProvider`（名称、默认值、可见性/提供者），读写用 `ISettingProvider.GetAsync` / `ISettingManager.SetAsync`（按 Tenant/User 等作用域）。SettingManagement 模块提供管理端。

## 文本模板（text-templating/index.md、scriban.md、razor.md）

```csharp
context.Services.Configure<AbpTextTemplatingOptions>(options =>
{
    options.Templates.Add(new TemplateDefinition(MyTemplates.Welcome).WithLocalizedDisplayName(...));
});
// 渲染
var html = await _templateRenderer.RenderAsync(MyTemplates.Welcome, new { Name = "x" });
```

- 默认 Scriban 引擎；Razor 引擎可替换；常用于邮件模板（配合 Emailing/MailKit）。

## Blob 存储全局/多租户（blob-storing/index.md）

- `IBlobContainer<TContainer>` / `IBlobContainer`：`SaveAsync/GetAsync/DeleteAsync`；提供 File-System / Database / MinIO / Azure / AWS / Aliyun 等提供者，切换不改业务代码。

## GUID 生成（guid-generation.md）

- 基类 `GuidGenerator`（Sequential GUID，DB 索引友好）；实体/领域服务基类里直接用；非基类场景注入 `IGuidGenerator`。**不要 `Guid.NewGuid()` 当主键。**

## 多租户（architecture/multi-tenancy/index.md）

- 数据隔离三种方式（租户级 partition/按库/按 schema），默认单库 + `TenantId` 过滤。
- 实体实现 `IMultiTenant`；切换：`ICurrentTenant.Change(tenantId)`（需在 UoW/作用域内）。
- 租户解析：`AbpMultiTenancyOptions`；当前租户来自 CurrentUser 或 Url/Header/Cookie（`TenantResolveContributors` 可扩展）。
- 主机数据（无 TenantId）与租户数据共存；`DisableFilter` 临时跨租户查询。

## 其他常用

- **审计 ID/关联**：`CorrelationId`（correlation-id.md）。
- **时钟**：`IClock`（`Now`），配合 `AbpClockOptions` 统一时区（timing.md）。
- **JSON**：`Abp.Json`（System.Text.Json 默认，`AbpJsonOptions` 定制）。
- **虚拟文件系统**：`AbpVirtualFileSystemOptions`（嵌入资源、替换文件）。
- **分布式锁**：`IAbpDistributedLock`（`AbpDistributedLockOptions`，Provider：Redis 等）。
- **邮件/短信**：`IEmailSender`（MailKit 集成）、`ISmsSender`。
- **实体缓存**：`IEntityCache<TEntity, TKey>`（entity-cache.md，按 Id 缓存实体）。
- **并发检查**：`IHasConcurrencyStamp` + EF `IsConcurrencyToken`；`AbpConcurrencyStampOptions`。
