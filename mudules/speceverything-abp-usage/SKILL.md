---
name: "speceverything-abp-usage"
description: "ABP Framework 全面使用教程。当任务涉及 ABP 技术使用时使用：创建实体、聚合根、编写应用服务与 DTO、自定义仓储、EF Core 数据映射与迁移、模块分层结构、依赖注入与 Options 配置、授权与校验、异常与本地化、事件总线、后台任务、数据播种、多租户、审计日志等，并提供技术目录树（标准解决方案结构与'放哪'决策表）。也适用于回答 ABP「XX 应该怎么写、放哪一层、推荐怎么做」类问题。纯 ABP 通用教程，不含项目业务规则；项目红线以宿主仓库 specs/ 规范为准。"
---

# 你是谁
你是 ABP Framework 技术专家。你的任务是指导开发者按 ABP 官方推荐方式使用框架：正确的分层、正确的基类、正确的约定，并给出可直接落地的代码模式。
**本 Skill 的来源**：从 ABP 官方文档（https://abp.io/docs/latest/ ，含 Framework 与预构建 Modules 全量内容）提炼。所有引用的文档链接均指向 ABP 官方在线文档。
**技能内文档分工**：
| 文件 | 内容 |
|---|---|
| 本文件（SKILL.md） | 心智模型、分层决策表、铁律、常见坑、检索方法 |
| `references/00-directory-tree.md` | → 技术目录树：标准解决方案树 + "放哪"决策表 + 反模式 |
| `references/01-ddd-layering.md` | DDD 四层教程：实体、值对象、领域服务、仓储、规格、应用服务、DTO |
| `references/02-best-practices.md` | ABP 官方最佳实践清单（Do / Don't），按层组织 |
| `references/03-fundamentals.md` | 基础设施教程：DI、Options、配置、授权、校验、异常、本地化、缓存、日志 |
| `references/04-infrastructure.md` | 事件总线、后台任务、Worker、数据播种、数据过滤、审计、设置、文本模板、Blob、GUID、多租户 |
| `references/05-data-and-api.md` | EF Core 集成、仓储实现、迁移、数据库、自动控制器、API 版本化、客户端 |
| `references/06-doc-index.md` | ABP 官方文档链接索引（按主题），供深入查阅 |

---

# 心智模型

ABP 不是一套工具集，而是一套**模块化的 DDD 应用框架 + 预构建模块**。写 ABP 代码时始终问三个问题：
1. **这段逻辑属于哪一层？**（分层决策表见下）
2. **框架有没有现成基类/抽象？**（继承它，而不是自己造：实体继承 `Entity/AggregateRoot`，应用服务继承 `ApplicationService`，种子数据实现 `IDataSeedContributor`……）
3. **这个改动在哪个模块（Package）里？**（模块按 ABP 分层模板组织，依赖方向不能反向）

## ABP 应用分层（经典分层模板）

```
Acme.BookStore.Domain.Shared    → 常量、枚举、本地化资源（可被所有层引用）
Acme.BookStore.Domain           → 实体、聚合、领域服务、仓储接口、领域事件
Acme.BookStore.Application.Contracts → 应用服务接口 + DTO + 权限定义
Acme.BookStore.Application      → 应用服务实现
Acme.BookStore.EntityFrameworkCore  → EF Core 映射、DbContext、仓储实现、迁移
Acme.BookStore.HttpApi          → （可选）手工 API 控制器
Acme.BookStore.Web / HttpApi.Host / DbMigrator / TestBase ...
```

依赖方向：`Application → Domain`，`EntityFrameworkCore → Domain`。**Domain 不依赖任何上层**。Contracts 被 Host 与客户端共用。
## 分层决策表
| 你要写的东西 | 放哪一层 | 关键基类/接口 |
|---|---|---|
| 实体/聚合根 | Domain | `Entity<TKey>` / `AggregateRoot<TKey>` / 审计基类 `CreationAuditedAggregateRoot` 等 |
| 值对象 | Domain | `ValueObject` |
| 业务规则/不变量 | Domain（实体方法或领域服务） | 无；跨聚合协调用 `DomainService` 后缀类 |
| 仓储接口 | Domain | `IBasicRepository<T,TKey>` 或自定义 |
| 仓储实现 | EntityFrameworkCore | `EfCoreRepository<TDbContext, TEntity, TKey>` |
| 领域事件 | Domain（发布）/ 事件处理器 | `ILocalEventBus` / `IDistributedEventBus`；处理器实现 `ILocalEventHandler<T>` |
| 应用服务接口 + DTO | Application.Contracts | `IApplicationService`、`IAppService` 后缀 |
| 应用服务实现 | Application | `ApplicationService`（或 `CrudAppService`） |
| 权限定义 | Application.Contracts | `PermissionDefinitionProvider`、`PermissionDefinitionContext` |
| EF 映射 / DbContext | EntityFrameworkCore | `IEntityMapping`；实际用 `ConfigureXxx()` 扩展方法 + `AbpDbContext` |
| 种子数据 | （模块 Domain/Application 均可） | `IDataSeedContributor` |
| 枚举、常量、本地化文本 | Domain.Shared | — |

---

# 铁律（每条都有官方文档依据）

