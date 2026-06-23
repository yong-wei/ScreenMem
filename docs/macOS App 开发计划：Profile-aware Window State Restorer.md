# macOS App 开发计划：Profile-aware Window State Restorer

## 1. 项目定位

开发一个 macOS 菜单栏常驻 App，用于在不同显示器组合之间自动延续窗口状态。

该 App 不是 Magnet、Moom、Rectangle 这类窗口编排工具，也不负责手动分屏、启动 App、创建窗口、关闭窗口、跨 Space 管理或全屏窗口管理。它只做一件事：

当用户处于某个已创建的显示器 Profile 下时，后台自动学习当前已开启普通窗口的位置和尺寸；当显示器组合发生变化并稳定后，自动根据已有 Profile 将当前仍然存在的窗口恢复到该 Profile 下最近一次学习到的位置。

核心原则：

用户怎样摆放窗口，App 就怎样记忆。
用户关闭的窗口，App 不负责恢复。
用户没有创建 Profile 的显示器组合，不自动建立 Profile。
未知显示器组合下，只基于已有 Profile 和已识别显示器做部分恢复。
整个过程尽量无感，但必须有暂停、日志和权限诊断能力。

## 2. 目标用户场景

典型用户使用 MacBook 连接不同地点的外接显示器工作。

家里：

- MacBook 内屏
- 外接 A1
- 外接 A2
- Codex、Chrome、Terminal、QQ、微信、VSCode 等窗口各有固定习惯位置

单位无 iPad：

- MacBook 内屏
- 外接 B1
- 外接 B2
- 同一批 App 需要按单位显示器布局恢复

单位有 Sidecar iPad：

- MacBook 内屏
- 外接 B1
- 外接 B2
- Sidecar iPad
- iPad 作为一个独立显示器参与 Profile 区分

用户希望：
连接显示器后，App 自动识别当前显示器组合。如果当前组合对应用户已经创建的 Profile，就恢复该 Profile 最近一次学习到的窗口状态。之后窗口变化继续自动学习。切换到其他场所时同理。

## 3. 明确不做的功能

MVP 不实现以下功能：

- 不替代 Magnet，不提供复杂手动分屏动作。
- 不启动缺失 App。
- 不创建已关闭窗口。
- 不恢复 Chrome 标签页。
- 不识别浏览器标签内容。
- 不管理真正 macOS 全屏窗口。
- 不跨 Space 移动窗口。
- 不管理 Stage Manager 特殊状态。
- 不做云同步。
- 不做复杂布局编辑器。
- 不做 AI 语义识别窗口。
- 不自动创建 Profile。
- 不在未知 Profile 下学习状态。

这些限制必须写入 README，避免后续开发膨胀。

## 4. 用户行为契约

### 4.1 Profile 创建

用户主动在当前显示器组合下点击：

“Create Profile from Current Displays”

App 创建一个 Profile，记录当前显示器集合、显示器指纹、显示器相对布局、MacBook 内屏身份以及当前窗口状态。

只有用户主动创建过的 Profile 才允许自动学习。

### 4.2 自动学习

当当前显示器组合精确匹配某个已创建 Profile 时：

- App 进入该 Profile 的 Learning 状态。
- 后台持续观察当前普通窗口集合。
- 用户移动或缩放窗口后，不立即写入。
- 等窗口状态稳定 1–3 秒后，将最新状态写入该 Profile。
- 用户关闭窗口后，该窗口从该 Profile 的活跃状态中移除，但应有短暂 tombstone 宽限期，避免系统抖动误删。
- 用户新开窗口后，如果它是普通可见窗口，则纳入学习。

### 4.3 自动恢复

当显示器组合发生变化时：

- 立即进入 DisplayChanging / Protection 状态。
- 暂停学习，避免把 macOS 切换过程中的混乱窗口状态写入 Profile。
- 等显示器组合稳定后再恢复。
- 如果精确匹配已创建 Profile，恢复该 Profile。
- 如果没有精确匹配，不创建新 Profile，只尝试从最相似的已有 Profile 做部分恢复。
- 恢复完成并稳定后，如果当前组合精确匹配 Profile，恢复学习；如果不匹配，保持 Unmanaged 状态，不学习。

### 4.4 未知显示器组合

未知组合不自动创建 Profile。

