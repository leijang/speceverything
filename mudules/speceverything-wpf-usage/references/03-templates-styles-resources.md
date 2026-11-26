# 模板、样式与资源

> 来源：WPF Styling and Templating 官方文档（learn.microsoft.com/dotnet/desktop/wpf/controls/styles-templates-overview）、资源概述。[F] net48 与 .NET 8 无差异。

## 1. 模板家族（职责边界）

| 模板 | 职责 | 挂在哪 |
|---|---|---|
| `ControlTemplate` | 控件的**外观骨架**（长什么样、内部结构、模板触发器） | Style.Template / Themes/generic.xaml |
| `DataTemplate` | **数据对象**的呈现（一个 Person → 卡片） | ContentTemplate / ItemTemplate / 隐式（DataType） |
| `ItemsPanelTemplate` | ItemsControl 条目的**排布容器** | ItemsPanel |
| `HierarchicalDataTemplate` | TreeView 的多级数据模板 | ItemTemplate（分组数据源） |

**铁律**：ControlTemplate 必须有 `ContentPresenter`（内容插槽）——没有它，`Content`（文字/内容）不显示（控件仍可点击）。

```xml
<ControlTemplate x:Key="FlatBtn" TargetType="Button">
  <Border CornerRadius="8" Background="{TemplateBinding Background}">
    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
  </Border>
</ControlTemplate>
```

## 2. 模板内取控件属性：TemplateBinding vs 完整 Binding

```xml
<Border Padding="{TemplateBinding Padding}"/>            <!-- 轻量：编译期、只读 OneWay -->
<Border Padding="{Binding Padding, RelativeSource={RelativeSource TemplatedParent}}"/>
                                                          <!-- 完整：支持 TwoWay/转换器 -->
```

- `TemplateBinding` ≈ TemplatedParent 的轻量版，**只引用模板目标控件自身的 DP**，不认 DataContext。
- **DataTemplate 里没有 TemplatedParent**（它不是 ControlTemplate）——找外层用 `FindAncestor`：

```xml
<Button Command="{Binding DataContext.DeleteCommand,
        RelativeSource={RelativeSource AncestorType=ItemsControl}}"/>
```

## 3. 触发器与位阶

```xml
<ControlTemplate TargetType="Button">
  <Border x:Name="border" Background="{TemplateBinding Background}"/>
  <ControlTemplate.Triggers>                        <!-- 模板 Trigger：位阶高于样式 Trigger -->
    <Trigger Property="IsMouseOver" Value="True">
      <Setter TargetName="border" Property="Background" Value="Gold"/>
    </Trigger>
  </ControlTemplate.Triggers>
</ControlTemplate>
```

**位阶表**（裁决冲突）：属性强制(Coerce) > 动画 > 本地值 > 模板Trigger > 样式Trigger > 样式Setter > 继承 > 默认值。

**坑**：默认控件的主题模板**自带** Trigger（如 Button 的悬停视觉）——样式 Trigger 压不过它；改悬停外观必须**重写 ControlTemplate**。Setter 改背景能生效是因为模板把背景 `{TemplateBinding Background}` 了。

`VisualStateManager` vs Trigger：State 视觉复杂（多状态互斥/过渡动画）用 VSM；简单条件切换用 Trigger。二者都需模板配合。

## 4. 样式组织（令牌 → 控件样式 → 主题）

```xml
<!-- Themes/Basic/Colors.xaml：设计令牌层 -->
<Color x:Key="AccentColor">#0078D4</Color>

<!-- Themes/Basic/Brushes.xaml：令牌 → 画刷（冻结优化） -->
<SolidColorBrush po:Freeze="True" x:Key="AccentBrush" Color="{StaticResource AccentColor}"/>

<!-- Themes/Styles/ButtonTheme.xaml：控件样式层（消费令牌） -->
<Style TargetType="Button" x:Key="DemoButton">
  <Setter Property="Background" Value="{DynamicResource AccentBrush}"/>  <!-- 换肤必须 Dynamic -->
  <Setter Property="Template" Value="{StaticResource FlatBtnTemplate}"/>
</Style>
```

**资源查找链**：元素 Resources → 逻辑树父级 → Application.Resources → 主题字典（**走逻辑树**）。

## 5. StaticResource vs DynamicResource

| 场景 | Static | Dynamic |
|---|---|---|
| 性能/启动 | ✅ 编译期解析，快 | 运行期表达式，略慢 |
| 换肤（换字典条目） | ❌ 不跟踪 | ✅ |
| 资源定义在使用点之后 | ❌ 找不到抛异常 | ✅ |
| 大对象延迟加载 | ❌ | ✅ |

注意：`StaticResource` 返回**同一实例的引用**（不是深拷贝）——改未冻结画刷的 Color 仍会传播 UI（Freezable 变更通知）；换肤的正规姿势是**换字典条目**而非改实例。

## 6. 换肤标准做法

1. 令牌层分离（Colors/Brushes 独立字典）。
2. 主题字典（Dark/Light）**同名 Key**，运行期替换 `Application.Resources.MergedDictionaries[0]`。
3. 消费端一律 `DynamicResource` 绑令牌 Key。
4. 冻结画刷注意：Frozen 后不可改 Color（换肤走换条目路线）。

## 7. 隐式样式与 BasedOn

```xml
<Style TargetType="Button">                    <!-- 无 Key：隐式，作用域内所有 Button 生效 -->
  <Style.BasedOn>
    <StaticResource ResourceKey="BaseButton"/>  <!-- 继承父样式，避免复制 -->
  </Style.BasedOn>
</Style>
```