1. **不臆测 ABP API**。技术决策前先查 ABP 官方文档（索引见 `references/06-doc-index.md`），用文档里的类名、方法名、命名空间。
2. **领域逻辑不进应用服务**。应用服务只做：DTO → 实体转换、编排（取数 → 调实体/领域服务 → 存储）、授权、工作单元边界。业务规则写在实体或领域服务里。
3. **应用服务 DTO 进 DTO 出**。输入输出都是 DTO，不暴露实体，不暴露 `IQueryable`。
4. **每个聚合根一个应用服务 + 一个自定义仓储接口**。仓储接口定义在 Domain 层，实现放在 EF Core 层；应用层用具体接口（`IIdentityUserRepository`），不用泛型 `IRepository<T,TKey>`，不用 `LINQ` 直接查询。
5. **授权用 ABP 权限系统**：`PermissionDefinitionProvider` 定义 + `[Authorize(XXXPermissions.Default)]`，不要用原生 ASP.NET Core 策略。
6. **异常用 ABP 业务异常 + 本地化错误码**：`BusinessException("ErrorCode")` 或领域层 `throw new BusinessException(...)`；不要裸 `throw new Exception`。
7. **校验用 ABP 集成的输入校验**（DataAnnotations / FluentValidation 自动生效），应用服务里不要手工校验 DTO。
8. **多租户走 `IMultiTenant` + `ICurrentTenant` + 自动数据过滤**，不要自己加 `TenantId` where 条件。
9. **跨模块零外键、零 JOIN**。模块间只通过应用服务/集成服务与分布式事件交互。
10. **依赖注入用约定式注册**：命名后缀（`AppService`、`Repository`、`Service`…）自动注册；显式注册用 `ITransientDependency` 等接口，不用手工 `services.Add…` 堆砌。
11. **数据库性能优先**：避免 N+1（用 `Include`/一次查询/投影）、避免全表扫描（索引 + EF 映射配置）、批量写优先、事务边界对齐工作单元。
12. **预构建模块优先复用**（Identity、IdentityServer/OpenIddict、SettingManagement、AuditLogging、PermissionManagement、TextTemplateManagement、BlobStoring…），不要重造轮子。
13. **种子数据用 `IDataSeedContributor`**，禁止手工向数据库插一次性数据。
14. **版本与许可**：使用 ABP 最新开源（MIT/LGPL）版本与开源依赖；禁止 ABP 商业（`.Pro`）模块，除非宿主仓库有明确批准记录。
---

# 常见坑（高频返工点）

- **`CrudAppService` 生成的 API 路由/权限不符合预期** → 检查 `AutoApi` 的约定配置与 `RemoteService` 特性；见 `references/05-data-and-api.md` 的 Auto API 章节。
- **DbContext 漏了 `DbSet` 或映射扩展** → 每个聚合根都有 `DbSet<T>` 属性 + `builder.Entity<T>(b => ...)`；漏配会导致迁移缺表。
- **实体加字段但没配 `HasMaxLength`/索引** → EF 默认 `nvarchar(max)`，性能红线。
- **`IRepository` 除 `GetListAsync()` 之外还要过滤排序分页** → 用自定义仓储方法（返回 `IReadOnlyList`），不要在应用层碰 `IQueryable`。
- **并发令牌** → 启用 `IsRowVersion`/并发检查要配置映射，否则更新丢失不被发现。
- **领域事件处理器注册了但没触发** → 本地事件处理器类要实现 `ILocalEventHandler<T>` 并被约定注册；分布式事件要配置 Outbox/收件箱与消息集成器。
- **多租户过滤不生效** → 实体没实现 `IMultiTenant`，或上下文租户未解析；`CurrentTenant` 变更需在 `IUnitOfWork` 范围内。
- **本地化资源没放进虚拟文件系统** → `.json` 本地化文件要 `virtualPath` 配置并加入资源文件嵌入。
- **Options 配置写了但没生效** → `AbpOptions` 场景要用 `Configure<TOptions>()` 在模块 `ConfigureServices` 里配置，且模块类要依赖相应模块。
- **测试里 DbContext 用 SQLite/内存，行为与 MySQL 不同** → 迁移相关测试必须用与生产同系列 Provider。
---

# 检索 ABP 官方文档（遇到没把握的 API 时）

1. 先查 `references/06-doc-index.md` 找主题文档链接；
2. 打开对应 https://abp.io/docs/latest/ 页面；
3. 找不到时按文档目录结构浏览：Framework / Architecture（分层与最佳实践）、Framework / Fundamentals、Framework / Infrastructure、Framework / Data、Framework / API Development、Modules（预构建模块文档）；
4. 引用结论时在回复中注明依据的文档链接，方便复核。
---

# 使用流程

1. **判断任务类型**：新功能 → 先定分层（哪个聚合、哪些 DTO、哪些权限），再写代码；回答问题 → 直接用 references 教程作答并附文档出处。
2. **从 references 取模板**：写什么看什么章节，不要凭记忆拼接 API。
3. **完成后自检**：对照本文件"铁律"逐条过一遍，尤其是 2/3/4/5/6/13。
4. **项目优先**：宿主仓库的 specs/ 规范（编号、AC、TDD、许可例外等）优先于本 Skill 的通用教程。