但如果当前组合中包含以前识别过的显示器，应做部分恢复：

- 已识别显示器上的窗口，尽量恢复到该显示器。
- 目标显示器不存在或无法识别时，窗口默认回落到 MacBook 内屏。
- 新显示器默认空白。
- 当前组合不进入自动学习，除非用户主动创建新 Profile。

例如：

已有 Office-B1-B2。
当前变成 Office-B1-B2-iPad，但用户尚未创建 iPad Profile。
App 应将原 B1、B2、MacBook 上的窗口恢复到 B1、B2、MacBook；iPad 保持空白。
用户如果想让 QQ、微信以后自动去 iPad，需要主动创建 Office-B1-B2-iPad Profile，然后移动窗口，App 自动学习。

## 5. 技术栈建议

使用 Swift + SwiftUI + AppKit。

建议项目形态：

- SwiftUI 菜单栏 App
- AppKit 桥接用于系统级窗口访问、菜单栏、权限、生命周期
- Accessibility API 用于枚举和移动其他 App 窗口
- CoreGraphics / AppKit 用于显示器枚举、显示器 ID、显示器变化监听
- JSON 或 SQLite 持久化 Profile 和窗口状态

MVP 阶段建议使用 JSON 文件持久化，原因是数据量小、调试直观、便于 Codex 快速实现。后续如果状态变多，再迁移 SQLite。

本地存储路径建议：

```
~/Library/Application Support/<AppName>/profiles.json
```

日志可使用：

```
~/Library/Logs/<AppName>/restore.log
```

或统一使用 OSLog，并在 App 内提供“最近一次恢复结果”。

## 6. 系统架构

建议模块划分：

```text
App/
  AppEntry/
    MainApp.swift
    StatusBarController.swift

  Display/
    DisplayService.swift
    DisplaySnapshot.swift
    DisplayIdentity.swift
    DisplayProfileMatcher.swift

  Window/
    WindowService.swift
    AccessibilityPermissionService.swift
    AXWindowReader.swift
    AXWindowMover.swift
    WindowSnapshot.swift
    WindowMatcher.swift

  Profile/
    Profile.swift
    ProfileStore.swift
    ProfileState.swift
    ProfileLearningService.swift

  Engine/
    RestorationEngine.swift
    StateMachine.swift
    Debouncer.swift
    LateWindowMonitor.swift

  UI/
    MenuBarView.swift
    SettingsWindow.swift
    ProfileListView.swift
    PermissionView.swift
    RestoreLogView.swift

  Logging/
    AppLogger.swift
    RestoreReport.swift

Tests/
  DisplayProfileMatcherTests.swift
  WindowMatcherTests.swift
  CoordinateTransformTests.swift
  StateMachineTests.swift
  ProfileStoreTests.swift
```

核心依赖方向：

- UI 只调用 Engine 和 Store，不直接操作 AX。
- Engine 调用 DisplayService、WindowService、ProfileStore。
- WindowService 隐藏 Accessibility 细节。
- DisplayService 隐藏 NSScreen / CoreGraphics 细节。
- ProfileStore 只负责读写，不负责匹配和恢复。
- 所有系统 API 外围都要有 protocol，方便测试时 mock。

## 7. 核心数据模型

### 7.1 DisplayIdentity

用于跨 Profile 识别显示器。

字段建议：

```swift
struct DisplayIdentity: Codable, Hashable {
    let stableID: String
    let localizedName: String
    let isBuiltin: Bool
    let vendorNumber: UInt32?
    let modelNumber: UInt32?
    let serialNumber: UInt32?
    let displayUUID: String?
    let nominalPixelWidth: Int
    let nominalPixelHeight: Int
    let backingScaleFactor: Double
}
```

说明：

- MacBook 内屏必须有特殊标记 `isBuiltin = true`。
- 外接显示器优先使用 UUID / vendor / model / serial 等稳定信息。
- 如果某些信息不可得，则组合 name + resolution + scale 形成 fallback identity。
- Sidecar iPad 当作普通外接显示器处理，但应允许其 identity 不稳定，因此需要通过 name/resolution/scale 辅助匹配。

### 7.2 DisplaySnapshot

用于描述当前某次采样中的显示器状态。

