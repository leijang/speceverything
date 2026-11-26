# ABP 官方最佳实践清单（Do / Don't）

> 官方文档：[Best Practices](https://abp.io/docs/latest/framework/architecture/best-practices)（entities / repositories / domain-services / application-services / data-transfer-objects / data-access-overview / module-architecture / entity-framework-core-integration）。按层组织，编写与评审时逐条核对。

## 实体（Entities）

- **DO** 在领域层定义实体，继承 `Entity<TKey>` / `AggregateRoot<TKey>` / 相应审计基类。
- **DO** 用构造函数保证创建时不变量成立；集合属性初始化为空集合。
- **DO** 用领域方法（如 `SetTitle`）变更状态，setter 收窄为 private/internal。
- **DO NOT** 让聚合根引用其他聚合根的实体导航（只存 Id）。
- **DO NOT** 在领域层以外定义实体。
- **DO** 常量类（`IssueConsts`）放 Domain.Shared。

## 领域服务（Domain Services）

- **DO** 用 `XxxManager`（继承 `DomainService`）承载跨实体/聚合业务规则。
- **DO** 业务异常用 `BusinessException` + 本地化错误码；参数校验用 `Check.NotNullOrWhiteSpace` 等。
- **DO** 跨聚合查询经由**仓储**，不要注入 DbContext。
- **DO NOT** 在领域服务里做 DTO、授权、UI 关注点。

## 仓储（Repositories）

- **DO** 接口在领域层、每个聚合根一个接口、实现按 Provider 分层。
- **DO NOT** 在应用/领域代码使用泛型 `IRepository<T,TKey>` 或 `IQueryable`。
- **DO** 方法全部 async + 可选 `CancellationToken`。
- **DO NOT** 为非聚合根实体定义仓储；非聚合根通过聚合根仓储处理。
- **DO** 需要复杂查询时在仓储中写返回 `IReadOnlyList` 的专用方法，并 `Include` 所需导航防 N+1。

## 应用服务（Application Services）

- **DO** 每个聚合根一个应用服务；接口定义在 Application.Contracts，实现继承 `ApplicationService`。
- **DO** DTO 进 DTO 出；输出尽量复用"基础 + 详细"两个 DTO。
- **DO** 命名 `XxxAppService : IXxxAppService`；接口实现 `IApplicationService`。
- **DO** 用 `ObjectMapper` 做映射，AutoMapper Profile 放在 Application 层。
- **DO NOT** 在应用服务里直接写业务规则（应调实体方法或领域服务）。
- **DO NOT** 返回实体或 `IQueryable`；不要手工校验 DTO（交给 ABP 验证管线）。
- **DO** 简单 CRUD 用 `CrudAppService` 复用，权限在构造函数挂接。
- **DO** 授权用 `PermissionDefinitionProvider` 定义的权限 + `[Authorize]`。

## DTO（Data Transfer Objects）

- **DO** DTO 在 Application.Contracts 定义；属性可空性与校验特性明确。
- **DO** 列表用 `PagedResultDto<T>` / `PagedAndSortedResultRequestDto`。
- **DO NOT** 在 DTO 之间大量复用导致字段冗余或泄漏敏感字段（密码等绝不进 DTO）。
- **DO** `IHasExtraProperties` 实体对应 DTO 继承 `Extensible*Dto`。

## 数据访问（Data Access / EF Core 集成）

- **DO** 一个模块一个 DbContext（或按聚合拆分并声明依赖）；继承 `AbpDbContext<TDbContext>`。
- **DO** 每个聚合根：`DbSet<T>` 属性 + `builder.Entity<T>(...)` 映射扩展（`public static IConfigurationBuilder ConfigureXxx(this ...)` 放在 EF Core 层）。
- **DO** 映射里配置字符串长度、索引、外键删除行为、值转换（枚举/Json）、owned 类型。
- **DO** 审计/租户/软删字段由 ABP 基类自动管理；上下文记得 `AddDefaultRepositories()`。
- **DO NOT** 在业务代码里手工写 `TenantId`、`IsDeleted` 过滤条件（由 `AbpDbContext` 全局过滤与 `ISoftDelete`/`IMultiTenant` 自动处理）。
- **DO** 并发用 `IsConcurrencyToken` / `IsRowVersion` 并在实体上实现 `IHasConcurrencyStamp`。

## 模块架构（Module Architecture）

- **DO** 按分层模板建 Package：Domain.Shared / Domain / Application.Contracts / Application / EntityFrameworkCore / HttpApi / (Web)。
- **DO** 模块类继承各层基类（`AbpModule` → `AbpDomainModule` …），`[DependsOn]` 声明依赖。
- **DO** 服务注册走约定（后缀）与 `ITransientDependency`/`ISingletonDependency`/`IScopedDependency`；模块 `ConfigureServices` 只做配置。
- **DO NOT** 模块间跨层引用：ModuleA.Application 不得依赖 ModuleB.Domain；跨模块调用走应用服务/集成服务与分布式事件。
- **DO NOT** 数据库层之间建立跨模块外键或 JOIN。
- **DO** 需要扩展预构建模块时用官方扩展机制（模块扩展实体、重写服务、替换 UI 组件），不要复制源码魔改。
