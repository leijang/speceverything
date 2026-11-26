# 性能与泄漏

> 来源：WPF 性能优化官方文档（learn.microsoft.com/dotnet/desktop/wpf/advanced/optimizing-wpf-application-performance）、绑定泄漏社区共识（DEV/Blog，行为可实测验证）。[F] net48 与 .NET 8 一致。

## 1. 列表虚拟化（最常见性能问题）

```xml
<!-- ✅ 正确：ScrollViewer 不破坏虚拟化（ItemsControl 自带滚动区） -->
<ListBox ItemsSource="{Binding Rows}" Height="400"/>
```

**虚拟化失效清单**（列表卡顿先查这些）：

1. ❌ `StackPanel`（垂直无界高度）直接包 `ItemsControl` —— 给子项无限空间，全部实例化
2. ❌ `ScrollViewer` 外套自适应高度（Height=Auto 链）——视口无界
3. ❌ 分组 / `CanContentScroll=False` —— 关闭虚拟化
4. ❌ `VirtualizingStackPanel` 未启用（普通 ItemsControl 默认不虚拟化；ListBox 默认开）
5. ✅ 修复：约束视口高度 + `VirtualizingStackPanel` + `VirtualizationMode=Recycling`

## 2. Freezable 冻结（可冻结对象）

```csharp
var brush = new SolidColorBrush(Colors.SteelBlue);
brush.Freeze();     // 冻结后：不可变、可跨线程共享、免变更监听、更省资源
```

XAML 里 `po:Freeze="True"`；**注意**：冻结后改 `Color` 抛异常——换肤走"换字典条目"而非改实例。

## 3. 泄漏四源（Window 关闭后对象不释放）

### 3.1 绑定泄漏（源无 INPC）

```
无 INPC 源 → 引擎走 PropertyDescriptor.AddValueChanged（类型级静态存储）
→ 静态描述符强引用源实例 → 永不回收
修复：源实现 INPC（最正）/ Mode=OneTime / 显式断开
```

### 3.2 静态事件泄漏

```
static event 的订阅列表挂静态字段 → += 形成静态对象→委托→订阅者 强引用
→ 订阅者（Window）关闭后滞留；开关 20 次 = 20 个 Window 全在内存
修复：① 成对 -=（必须同一 handler 引用；内联 lambda 两次创建不相等，无法解除）
     ② WeakEventManager 弱引用订阅
```

### 3.3 Messenger 闭包陷阱（见 references/01 §5）

### 3.4 图片内存

```csharp
var bmp = new BitmapImage();
bmp.BeginInit();
bmp.CacheOption = BitmapCacheOption.OnLoad;   // 释放文件句柄（默认 OnDemand 持有）
bmp.DecodePixelWidth = 400;                   // 只解码需要的尺寸（大图显示缩略时必加）
bmp.EndInit();
```

大图列表（万级图片）必须配 `DecodePixelWidth` + 虚拟化，否则内存爆炸。

## 4. 渲染层优化速查

| 手段 | 说明 |
|---|---|
| 降低视觉树深度 | 每层都有 Measure/Arrange 成本；用 Snoop 看树深 |
| 固定尺寸优先 | `Width/Height` 明确值比 Auto 便宜；`AffectsMeasure` 元数据即为此设计 |
| TextBlock 显式排版 | 高频文本用 `TextOptions.TextFormattingMode="Display"` |
| 避免 Opacity 层级叠加 | 半透明多层引发软件渲染回退 |
| `CacheMode` 谨慎用 | `BitmapCache` 换渲染缓存，但占显存 |

## 5. 诊断工具链

| 工具 | 用途 |
|---|---|
| **Snoop** | 视觉树/属性值来源/绑定表达式/事件路由实测（首选） |
| **Live Visual Tree**（VS 内置） | 运行时视觉树 + 选择高亮 |
| **WPF TraceSource** | 绑定错误详细级别（输出窗口） |
| **dotMemory / VS 诊断工具** | 快照对比：retention path 找 PropertyDescriptor/静态事件引用链 |
| **PerfView / dotnet-counters** | UI 线程占用、GC 压力 |

**泄漏判定口诀（附说明）**："**快照对比找 retention path**"——内存快照 A/B 对比，对滞留实例沿引用链向上看谁拽着它：见 `PropertyDescriptor` → 绑定泄漏；见静态 `EventHandler` 列表 → 静态事件泄漏；见 `Messenger` 注册表 → 闭包陷阱。