```swift
struct DisplaySnapshot: Codable, Hashable {
    let identity: DisplayIdentity
    let frame: CGRect
    let visibleFrame: CGRect
    let isMain: Bool
    let orderIndex: Int
}
```

说明：

- `frame` 表示完整显示器坐标。
- `visibleFrame` 排除菜单栏和 Dock，更适合窗口恢复。
- 窗口坐标应优先相对 `visibleFrame` 保存。

### 7.3 Profile

```swift
struct Profile: Codable, Identifiable {
    let id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date

    var displaySetFingerprint: String
    var displays: [DisplayIdentity]

    var windowStates: [WindowState]
}
```

### 7.4 WindowSnapshot

表示当前实时枚举到的窗口。

```swift
struct WindowSnapshot: Codable, Hashable {
    let runtimeWindowID: String?
    let pid: pid_t
    let bundleIdentifier: String?
    let appName: String
    let processName: String?

    let title: String?
    let role: String?
    let subrole: String?

    let frame: CGRect
    let isMinimized: Bool
    let isFullscreenLike: Bool
    let isMovable: Bool
    let isResizable: Bool

    let appWindowOrdinal: Int
    let observedAt: Date
}
```

说明：

- `runtimeWindowID` 可以来自当前会话内可获得的窗口编号或合成 ID，只用于运行期增强匹配，不要求跨重启稳定。
- `bundleIdentifier` 优先于 appName，但 UI 上显示 appName。
- `title` 只作为辅助，不作为主要身份依据。
- Chrome 不依赖标题匹配，因为网页标题变化频繁。
- 多个 Chrome 窗口按同 App 内独立窗口处理。

### 7.5 WindowState

表示某个 Profile 下学习到的窗口状态。

```swift
struct WindowState: Codable, Identifiable {
    let id: UUID

    var bundleIdentifier: String?
    var appName: String
    var processName: String?

    var titleHint: String?
    var role: String?
    var subrole: String?

    var appWindowOrdinal: Int
    var lastRuntimeWindowID: String?

    var targetDisplayStableID: String
    var normalizedFrame: NormalizedRect
    var absoluteFrameHint: CGRect

    var isMinimized: Bool
    var lastSeenAt: Date
    var lastUpdatedAt: Date
}
```

### 7.6 NormalizedRect

```swift
struct NormalizedRect: Codable, Hashable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}
```

说明：

- 坐标相对目标显示器 `visibleFrame` 保存。
- 恢复时按当前显示器 visibleFrame 反算实际 frame。
- 要做边界 clamp，避免窗口跑出屏幕。

## 8. Profile 匹配规则

### 8.1 精确匹配

当前显示器集合与某 Profile 的显示器集合完全一致，视为精确匹配。

比较时应忽略显示器数组顺序，按 stableID 排序后生成 fingerprint。

精确匹配后：

- 自动恢复。
- 恢复后进入 Learning。
- 后续窗口变化自动写入该 Profile。

### 8.2 部分匹配

如果没有精确 Profile：

- 找出与当前显示器集合重合数量最多的已有 Profile。
- 重合数量相同，选择最近使用的 Profile。
- 如果仍不唯一，可选择最近恢复成功的 Profile。
- 不自动创建 Profile。
- 不进入 Learning。
- 只执行部分恢复。

部分恢复规则：

- 目标显示器当前存在：恢复到该显示器。
- 目标显示器当前不存在：恢复到 MacBook 内屏。
- 如果 MacBook 内屏不可用，恢复到当前主显示器。
- 当前新出现但 Profile 中没有的显示器：不放窗口，保持空白。

### 8.3 无匹配

如果没有任何显示器重合：

- 不移动窗口。
- 菜单栏状态显示“Unknown Display Set”。
- 提供“Create Profile”入口。
- 不学习。

## 9. 窗口匹配规则

不要实现复杂语义匹配。只做状态延续需要的轻量匹配。

匹配优先级：

1. 同一运行期窗口 ID 匹配。
2. bundleIdentifier + role/subrole + appWindowOrdinal。
3. appName + role/subrole + appWindowOrdinal。
4. bundleIdentifier + titleHint 弱匹配。
5. appName + titleHint 弱匹配。

注意：

