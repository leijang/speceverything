# DDD 四层教程（ABP 实现）

> 官方文档：[Domain-Driven Design](https://abp.io/docs/latest/framework/architecture/domain-driven-design)（entities / value-objects / domain-services / repositories / specifications / unit-of-work / application-services / data-transfer-objects）与 [Best Practices](https://abp.io/docs/latest/framework/architecture/best-practices)。

## 1. 实体与聚合根

- 实体基类链：`Entity<TKey>` → `AggregateRoot<TKey>`（聚合根额外承担领域事件与并发令牌）。
- 审计基类按需继承（都在 `Volo.Abp.Domain.Entities.Auditing`）：
  - `CreationAuditedEntity<T>` / `CreationAuditedAggregateRoot<T>`：CreationTime + CreatorId
  - `AuditedEntity<T>` / `AuditedAggregateRoot<T>`：+ Modification
  - `FullAuditedEntity<T>` / `FullAuditedAggregateRoot<T>`：+ 软删除（IsDeleted），配合 `ISoftDelete` 自动过滤
- 可选接口：`IMultiTenant`（租户隔离 + 自动过滤）、`IHasConcurrencyStamp`、`IHasExtraProperties`（扩展属性字典）、`IActiveInactive` 风格的自定义状态。
- 示例：

```csharp
public class Issue : FullAuditedAggregateRoot<Guid>
{
    public Guid RepositoryId { get; private set; }   // 聚合外键只存 Id，不引用其他聚合的实体
    public string Title { get; private set; } = null!;
    public string? Text { get; set; }
    public Guid? AssignedUserId { get; private set; }
    public bool IsClosed { get; private set; }
    public IssueLabelsCollection Labels { get; private set; }   // 集合导航

    private Issue() { /* EF Core */ }

    internal Issue(Guid id, Guid repositoryId, string title, string? text = null)
        : base(id)
    {
        RepositoryId = repositoryId;
        SetTitle(title);
        Text = text;
        Labels = new IssueLabelsCollection(this);   // 集合构造进聚合内部
    }

    public void SetTitle(string title)
    {
        Title = Check.NotNullOrWhiteSpace(title, nameof(title), IssueConsts.MaxTitleLength);
        // 领域校验用 Check.*，不抛裸异常
    }
}
```

要点：
- **构造函数做初始化**，保证创建即有效（不变量在构造时建立）。
- **属性 setter 设为 private/internal**，通过方法改状态。
- **聚合内部实体**（如 `IssueLabel : Entity<Guid>`）持有对聚合根的导航引用 `Issue Issue { get; private set; }`。
- 常量（`IssueConsts.MaxTitleLength`）放 Domain.Shared。
- 聚合外的实体只保存 `Guid` 外键，不跨聚合导航。

## 2. 值对象

```csharp
public class Address : ValueObject
{
    public string City { get; private set; }
    public string Street { get; private set; }
    // ... 构造函数校验
    protected override IEnumerable<object> GetAtomicValues()
    {
        yield return City;
        yield return Street;
    }
}
```

- EF Core 里值对象用 **owned entity** 映射；没有 Id，随聚合根存储。
- 判断标准：无标识、不可变、整体替换而不是修改。

## 3. 领域服务

- 用于**跨聚合/跨实体的业务逻辑**，不适合放在单个实体上的规则。
- 命名：`XxxManager`（或 `XxxService`），基类 `DomainService`（可获得 `ILoggerFactory`、`IClock`、`ICurrentUser` 等注入）。
- 方法默认 `virtual`，返回值抛 `BusinessException` 错误码。

```csharp
public class IssueManager : DomainService
{
    private readonly IIssueRepository _issueRepository;

    public IssueManager(IIssueRepository issueRepository) => _issueRepository = issueRepository;

    public async Task<Issue> CreateAsync(Guid repositoryId, string title, string? text = null)
    {
        if (await _issueRepository.ExistsWithTitleAsync(repositoryId, title))
        {
            throw new BusinessException("IssueTracker:DuplicateIssueTitle");  // 本地化错误码
        }
        return new Issue(GuidGenerator.Create(), repositoryId, title, text);
    }
}
```

- `GuidGenerator.Create()`（来自 `DomainService`/`Entity` 基类）生成 GUID，不要 `Guid.NewGuid()`。

## 4. 仓储

### 接口（Domain 层）

```csharp
public interface IIssueRepository : IBasicRepository<Issue, Guid>
{
    Task<Issue?> FindByTitleAsync(string title, CancellationToken cancellationToken = default);
    Task<List<Issue>> GetOpenIssuesAsync(Guid repositoryId, CancellationToken cancellationToken = default);
}
```

- 继承 `IBasicRepository<T, TKey>`（含基础 CRUD），不要继承 `IRepository<T, TKey>`（暴露 IQueryable）。
- 一个聚合根一个接口；方法全部 async，带 `CancellationToken cancellationToken = default`。

### 实现（EF Core 层）

```csharp
public class EfCoreIssueRepository : EfCoreRepository<IssueDbContext, Issue, Guid>, IIssueRepository
{
    public EfCoreIssueRepository(IDbContextProvider<IssueDbContext> dbContextProvider)
        : base(dbContextProvider) { }

    public async Task<List<Issue>> GetOpenIssuesAsync(Guid repositoryId, CancellationToken ct = default)
    {
        var dbSet = await GetDbSetAsync();
        return await dbSet
            .Where(i => i.RepositoryId == repositoryId && !i.IsClosed)
            .Include(i => i.Labels)                 // 避免 N+1
            .OrderBy(i => i.CreationTime)
            .ToListAsync(GetCancellationToken(ct));
    }
}
```

- `GetDbSetAsync()` 拿 DbSet、`GetDbContextAsync()` 拿上下文（用于 `ExecuteUpdateAsync` 等批量操作）。
- 聚合根默认仓储已由 ABP 注册；自定义接口要在模块 `ConfigureServices` 里加：

```csharp
context.Services.AddAbpDbContext<IssueDbContext>(options =>
{
    options.AddDefaultRepositories();               // 或 AddDefaultRepositories(includeAllEntities: true)
    options.AddRepository<Issue, EfCoreIssueRepository>();
});
```

## 5. 规格（Specification）

```csharp
public class OpenIssuesSpecification : Specification<Issue>
{
    public override Expression<Func<Issue, bool>> ToExpression()
        => i => !i.IsClosed;
}

// 使用：组合与持久化
var open = OpenIssuesSpecification.And(new ImportantIssuesSpecification());
var list = await _issueRepository.GetListAsync(open);
```

- 规格 = 可复用的查询/业务规则表达式；支持 `And/Or/Not` 组合，也可用于内存校验（`IsSatisfiedBy`）。

## 6. 工作单元（UoW）

- ABP 自动为应用服务方法、控制器 Action 开启 UoW，提交时保存所有变更（无需手工 `SaveChanges`）。
- 关闭/自定义：`[UnitOfWork(isTransactional: false)]`；只读方法可考虑关事务。
- `IUnitOfWork` 可显式保存：`await _unitOfWork.SaveChangesAsync()`。
- 多租户切换等环境变更必须在 UoW 范围内进行。

## 7. 应用服务

```csharp
public class IssueAppService : ApplicationService, IIssueAppService
{
    private readonly IIssueRepository _issueRepository;
    private readonly IssueManager _issueManager;

    public IssueAppService(IIssueRepository issueRepository, IssueManager issueManager)
    {
        _issueRepository = issueRepository;
        _issueManager = issueManager;
    }

    [Authorize(IssueTrackerPermissions.Issues.Default)]
    public async Task<IssueDto> GetAsync(Guid id)
    {
        var issue = await _issueRepository.GetAsync(id);
        return ObjectMapper.Map<Issue, IssueDto>(issue);
    }

    public async Task<IssueDto> CreateAsync(CreateIssueDto input)
    {
        var issue = await _issueManager.CreateAsync(input.RepositoryId, input.Title, input.Text);
        await _issueRepository.InsertAsync(issue);
        return ObjectMapper.Map<Issue, IssueDto>(issue);
    }
}
```

- 应用服务的职责只有四件事：授权、输入校验（自动）、调用领域对象完成用例、DTO 映射与返回。
- 简单 CRUD 直接继承：

```csharp
public class IssueAppService
    : CrudAppService<Issue, IssueDto, Guid, PagedAndSortedResultRequestDto, CreateIssueDto, UpdateIssueDto>,
      IIssueAppService
{
    // 自动获得 Get/GetList/Create/Update/Delete，权限可在构造时用 GetPolicyAsync + L 挂上
}
```

- `ObjectMapper` 用 AutoMapper Profile（继承 `Profile`，在模块类里注册 `AbpAutoMapperOptions`）。

## 8. DTO（Application.Contracts）

- 基础 DTO：`ExtensibleEntityDto<TKey>` 系列（`EntityDto` / `AuditedEntityDto` / `FullAuditedEntityDto`）；输入 DTO 常继承 `EntityDto<Guid>` + 校验特性。
- 列表输入：`PagedAndSortedResultRequestDto`；输出：`PagedResultDto<T>`。
- 每个聚合根一个"基础 DTO"（全部原始属性）+ 一个"详细 DTO"（含关联聚合的引用信息），避免 DTO 爆炸。
- DTO 标注数据校验特性（`[Required]`、`[StringLength]` 等），校验自动生效。
