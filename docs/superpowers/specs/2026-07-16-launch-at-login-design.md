# SnapSail 开机自动启动设计

- 日期：2026-07-16
- 状态：用户已要求在软件设置中支持开机自动启动
- 系统接口：macOS ServiceManagement `SMAppService.mainApp`

## 目标

在“设置 → 通用”中增加“登录时启动 SnapSail”开关。开关直接控制 macOS 登录项，并在设置页打开时读取系统真实状态，不使用仅存在于 `UserDefaults` 的伪状态。

## 方案

- macOS 13 及以上使用 `SMAppService.mainApp.register()` 与 `unregister()`。
- `enabled` 显示为开启，`notRegistered` 显示为关闭。
- `requiresApproval` 保持开启显示，并自动打开“系统设置 → 通用 → 登录项”供用户批准。
- macOS 12 显示禁用状态和不可用提示，保持当前最低部署版本不变。
- 注册失败时恢复系统真实状态，并显示本地化错误提示。

## 结构

- `LaunchAtLoginController` 隔离 ServiceManagement，并通过协议允许测试替身验证注册、注销和批准流程。
- `SettingsWindowController` 只负责展示状态和转发用户操作，不把登录项状态写入 `AppPreferences`。
- `AppLocalization` 增加中英文标题、批准提示、不可用提示和失败提示。

## 验收标准

1. 通用设置页存在“登录时启动 SnapSail”开关。
2. 开关每次显示设置窗口时都同步系统登录项状态。
3. 开启、关闭、需要批准和不可用四种状态均有确定行为。
4. 切换语言后新控件与提示同步切换中英文。
5. 不默认替用户开启登录项；只有点击开关时才修改系统状态。
6. 完整测试、生产构建和签名验证通过。