- 应用名称和 bundleIdentifier 是主依据。
- 标题只作为辅助。
- Chrome 标题权重降低。
- VSCode / Terminal 标题可以作为辅助。
- 匹配失败不报错，只记录 skipped。
- 同一 App 多窗口数量变化时，只恢复能匹配到的窗口。
- 用户关闭的窗口不重建。
- 用户新开的窗口在 Learning 状态下会被学习；在刚切换 Profile 后的监听窗口期内，如果能匹配历史状态，则恢复一次。

## 10. 状态机

实现 `RestorationStateMachine`。

状态建议：

```text
Idle
PermissionMissing
DisplayChanging
DisplayStabilizing
ExactProfileMatched(profileID)
PartialProfileMatched(sourceProfileID)
Restoring(profileID or sourceProfileID)
LateWindowMonitoring(profileID or sourceProfileID)
Learning(profileID)
UnmanagedDisplaySet
Paused
```

### 10.1 显示器变化流程

```text
Display change event
  -> DisplayChanging
  -> pause learning
  -> wait debounce interval
  -> sample displays
  -> wait until display snapshots stable
  -> match profile
  -> restore
  -> late window monitor
  -> if exact profile: Learning
  -> if partial/no match: UnmanagedDisplaySet
```

### 10.2 切换保护期

在 DisplayChanging、DisplayStabilizing、Restoring 状态下，禁止写入 Profile。

这是硬规则。
任何窗口变化事件在保护期内只可用于恢复判断，不可覆盖已保存状态。

### 10.3 Learning 状态

只有精确匹配用户创建的 Profile 后才能进入 Learning。

Learning 中：

- 周期采样当前窗口集合。
- 检测窗口出现、关闭、移动、缩放。
- 通过 debounce 等状态稳定后写入 Profile。
- 写入时使用 atomic write，避免 profiles.json 损坏。

## 11. 自动学习策略

### 11.1 采样方式

MVP 建议先使用轮询：

- 每 1 秒枚举当前普通窗口。
- 检测窗口集合与位置变化。
- 如果发生变化，启动 2 秒 debounce。
- debounce 期间如果继续变化，重新计时。
- debounce 结束后写入 Profile。

原因：

- 实现简单。
- 不依赖每个 App 的 AXObserver 差异。
- 对用户窗口数量而言性能压力可控。
- 更适合第一版快速验证。

后续可优化为 AXObserver：

- 监听 window moved
- window resized
- window created
- window destroyed
- app launched
- app terminated

但 MVP 不建议一开始就做复杂事件订阅。

### 11.2 写入条件

满足以下条件才写入：

- 当前是 Learning(profileID)。
- Accessibility 权限可用。
- 当前显示器集合仍精确匹配该 Profile。
- 当前不在 restore protection window。
- 窗口状态已经稳定超过 debounce 时间。
- 当前采样结果非空。

### 11.3 关闭窗口处理

窗口消失后不要立即从 Profile 删除。

建议：

- 先标记为 tombstone。
- tombstone 保留 30–60 秒。
- 如果窗口在宽限期内重新出现，取消 tombstone。
- 如果超过宽限期仍不存在，从 active windowStates 中删除。

原因：显示器切换、App 短暂无响应、系统恢复时可能造成窗口短暂不可见，立即删除容易丢状态。

## 12. 恢复策略

### 12.1 恢复前准备

恢复前先枚举：

- 当前显示器集合
- 当前普通窗口集合
- 当前可移动、可调整大小窗口
- 当前 Profile 或部分匹配 Profile

跳过以下窗口：

- 最小化窗口，默认不取消最小化
- 全屏窗口
- 不可移动窗口
- 不可调整尺寸窗口
- 系统特殊窗口
- 没有权限访问的窗口
- 菜单栏、Dock、桌面、浮层类窗口

### 12.2 坐标转换

保存时：

```text
normalized.x = (window.x - display.visibleFrame.x) / display.visibleFrame.width
normalized.y = (window.y - display.visibleFrame.y) / display.visibleFrame.height
normalized.width = window.width / display.visibleFrame.width
normalized.height = window.height / display.visibleFrame.height
```

恢复时：

```text
window.x = targetVisibleFrame.x + normalized.x * targetVisibleFrame.width
window.y = targetVisibleFrame.y + normalized.y * targetVisibleFrame.height
window.width = normalized.width * targetVisibleFrame.width
window.height = normalized.height * targetVisibleFrame.height
```

