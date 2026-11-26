# 数据访问与 API 开发教程

> 官方文档：[Data](https://abp.io/docs/latest/framework/data/entity-framework-core) 、[API Development](https://abp.io/docs/latest/framework/api-development/auto-controllers) 、[EF Core Integration Best Practices](https://abp.io/docs/latest/framework/architecture/best-practices/entity-framework-core-integration)。

## EF Core 集成

### DbContext

```csharp
public class IssueDbContext : AbpDbContext<IssueDbContext>
{
    public DbSet<Issue> Issues { get; set; }

    public IssueDbContext(DbContextOptions<IssueDbContext> options) : base(options) { }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);   // 必须先调，加载 ABP/其他模块的实体扩展
        builder.ConfigureIssueTracker(); // 自己模块的映射扩展方法
        // 其他模块：builder.ConfigureIdentity(); 等
    }
}
```

### 映射扩展（放在 EF Core 层，静态方法）

```csharp
public static class IssueDbContextModelCreatingExtensions
{
    public static void ConfigureIssueTracker(this ModelBuilder builder)
    {
        builder.Entity<Issue>(b =>
        {
            b.ToTable(IssueTrackerConsts.DbTablePrefix + "Issues", IssueTrackerConsts.DbSchema);
            b.ConfigureByConvention();                 // 审计/租户/软删/扩展属性约定，必调
            b.Property(i => i.Title).IsRequired().HasMaxLength(IssueConsts.MaxTitleLength);
            b.HasMany(i => i.Labels).WithOne().HasForeignKey("IssueId").OnDelete(DeleteBehavior.Cascade);
            b.HasIndex(i => new { i.RepositoryId, i.Title });   // 性能红线：可查询字段必须配索引
            b.MapOwned<Address>();                     // 值对象
        });
    }
}
```

- `ConfigureByConvention()` 处理：审计字段、多租户、软删除、并发戳、扩展属性映射。
- 枚举存字符串用 `b.Property(x => x.Status).HasConversion<string>()`。

### 连接字符串与数据库（data/entity-framework-core/mysql.md 等）

- 连接串在 `appsettings.json` 的 `ConnectionStrings:Default`；`AbpDbConnectionOptions`（多数据库：`ConfigureDatabases`/`ReplaceDbContext`）。
- 各 DBMS 文档：`mysql.md`、`postgresql.md`、`sqlite.md`、`oracle*.md`、`other-dbms.md`；本项目 MySQL：Pomelo `MySql.EntityFrameworkCore`/`Pomelo` 集成按文档配置字符集/迁移。

### 迁移（data/entity-framework-core/migrations.md）

- 在 `EntityFrameworkCore` 包目录执行 `dotnet ef migrations add Xxx`（或模板内置的迁移控制台）；`DbMigrator` 项目负责初始化库 + 种子数据。
- 迁移产物必须随代码提交；不要手写 SQL 改表结构。

### 仓储实现注册

```csharp
context.Services.AddAbpDbContext<IssueDbContext>(options =>
{
    options.AddDefaultRepositories();
    options.AddRepository<Issue, EfCoreIssueRepository>();
});
```

## API 开发

### 自动控制器（auto-controllers.md）

- ABP 约定把实现 `IApplicationService`（或 `[RemoteService]`）的类暴露成 REST API：`/api/issue-tracker/issues`（按模块名 + 服务名去掉后缀）。
- 方法名约定：`GetAsync`→GET、`GetListAsync`→GET(带分页参数)、`CreateAsync`→POST、`UpdateAsync`→PUT、`DeleteAsync`→DELETE。
- `ConventionalControllerOptions` 可定制根路径、动词映射。
- DTO 特性：`[RemoteService(IsEnabled = false)]` 可禁用某服务自动暴露。

### DTO 路由与版本化（versioning.md）

- 标准 API 版本化集成 `Asp.Versioning`；`[ApiVersion("1.0")]`；URL/Header 查询策略均可配。

### Swagger（swagger.md）

- 模板默认集成 Swashbuckle；Host 项目 `Configure<AbpSwaggerGenOptions>` 定制文档/分组。

### 静/动态 C# 客户端（static-csharp-clients.md / dynamic-csharp-clients.md）

- 动态客户端：引用 Contracts，`AddHttpClientProxies(typeof(IssueTrackerApplicationContractsModule).Assembly, "IssueTracker")` 后直接注入接口调用，自动带上错误解析/授权头。
- 静态客户端：`abp generate-proxy -t csharp --url ...` 生成代理代码（离线可用）。

### 标准 API 响应（standard-apis/）

- 错误响应包装 `{ error: { code, message, details, data } }`；`GetList` 返回 `PagedResultDto<T>`（`totalCount` + `items`）。
- 本地化 API：`/api/abp/application-localization` 提供资源字典。

## 集成服务（integration-services.md）

- 跨模块调用推荐 **Integration Services**：定义 `IBookIntegrationService : IIntegrationService`（在 Contracts），实现类继承 `ApplicationService`；`IntegrationServiceOptions` 控制是否自动暴露为 HTTP API。
- 与分布式事件配合，实现模块间零耦合调用（不直接引用对方 Domain）。

## 简单一览：从聚合到 API 的完整文件清单

以 `Product` 聚合为例，新建功能需要产出：

1. `Domain.Shared`：`ProductConsts`（长度/表前缀常量）、枚举
2. `Domain`：`Product : FullAuditedAggregateRoot<Guid>`、`IProductRepository`、`ProductManager`
3. `Application.Contracts`：`IProductAppService`、`ProductDto/CreateUpdateProductDto`、`ProductPermissions` + `PermissionDefinitionProvider`、本地化 json
4. `Application`：`ProductAppService`、AutoMapper Profile
5. `EntityFrameworkCore`：`DbSet` + 映射扩展、`EfCoreProductRepository`、迁移
6. （可选）`HttpApi` 手工控制器；前端代理生成
