# ABP 技术目录树

> 来源：ABP 官方启动模板（https://abp.io/docs/latest/solution-templates ，Layered/Single-Layer 模板）。本文件是"技术方案 → 目录落地"的依据，与宿主项目 `specs/项目目录结构.md` 冲突时以项目定制为准。

## 1. 标准分层解决方案树（Layered 模板）

```text
MyProject/
├── src/
│   ├── MyProject.Domain.Shared/        # ① 共享层：常量、枚举、本地化资源、共享错误码
│   │   ├── Localization/
│   │   └── …
│   ├── MyProject.Domain/               # ② 领域层：业务核心，不依赖任何其他层
│   │   ├── <聚合>/<AggregateRoot>.cs   #   聚合根、实体、值对象
│   │   ├── <聚合>/I<Xxx>Repository.cs  #   仓储接口（实现放 EF 层）
│   │   ├── <领域服务>.cs               #   领域服务（跨聚合业务规则）
│   │   ├── Specifications/             #   规格模式（ISpecification）
│   │   ├── Settings/                   #   设置定义
│   │   └── Data/                       #   数据播种贡献者（IDataSeedContributor）
│   ├── MyProject.Application.Contracts/# ③ 契约层：DTO、应用服务接口、权限定义
│   │   ├── <功能>/Dtos/
│   │   ├── <功能>/I<Xxx>AppService.cs
│   │   └── Permissions/                #   权限定义与 Provider
│   ├── MyProject.Application/          # ④ 应用层：应用服务实现、AutoMapper Profile
│   │   ├── <功能>/<Xxx>AppService.cs
│   │   └── <Xxx>ApplicationAutoMapperProfile.cs
│   ├── MyProject.EntityFrameworkCore/  # ⑤ EF Core 层：DbContext、实体映射、仓储实现、迁移
│   │   ├── <Xxx>DbContext.cs
│   │   ├── <Xxx>DbContextModelCreatingExtensions.cs  # 实体映射（OnModelCreating）
│   │   └── Repositories/               # 自定义仓储实现（EFCoreRepository）
│   ├── MyProject.HttpApi/              # ⑥ API 层：控制器（多数为 AutoApi 生成，少量自定义）
│   ├── MyProject.HttpApi.Client/       # 客户端代理（C# 客户端调用）
│   ├── MyProject.DbMigrator/           # 迁移执行控制台（生产环境迁移入口）
│   └── MyProject.Web/                  # ⑦ 表现层：UI（Razor Pages/MVC/Blazor）
│       ├── Pages/
│       ├── wwwroot/
│       └── …
├── test/
│   ├── MyProject.TestBase/             # 测试基础设施（共享 Fixture）
│   ├── MyProject.Domain.Tests/         # 领域层测试（TDD 主战场）
│   ├── MyProject.EntityFrameworkCore.Tests/  # 仓储/映射测试
│   ├── MyProject.Application.Tests/    # 应用服务测试
│   └── MyProject.Web.Tests/            # UI/集成测试
└── MyProject.sln
```

## 2. "放哪里"决策表

| 产物 | 归属 | 禁止位置 |
|---|---|---|
| 实体 / 聚合根 / 值对象 | `Domain` | Application、Web |
| 仓储**接口** | `Domain` | EF Core 层（接口必须领域可依赖） |
| 仓储**实现** | `EntityFrameworkCore` | Domain |
| 领域服务 | `Domain` | Application |
| DTO | `Application.Contracts` | Domain |
| 应用服务 | `Application` | Web/HttpApi |
| 权限定义 | `Application.Contracts` | Web |
| DTO↔实体映射 | `Application`（AutoMapper Profile） | 各处手写映射 |
| DbContext / 实体映射 / 迁移 | `EntityFrameworkCore` | Domain |
| 自定义控制器 | `HttpApi`（仅 AutoApi 覆盖不了的场形） | Application |
| 本地化 / 枚举 / 常量（跨层共享） | `Domain.Shared` | 各层重复定义 |
| 数据播种 | `Domain`（DataSeedContributor）+ `EntityFrameworkCore`（注册） | 手工 SQL 散落 |
| 单元测试 | `test/` 对应层测试项目 | src/ 内 |

## 3. 反模式

- ❌ 业务规则写在 AppService/Web 层 → 应下沉 Domain（聚合方法或领域服务）
- ❌ DTO 直接当实体用 / 实体直接序列化返回 → 必须经 DTO 与映射
- ❌ 仓储接口放 EF Core 层导致 Domain 依赖基础设施
- ❌ SQL/迁移脚本手工散落在 Web 目录 → 迁移只走 `EntityFrameworkCore` + `DbMigrator`
- ❌ 每层自定义一套异常/常量 → 统一 Domain.Shared

## 4. 与宿主项目的衔接

- 项目实际结构以 `specs/项目目录结构.md` 与现有代码为准；本树是**默认基线**。
- 新增模块落地时对照本树选层；偏离基线须在技术方案中说明理由。
- 分层职责细节见 `01-ddd-layering.md`，最佳实践 Do/Don't 见 `02-best-practices.md`。