恢复前做 clamp：

- 最小宽度建议 300 pt。
- 最小高度建议 200 pt。
- 不允许窗口完全移出 visibleFrame。
- 如果尺寸大于目标显示器 visibleFrame，缩小到可见区域内。

### 12.3 恢复动作顺序

建议：

1. 先设置 size。
2. 再设置 position。
3. 如果失败，再尝试 position 后 size。
4. 对失败原因做记录。

不同 App 对 AX size/position 的接受顺序可能不同，必须记录失败并继续处理其他窗口，不要因为一个窗口失败中断整个恢复。

### 12.4 Late Window Monitor

Profile 切换后的 60 秒内启动迟到窗口监听。

逻辑：

- 如果新窗口出现，且匹配当前 Profile 中未恢复的 WindowState，则自动恢复一次。
- 如果用户已经手工移动过该窗口，不再抢回。
- 60 秒后关闭监听。
- 之后新窗口只进入学习，不主动移动。

## 13. 菜单栏 UI

MVP 使用菜单栏常驻，不需要复杂主窗口。

菜单栏显示：

- 当前状态：Learning / Restoring / Unmanaged / Paused / Permission Missing
- 当前 Profile 名称
- 当前显示器数量
- 最近一次恢复结果摘要

菜单项建议：

```text
Current Profile: Office-B1-B2
Status: Learning

Create Profile from Current Displays...
Restore Now
Pause Restore for 10 Minutes
Pause Learning
Pause All

Profiles...
Recent Restore Report...
Permissions...
Quit
```

### 13.1 Profiles 窗口

简单列表即可：

- Profile 名称
- 创建时间
- 最近更新时间
- 显示器数量
- 最近学习窗口数量
- Rename
- Delete
- Duplicate
- Set as Manual Restore Source，可选

不要做复杂布局编辑器。

### 13.2 Recent Restore Report

显示最近一次恢复：

```text
Profile: Office-B1-B2
Mode: Exact Match
Started: 2026-xx-xx xx:xx
Windows found: 12
Restored: 9
Skipped: 3

Skipped:
- WeChat: minimized
- Chrome: no matching state
- System Settings: not resizable
```

这个界面很重要，用于判断 App 是否工作正常。

## 14. 权限处理

启动时检查 Accessibility 权限。

如果没有权限：

- 菜单栏状态显示 Permission Missing。
- 打开 PermissionView。
- 提供按钮引导用户打开 System Settings。
- 不进入 Learning。
- 不执行 Restore。
- 可以显示当前显示器信息，但不能控制窗口。

不要在没有权限时静默失败。

## 15. 开发阶段

### Phase 0：项目骨架

目标：

- 建立 SwiftUI macOS 菜单栏 App。
- 建立基本目录结构。
- 建立 `script/build_and_run.sh`。
- 建立 `.codex/environments/environment.toml`，让 Codex 有 Run 按钮。
- App 可启动、可退出、可显示菜单栏状态。

验收：

- `./script/build_and_run.sh` 可以构建并启动 App。
- 菜单栏图标出现。
- Quit 可用。
- README 写清项目定位和不做事项。

### Phase 1：显示器识别与 Profile 创建

目标：

- 实现 DisplayService。
- 枚举当前 NSScreen / CoreGraphics 显示器。
- 识别 MacBook 内屏。
- 生成 DisplayIdentity。
- 生成 displaySetFingerprint。
- 实现 ProfileStore JSON 读写。
- 支持“Create Profile from Current Displays”。

验收：

- App 能显示当前显示器列表。
- 创建 Profile 后 profiles.json 中有记录。
- 同一显示器组合重新连接后 fingerprint 稳定。
- Sidecar 出现时显示为独立显示器。
- 未知组合不自动创建 Profile。

### Phase 2：Accessibility 权限与窗口枚举

目标：

- 实现 AccessibilityPermissionService。
- 实现 WindowService。
- 枚举当前普通窗口。
- 读取 appName、bundleIdentifier、pid、titleHint、frame、minimized、role/subrole。
- 过滤系统窗口、不可见窗口、特殊窗口。

验收：

