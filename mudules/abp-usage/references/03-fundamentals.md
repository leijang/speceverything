# 基础设施教程（Fundamentals）

> 官方文档：[Fundamentals](https://abp.io/docs/latest/framework/fundamentals)（各页链接见 `06-doc-index.md`）。按主题给出最常用的使用模式。

## 依赖注入（dependency-injection.md）

- 约定注册：按命名后缀自动注册 `AppService`、`Controller`、`Repository`、`Service`、`Manager`、`Provider`、`Handler` 等，默认生命周期瞬态（实现 `ITransientDependency`）。
- 显式生命周期：类实现 `ITransientDependency` / `IScopedDependency` / `ISingletonDependency`。
- 直接暴露到 DI 容器：`[ExposeServices(typeof(IXxx))]`；替换服务：`[ReplaceServices]` + `context.Services.Replace(...)`;
- 拦截器/切面：方法挂 `[UnitOfWork]`、`[Authorize]` 等 ABP 拦截器特性即可生效（Autofac 集成默认启用）。

## Options 系统（options.md）

- 用 `IOptions<TOptions>` / ABP 简化接口（如 `IAbpLazyServiceProvider`…）；标准方式：

```csharp
public class MyService
{
    private readonly MyOptions _options;
    public MyService(IOptions<MyOptions> options) => _options = options.Value;
}
```

- 模块中配置：`context.Services.Configure<MyOptions>(o => o.X = ...)`；可加 `[DependsOn]` 的模块上配置。
- ABP 有大量预置 Options 类（`AbpAutoMapperOptions`、`AbpBackgroundJobOptions`…），配置入口都在模块类的 `ConfigureServices`。

## 配置（configuration.md / appsettings）

- `IConfiguration` 直接可用；ABP 补充 `IConfigurationAccessor`。环境配置沿用 ASP.NET Core（appsettings.json + appsettings.{env}.json）。
- 模块里读取：`context.Services.ExecutePreConfiguredActions<...>()` 等高级用法先查文档再写。

## 认证与授权（authorization.md / authorization/resource-based-authorization.md）

- 权限定义：

```csharp
public class IssueTrackerPermissions
{
    public const string GroupName = "IssueTracker";
    public static class Issues
    {
        public const string Default = GroupName + ".Issues";
        public const string Create = Default + ".Create";
        public const string Edit = Default + ".Edit";
        public const string Delete = Default + ".Delete";
    }
}

public class IssueTrackerPermissionDefinitionProvider : PermissionDefinitionProvider
{
    public override void Define(IPermissionDefinitionContext context)
    {
        var group = context.AddGroup(IssueTrackerPermissions.GroupName, L("Permission:IssueTracker"));
        var issue = group.AddPermission(IssueTrackerPermissions.Issues.Default, L("Permission:Issues"));
        issue.AddChild(IssueTrackerPermissions.Issues.Create, L("Permission:Issues.Create"));
    }
    private static LocalizableString L(string name) => LocalizableString.Create<IssueTrackerResource>(name);
}
```

- 应用服务/方法：`[Authorize(IssueTrackerPermissions.Issues.Default)]`；代码内判断：`_authorizationService.IsGrantedAsync(...)` 或注入 `ICurrentUser`/`ICurrentTenant`。
- 资源级授权：`IAuthorizationService.AuthorizeAsync(user, resource, policy)` 或继承 `AuthorizationProvider` 写自定义策略。

## 输入校验（validation.md / fluent-validation.md）

- DataAnnotations 特性自动生效；FluentValidation 集成：定义 `AbstractValidator<CreateIssueDto>` 自动执行（包 `Volo.Abp.FluentValidation`）。
- 自定义校验逻辑也可在 DTO 实现 `IValidatableObject`。

## 异常处理（exception-handling.md）

- `BusinessException(code, ...)`：默认返回 403 业务错误码（HTTP 由错误码→映射决定），错误码本地化在 `AbpValidationResource`/自定义资源。
- `UserFriendlyException`：直接把消息展示给用户（常用但注意别绕过本地化）。
- 错误码→HTTP 映射：`AbpExceptionHttpStatusCodeOptions`；错误消息本地化：错误码作为本地化 key。
- 响应包装：`AbpShouldWrapExceptionResponseOptions`（默认包装为 `{ code, message, details, ... }`）。

## 本地化（localization.md / url-based-localization.md）

- 资源 JSON 文件（如 `en.json`、`zh-Hans.json`）放 Domain.Shared，虚拟文件系统嵌入：

```csharp
Configure<AbpVirtualFileSystemOptions>(options =>
{
    options.FileSets.AddEmbedded<MyModule>("MyModule");   // 本地化 json 随嵌入资源可用
});
Configure<AbpLocalizationOptions>(options =>
{
    options.Resources.Add<MyResource>("en").AddBaseTypes(...).AddVirtualJson("/Locales/MyModule");
});
```

- 使用：注入 `IStringLocalizer<MyResource>`，或应用服务/控制器基类的 `L` 属性。

## 缓存（caching.md / redis-cache.md）

- `IDistributedCache<TCacheItem, TCacheKey>`：强类型缓存，支持绝对/滑动过期、区域。

```csharp
var value = await _cache.GetAsync(key);
if (value == null) { value = await ComputeAsync(); await _cache.SetAsync(key, value, new DistributedCacheEntryOptions { AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10) }); }
```

- Redis 集成包 `Volo.Abp.Caching.StackExchangeRedis`；默认序列化 JSON（`AbpDistributedCacheOptions.SerializerName`）。

## 日志（logging.md）

- 基类自带 `ILoggerFactory`（`Logger` 属性）；标准 `ILogger<T>` 注入亦可。
- ABP 用 Serilog 在模板中预配置；审计日志见 infrastructure。

## 当前用户（current-user.md）

- `ICurrentUser`：`Id`、`UserName`、`TenantId`、`IsAuthenticated`、`FindClaim`；`ICurrentTenant` 切换租户（配合 UoW）。

## 对象映射（object-to-object-mapping.md）

- AutoMapper 集成：Profile 继承 `Profile`，模块里：

```csharp
Configure<AbpAutoMapperOptions>(options => options.AddMaps<MyApplicationModule>());
```

- `ObjectMapper.Map<TSource,TDestination>(src)`；未显式映射的属性按 AutoMapper 约定。

## 对象扩展（object-extensions.md）

- `IHasExtraProperties` 实体 + `ObjectExtensionManager` 定义扩展属性，配合模块扩展机制给预构建模块实体加字段（推荐给 Identity/Order 等内置实体扩字段时使用）。
