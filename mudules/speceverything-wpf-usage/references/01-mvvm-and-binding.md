# MVVM 三契约与绑定

> 来源：WPF 数据绑定官方文档（learn.microsoft.com/dotnet/desktop/wpf/data/data-binding-overview）、CommunityToolkit.Mvvm 文档（learn.microsoft.com/dotnet/communitytoolkit/mvvm）。[F] 标注：net48 与 .NET 8 无差异（除特别注明）。

## 1. 依赖属性（绑定目标契约）

可绑定属性必须注册为 DP；绑定引擎只经 `GetValue/SetValue` 通道写入。

```csharp
public class NodeView : Control
{
    // ① 注册：属性名 + 类型 + 宿主类 + 元数据（默认值/回调/行为标志）
    public static readonly DependencyProperty HeaderProperty =
        DependencyProperty.Register(
            nameof(Header), typeof(string), typeof(NodeView),
            new FrameworkPropertyMetadata(string.Empty,
                FrameworkPropertyMetadataOptions.AffectsMeasure,   // 值变化触发重新测量
                (d, e) => ((NodeView)d).OnHeaderChanged(e)));       // 变更回调

    // ② CLR 包装器：只含 GetValue/SetValue（不放业务逻辑）
    public string Header
    {
        get => (string)GetValue(HeaderProperty);
        set => SetValue(HeaderProperty, value);
    }
}
```

**值优先级**（裁决"改了没反应"）：动画 > 本地值 > Trigger > Setter > 继承 > 默认值；动画结束后默认 `FillBehavior.HoldEnd` 仍占位，恢复用 `control.BeginAnimation(prop, null)`。

**附加属性**（行为注入，不建子类）：

```csharp
public static readonly DependencyProperty EnableDragMoveProperty =
    DependencyProperty.RegisterAttached("EnableDragMove", typeof(bool), typeof(DragBehavior),
        new PropertyMetadata(false, OnEnableDragMoveChanged));   // 挂到任意 UIElement 上生效
```

## 2. INPC 绑定（源契约）

```csharp
// CommunityToolkit 源生成器（推荐）
public partial class PinViewModel : ObservableObject
{
    [ObservableProperty]
    private string name = "";        // → 生成 public string Name { get; set; }（含判等+通知）
}

// 模型层手写属性（SetProperty 模式）
public string Name
{
    get => _name;
    set => SetProperty(ref _name, value);   // 判等→赋值→广播，一行三事
}
```

- 集合：`ObservableCollection<T>` 只通知**增删**；元素内部属性变化要求元素类自身实现 INPC。
- `PropertyChanged` 传 `""`/`null` = 刷新该对象全部绑定（批量替换场景用）。
- 无 INPC 的源：OneWay 绑定**永不自动更新**；且绑定引擎走 PropertyDescriptor 静态订阅通道，**有泄漏风险**（见 references/04）。

## 3. 绑定管线（正反向）

```
正向（源→UI）：setter → SetProperty → PropertyChanged → 引擎匹配属性名
             → 重读源 → 转换器 → 线程封送检查 → 目标 SetValue → UI 更新
反向（UI→源，TwoWay）：目标 DP 变更 → UpdateSourceTrigger 判定时机
             → 验证(ValidationRule) → ConvertBack → 写源 CLR 属性
             → 源判等拦截（值相同不再广播）→ 不会死循环
```

**绑定诊断三板斧**（绑定失败默认静默，必须主动看）：

1. 输出窗口找绑定错误（典型 `System.Windows.Data Error: 40 : BindingExpression path error`）。
2. 单绑定精细追踪：`{Binding Name, diag:PresentationTraceSources.TraceLevel=High}`（输出完整解析过程）。
3. 运行时检查：Snoop / Live Visual Tree 看实际绑定源与 DP 值来源。

## 4. 命令（第三契约）

```csharp
// CommunityToolkit（推荐）
[RelayCommand(CanExecute = nameof(CanSave))]
private void Save() { /* ... */ }

[ObservableProperty]
[NotifyCanExecuteChangedFor(nameof(SaveCommand))]   // ★ 属性变化 → 命令重查 CanExecute
private bool isDirty;
```

- Button 监听 `ICommand.CanExecuteChanged`，**与 INPC 的 PropertyChanged 无关**——缺通知 → 按钮状态冻结。
- WPF 内置 `RoutedCommand`（如 `SystemCommands`）需在视觉树挂 `CommandBinding`；与 RelayCommand 并存，语义不同（路由级 vs 实例级）。
- VM 内事件出口：`Interaction.Triggers`（EventToCommand）或 attached behavior，禁止在 code-behind 写业务。

## 5. 跨 VM 通信：Messenger

```csharp
// 发送（任何层，含后台线程）
WeakReferenceMessenger.Default.Send(new DataReadyMessage { Payload = ... });

// 接收（UI 层；回调在发送方线程执行）
WeakReferenceMessenger.Default.Register<DataReadyMessage>(this, (r, e) =>
{
    Dispatcher.InvokeAsync(() => { /* 改 UI */ });   // 改控件必须封送
});
```

陷阱：注册 lambda **闭包捕获接收者**会让 `Weak` 版失效（注册表→委托→闭包→接收者 强引用链）；正确写法只用 `r` 参数。`StrongReferenceMessenger` 必须在生命周期终点 `Unregister`。

## 6. 校验

三层递进：`ValidationRule`（XAML 规则）→ `IDataErrorInfo`（同步索引校验）→ `INotifyDataErrorInfo`（异步/多错误，推荐）；错误可视化用 `Validation.ErrorTemplate`。[F] 三者在 net48/.NET 8 均可用。

## 7. 文档索引

- 数据绑定概述：https://learn.microsoft.com/dotnet/desktop/wpf/data/data-binding-overview
- INotifyDataErrorInfo：https://learn.microsoft.com/dotnet/api/system.componentmodel.inotifydataerrorinfo
- CommunityToolkit.Mvvm：https://learn.microsoft.com/dotnet/communitytoolkit/mvvm/
- 依赖属性值优先级：https://learn.microsoft.com/dotnet/desktop/wpf/properties/dependency-property-value-precedence