- 无权限时显示 Permission Missing。
- 授权后能列出当前普通窗口。
- Chrome 多窗口应显示为多个独立 WindowSnapshot。
- QQ、微信多个窗口应显示为多个独立 WindowSnapshot。
- 最小化窗口不参与恢复，但可记录状态。

### Phase 3：自动学习

目标：

- 实现 Learning 状态。
- 当前显示器集合精确匹配 Profile 时，自动学习窗口状态。
- 窗口移动或缩放后延迟写入。
- 关闭窗口后 tombstone，超时删除。
- 新开窗口后纳入学习。

验收：

- 创建 Profile 后，移动窗口，等待 2 秒，profiles.json 更新。
- 快速拖动窗口时不保存中间状态。
- 关闭窗口后不会在恢复时重建。
- 切换保护期内不写入 Profile。

### Phase 4：精确 Profile 自动恢复

目标：

- 监听显示器变化。
- 实现显示器稳定检测。
- 实现 RestorationEngine。
- 精确 Profile 匹配后自动恢复窗口。
- 恢复期间暂停学习。
- 恢复后进入 Learning。

验收：

- 在 Profile A 下摆放窗口，保存学习。
- 切换到 Profile B，再切回 Profile A。
- 当前仍存在的窗口自动回到 Profile A 最近位置。
- 关闭的窗口不恢复。
- 恢复失败不影响其他窗口。

### Phase 5：未知组合与部分恢复

目标：

- 实现 PartialProfileMatched。
- 未知显示器组合下不创建 Profile。
- 选择最相似已有 Profile。
- 对已识别显示器执行部分恢复。
- 缺失显示器目标回落到 MacBook。
- 新显示器保持空白。
- 不进入 Learning。

验收：

- 已有 Office-B1-B2。
- 接入 B1-B2-iPad，但没有 iPad Profile。
- B1/B2/MacBook 的窗口按已有状态恢复。
- iPad 不主动放窗口。
- 状态显示 Unmanaged 或 Partial Restore。
- profiles.json 不新增 Profile。
- 窗口变化不写入任何 Profile。

### Phase 6：迟到窗口监听

目标：

- Profile 切换后启动 60 秒 LateWindowMonitor。
- 新出现窗口如果匹配历史状态，恢复一次。
- 超过监听窗口期，新窗口只学习，不主动移动。

验收：

- 切换 Profile 后，延迟打开 VSCode。
- 60 秒内打开时自动恢复到历史位置。
- 60 秒后打开时不主动移动。
- 用户手动移动过的窗口不再被抢回。

### Phase 7：菜单栏 UI 与日志

目标：

- 完成菜单栏状态显示。
- 完成 Profiles 窗口。
- 完成 Recent Restore Report。
- 完成 Pause Restore / Pause Learning / Pause All。
- 完成 Restore Now。

验收：

- 用户能看到当前 Profile 和状态。
- 用户能暂停自动行为。
- 用户能查看最近一次恢复成功/失败明细。
- 用户能删除或重命名 Profile。
- Restore Now 可手动触发当前匹配 Profile 的恢复。

### Phase 8：测试与硬化

目标：

- 增加单元测试。
- 增加 mock DisplayProvider / WindowProvider。
- 增加状态机测试。
- 增加坐标转换测试。
- 增加 Profile 匹配测试。
- 增加窗口匹配测试。
- 增加 JSON store atomic write 测试。

验收：

- 坐标归一化和反归一化误差可控。
- Profile exact/partial/no-match 行为符合预期。
- DisplayChanging 期间不会写入状态。
- Learning 只在 exact profile 下发生。
- partial profile 不学习。
- tombstone 超时删除逻辑正确。
- 运行 build 和 test 均通过。

## 16. 手工测试矩阵

至少完成以下测试：

### 测试 1：MacBook 单屏

- MacBook 单屏创建 Profile。
- 打开 Chrome、Terminal、VSCode。
- 移动窗口。
- 等待自动学习。
- Restore Now。
- 窗口回到学习位置。

### 测试 2：双外接显示器

- 连接 A1、A2。
- 创建 Home Profile。
- 摆放多个窗口。
- 断开外接屏。
- 重新连接。
- App 自动恢复。

### 测试 3：单位 Profile

- 连接 B1、B2。
- 创建 Office Profile。
- 摆放窗口。
- 切换到 Home。
- 再回 Office。
- Office 布局恢复。

