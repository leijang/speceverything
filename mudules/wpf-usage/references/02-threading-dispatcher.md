# 线程模型：Dispatcher 与异步

> 来源：WPF Threading Model（learn.microsoft.com/dotnet/desktop/wpf/advanced/threading-model）、async/await 官方文档（learn.microsoft.com/dotnet/csharp/asynchronous-programming）。[F] net48 与 .NET 8 行为一致。

## 1. 线程亲和与 Dispatcher

- WPF 的 UI 对象派生自 `DispatcherObject`：**每个对象绑定创建它的线程**，跨线程访问抛 `InvalidOperationException`。
- UI 线程内是**消息泵 + Dispatcher 优先级队列**：输入/渲染/数据绑定按优先级调度。
- 封送 API 选择：

```csharp
dispatcher.Invoke(action);        // 同步等待完成 —— 阻塞调用方，慎用（可致死锁）
await dispatcher.InvokeAsync(action);   // 推荐：异步排队，优先级可选（Background/Loaded/DataBind）
dispatcher.BeginInvoke(action);   // 旧 API，等同 InvokeAsync 的非泛型形态
```

## 2. async/await 三条铁律

```csharp
// ① 事件处理器是 async void 的唯一合法场景（其他地方禁止 async void：异常直接崩进程）
private async void Button_Click(object sender, RoutedEventArgs e)
{
    var data = await _service.LoadAsync();   // await 期间 UI 线程立即"让出"（处理消息，不卡界面）
    statusText.Text = data;                  // ← 续体默认回 UI 线程：直接改控件合法
}

// ② 续体落点由"await 时刻的 SynchronizationContext"决定，不是任务内部线程决定
//    UI 线程上 await → 捕获 DispatcherSynchronizationContext → 续体回 UI
//    线程池上 await → Current 为 null → 续体落线程池

// ③ .Result / .Wait() 在 UI 线程 = 死锁经典现场（续体等 UI，UI 等结果）
```

## 3. ConfigureAwait 纪律（分层治理）

| 层 | 写法 | 理由 |
|---|---|---|
| 库/服务/算法层 | `await x.ConfigureAwait(false)` | 续体不依赖调用方线程；防调用方 `.Result` 死锁；省上下文捕获 |
| UI 事件层 | 默认（不写） | 续体回 UI 线程，直接改控件 |

**它治理/不治理**：

- ✅ 治理：同步断点死锁（不可传染区被迫 `.Result` 时，链上续体不再索要被阻塞的线程）
- ❌ 不治理：async 签名传染（方法仍 async/Task）；阻塞行为本身；async void 崩溃

**不可传染区预取模式**（getter/构造函数不能 async）：

```csharp
private Task<RobotState>? _stateTask;
public SimulationController() => _stateTask = LoadStateAsync();  // 构造时启动

public RobotState State => _stateTask!.IsCompleted
    ? _stateTask.Result                       // 已完成 → 安全取值
    : RobotState.Unknown;                     // 未就绪 → 占位，UI 稍后经绑定刷新
```

## 4. 后台回调回 UI（gRPC/事件/组件库）

```csharp
// 后台线程（gRPC 回调/计算完成）里通知 UI：经 Messenger 或直接 Dispatcher
Application.Current?.Dispatcher.InvokeAsync(() => uiText.Text = msg);
// 或经事件总线，在 UI 侧接收处封送：
WeakReferenceMessenger.Default.Register<DoneMsg>(this, (r, e) =>
    ((MainView)r).Dispatcher.InvokeAsync(() => ((MainView)r).Show(e.Data)));
```

**注意**：`INotifyPropertyChanged` 属性的修改**不需要**封送（绑定引擎自动 marshal）；直接操作 UI 元素/Visual 树**必须**封送——两条规则不可互相外推。

## 5. 长任务的取消与进度

```csharp
CancellationTokenSource _cts = new();
async Task RunAsync(CancellationToken ct, IProgress<int> progress)
{
    for (int i = 0; i < 100; i++)
    {
        ct.ThrowIfCancellationRequested();          // 协作式取消
        progress.Report(i);                         // IProgress 自动回 UI 线程回调
        await Task.Delay(10, ct);
    }
}
// 窗口关闭：_cts.Cancel(); 事件处理器捕获 OperationCanceledException 静默处理
```

## 6. 诊断

- 死锁排查：卡住线程的调用栈里找 `WaitForSynchronizationContext` / `.Result`。
- 线程号实测：`Environment.CurrentManagedThreadId` 打日志，或并行堆栈窗口。
- 全局兜底：`Application.DispatcherUnhandledException` + `TaskScheduler.UnobservedTaskException` 记日志，防止 async void 崩进程。