### 测试 4：Sidecar 未建 Profile

- 已有 Office-B1-B2。
- 开启 Sidecar iPad。
- 不创建新 Profile。
- App 只部分恢复 B1/B2/MacBook。
- iPad 保持空白。
- 当前状态不学习。

### 测试 5：Sidecar 建 Profile

- 在 B1/B2/iPad 下创建新 Profile。
- 将 QQ、微信拖到 iPad。
- 等待学习。
- 断开 iPad。
- 再连接 iPad。
- QQ、微信如果窗口仍存在，应恢复到 iPad。

### 测试 6：关闭窗口

- 在某 Profile 下关闭一个 Chrome 窗口。
- 等待 tombstone 超时。
- 切换 Profile 后再回来。
- 关闭的 Chrome 窗口不被恢复。

### 测试 7：Chrome 多窗口

- 打开多个 Chrome 独立窗口。
- 分别放到不同显示器。
- 切换 Profile。
- 恢复时按同 App 多窗口尽力匹配。
- 不依赖标签页标题。

### 测试 8：最小化与全屏

- 最小化微信窗口。
- 将 VSCode 设为真正全屏。
- 切换 Profile。
- App 不强制展开最小化窗口。
- App 跳过真正全屏窗口。
- 日志中说明 skipped 原因。

## 17. 风险与处理

### 风险 1：窗口身份无法长期稳定

处理：

- 明确使用 best-effort 匹配。
- 主依据为 bundleIdentifier / appName / ordinal。
- title 只辅助。
- 不承诺 Chrome 标签级恢复。

### 风险 2：显示器 ID 不稳定

处理：

- DisplayIdentity 使用多字段组合。
- MacBook 内屏特殊识别。
- Sidecar 允许通过 name/resolution/scale 辅助匹配。
- 提供 Profile 页面让用户查看当前识别到的显示器。

### 风险 3：系统切屏瞬间污染学习状态

处理：

- DisplayChanging / DisplayStabilizing / Restoring 期间禁止写入。
- 恢复完成并稳定后才重新学习。
- 这是硬性状态机约束。

### 风险 4：Accessibility 权限导致失败

处理：

- 启动时检查权限。
- 无权限不静默失败。
- App 内显示权限状态和引导。
- Recent Restore Report 中记录权限失败。

### 风险 5：某些 App 拒绝移动或调整大小

处理：

- 跳过失败窗口。
- 记录失败原因。
- 不影响其他窗口恢复。
- 不针对单个 App 写特殊 hack，除非后续确有高频需求。

## 18. 第一版验收标准

第一版完成后，应满足：

- 用户可以手动创建 Profile。
- App 能识别 MacBook + 外接屏 + Sidecar 的显示器组合。
- 已创建 Profile 下，窗口位置和尺寸会自动学习。
- 显示器切换后，精确 Profile 自动恢复。
- 未知组合不创建 Profile，但能根据已有显示器做部分恢复。
- 关闭窗口不会被重新打开。
- 新窗口可以在 Learning 状态下被纳入。
- 切换后 60 秒内迟到窗口可自动恢复一次。
- 菜单栏可查看状态、暂停、手动恢复、查看日志。
- 不处理全屏、跨 Space、启动 App、Chrome 标签页。
- 项目有基础单元测试和可重复运行的 build/run 脚本。

## 19. Codex 执行建议

请按 Phase 顺序实现，不要一次性堆完所有功能。

每个 Phase 单独提交：

1. 先实现可运行骨架。
2. 再实现显示器识别。
3. 再实现窗口枚举。
4. 再实现自动学习。
5. 再实现恢复。
6. 再实现部分恢复。
7. 再补 UI 和测试。

每个阶段必须包含：

- 编译通过。
- 基本单元测试通过。
- README 更新当前功能边界。
- Recent Restore Report 或日志能解释失败原因。

禁止在 MVP 阶段扩展以下功能：

- 布局编辑器
- 云同步
- App 自动启动
- Chrome 标签识别
- AI 识别窗口
- 跨 Space 管理
- 真全屏恢复
- 复杂规则 DSL

当前目标不是做一个全能窗口管理器，而是做一个稳定、无感、可解释的窗口状态连续性服务。