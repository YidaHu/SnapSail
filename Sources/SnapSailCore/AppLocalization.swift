public enum AppLanguage: String, CaseIterable {
    case english
    case simplifiedChinese

    public var displayName: String {
        switch self {
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        }
    }
}

public enum AppTextKey: String, CaseIterable {
    case general, capture, scrolling, export, shortcuts, preferencesTitle, language
    case appBehavior, launchAtLogin, launchAtLoginApproval, launchAtLoginUnavailable, launchAtLoginFailed
    case playSound, showNotification, keepHistory, privacyHint
    case screenshotBehavior, includeWindowShadow, copyAfterCapture, saveAfterCapture, shadowHint
    case scrollingCapture, scrollSlow, scrollSlowDetail, stopStable, stopStableDetail, maxPixels, maxPixelsDetail
    case fileOutput, format, jpegQuality, filenamePrefix, saveFolder, choose
    case globalShortcuts, captureArea, captureWindow, shortcutHint
    case captureHistory, settings, about, quit, tagline
    case pinOnScreen, typeAndReturn, windowInstruction, regionInstruction
    case rectangle, ellipse, line, arrow, pen, pixelate, text, number, highlight
    case changeColor, undo, redo, cancel, saveAndCopy, copyAndFinish
    case recorderTooltip, pressShortcut, pressKey, addModifier
    case shortcutUnavailable, shortcutDuplicate, shortcutSystemConflict, ok
    case editorTitle, color, save, copy, pin, closePinnedImage
    case historyTitle, clearHistoryQuestion, clear, recentCaptures, open, clearHistory
    case permissionTitle, permissionBody, openSystemSettings, captureFailed, captureFailedBody
    case addText, annotationPlaceholder, add
    case scrollUnavailable, scrollReady, scrollStitching, scrollPaused, scrollWaiting
    case scrollMaximum, scrollDisplayChanged, startingCapture, live, finish
}

public enum AppLocalization {
    public static func text(_ key: AppTextKey, language: AppLanguage) -> String {
        catalogs[language]?[key] ?? catalogs[.english]?[key] ?? key.rawValue
    }

    public static func hasTranslation(_ key: AppTextKey, language: AppLanguage) -> Bool {
        guard let value = catalogs[language]?[key] else { return false }
        return !value.isEmpty
    }

    private static let catalogs: [AppLanguage: [AppTextKey: String]] = [
        .english: [
            .general: "General", .capture: "Capture", .scrolling: "Scrolling", .export: "Export",
            .shortcuts: "Shortcuts", .preferencesTitle: "SnapSail Preferences", .language: "Language:",
            .appBehavior: "App behavior", .launchAtLogin: "Launch SnapSail at login",
            .launchAtLoginApproval: "Approval is required in System Settings → General → Login Items.",
            .launchAtLoginUnavailable: "Launch at login requires macOS 13 or later.",
            .launchAtLoginFailed: "Couldn’t Change Login Item",
            .playSound: "Play a subtle sound after capture",
            .showNotification: "Show a notification when capture completes",
            .keepHistory: "Keep capture history on this Mac",
            .privacyHint: "Your screenshots and history never leave this Mac.",
            .screenshotBehavior: "Screenshot behavior", .includeWindowShadow: "Include window shadow",
            .copyAfterCapture: "Copy to clipboard after capture", .saveAfterCapture: "Save to folder after capture",
            .shadowHint: "Hold Option while selecting to temporarily invert shadow behavior.",
            .scrollingCapture: "Scrolling Capture", .scrollSlow: "Scroll slowly and steadily",
            .scrollSlowDetail: "SnapSail matches overlapping rows while you scroll.",
            .stopStable: "Stop on stable content",
            .stopStableDetail: "Avoid animated banners and fixed overlays for cleaner stitching.",
            .maxPixels: "Up to 60,000 pixels",
            .maxPixelsDetail: "The preview updates efficiently while the full image stays sharp.",
            .fileOutput: "File output", .format: "Format:", .jpegQuality: "JPEG quality:",
            .filenamePrefix: "Filename prefix:", .saveFolder: "Save folder:", .choose: "Choose…",
            .globalShortcuts: "Global shortcuts", .captureArea: "Capture Area", .captureWindow: "Capture Window",
            .shortcutHint: "Click a shortcut to record · Esc cancels · Delete restores the default",
            .captureHistory: "Capture History", .settings: "Settings…", .about: "About SnapSail",
            .quit: "Quit SnapSail", .tagline: "Capture More. Scroll Less.",
            .pinOnScreen: "Pin on Screen", .typeAndReturn: "Type and press Return",
            .windowInstruction: "Click to select · Shift-click multiple · Space switches mode · Esc cancels",
            .regionInstruction: "Drag to select · Move or resize · Return captures · Space switches mode",
            .rectangle: "Rectangle", .ellipse: "Ellipse", .line: "Line", .arrow: "Arrow", .pen: "Pen",
            .pixelate: "Pixelate", .text: "Text", .number: "Number", .highlight: "Highlight",
            .changeColor: "Change Color", .undo: "Undo", .redo: "Redo", .cancel: "Cancel",
            .saveAndCopy: "Download", .copyAndFinish: "Copy and Finish",
            .recorderTooltip: "Click, then press a shortcut. Delete restores the default.",
            .pressShortcut: "Press shortcut…", .pressKey: "Press a key", .addModifier: "Add a modifier",
            .shortcutUnavailable: "Shortcut Unavailable",
            .shortcutDuplicate: "That shortcut is already used by SnapSail.",
            .shortcutSystemConflict: "macOS or another app is already using that shortcut.", .ok: "OK",
            .editorTitle: "SnapSail Editor", .color: "Color", .save: "Save…", .copy: "Copy", .pin: "Pin",
            .closePinnedImage: "Close Pinned Image", .historyTitle: "Capture History",
            .clearHistoryQuestion: "Clear Capture History?", .clear: "Clear", .recentCaptures: "Recent Captures",
            .open: "Open", .clearHistory: "Clear History",
            .permissionTitle: "Screen Recording Permission Required",
            .permissionBody: "SnapSail needs Screen Recording access to capture your screen. Enable it in System Settings → Privacy & Security → Screen Recording, then relaunch SnapSail.",
            .openSystemSettings: "Open System Settings", .captureFailed: "Capture Failed",
            .captureFailedBody: "SnapSail could not capture this content. Check Screen Recording permission and try again.",
            .addText: "Add Text", .annotationPlaceholder: "Enter annotation text", .add: "Add",
            .scrollUnavailable: "Capture unavailable. Check Screen Recording permission.",
            .scrollReady: "Ready — scroll down slowly · %d px", .scrollStitching: "Stitching smoothly · %d px",
            .scrollPaused: "Paused — scroll more slowly · %d px saved",
            .scrollWaiting: "Waiting for vertical movement · %d px",
            .scrollMaximum: "Maximum height reached · %d px",
            .scrollDisplayChanged: "Display changed · %d px saved",
            .startingCapture: "Starting capture…", .live: "LIVE", .finish: "Finish"
        ],
        .simplifiedChinese: [
            .general: "通用", .capture: "截图", .scrolling: "滚动截图", .export: "导出",
            .shortcuts: "快捷键", .preferencesTitle: "SnapSail 偏好设置", .language: "语言：",
            .appBehavior: "应用行为", .launchAtLogin: "登录时启动 SnapSail",
            .launchAtLoginApproval: "需要在“系统设置 → 通用 → 登录项”中批准。",
            .launchAtLoginUnavailable: "开机自动启动需要 macOS 13 或更高版本。",
            .launchAtLoginFailed: "无法更改登录项",
            .playSound: "截图完成后播放提示音",
            .showNotification: "截图完成后显示通知", .keepHistory: "在本机保留截图历史",
            .privacyHint: "你的截图和历史记录始终保存在本机。",
            .screenshotBehavior: "截图行为", .includeWindowShadow: "包含窗口阴影",
            .copyAfterCapture: "截图后复制到剪贴板", .saveAfterCapture: "截图后保存到文件夹",
            .shadowHint: "选择窗口时按住 Option 可临时切换阴影效果。",
            .scrollingCapture: "滚动截图", .scrollSlow: "缓慢、匀速滚动",
            .scrollSlowDetail: "滚动时 SnapSail 会匹配上下帧的重叠区域。",
            .stopStable: "在稳定内容处停止", .stopStableDetail: "避开动画横幅和固定悬浮元素，拼接效果会更干净。",
            .maxPixels: "最高 60,000 像素", .maxPixelsDetail: "预览会高效更新，完整长图仍保持清晰。",
            .fileOutput: "文件输出", .format: "格式：", .jpegQuality: "JPEG 质量：",
            .filenamePrefix: "文件名前缀：", .saveFolder: "保存文件夹：", .choose: "选择…",
            .globalShortcuts: "全局快捷键", .captureArea: "区域截图", .captureWindow: "窗口截图",
            .shortcutHint: "点击快捷键后录制 · Esc 取消 · Delete 恢复默认",
            .captureHistory: "截图历史", .settings: "设置…", .about: "关于 SnapSail",
            .quit: "退出 SnapSail", .tagline: "截得更多，滚得更少。",
            .pinOnScreen: "钉在屏幕上", .typeAndReturn: "输入文字后按 Return",
            .windowInstruction: "点击选择窗口 · Shift 点击可多选 · 空格切换模式 · Esc 取消",
            .regionInstruction: "拖动选择区域 · 可移动或缩放 · Return 完成 · 空格切换模式",
            .rectangle: "矩形", .ellipse: "椭圆", .line: "直线", .arrow: "箭头", .pen: "画笔",
            .pixelate: "马赛克", .text: "文字", .number: "序号", .highlight: "高亮",
            .changeColor: "切换颜色", .undo: "撤销", .redo: "重做", .cancel: "取消",
            .saveAndCopy: "下载", .copyAndFinish: "复制并完成",
            .recorderTooltip: "点击后按下新快捷键，Delete 可恢复默认。",
            .pressShortcut: "请按快捷键…", .pressKey: "请按一个按键", .addModifier: "请添加修饰键",
            .shortcutUnavailable: "快捷键不可用", .shortcutDuplicate: "该快捷键已被 SnapSail 使用。",
            .shortcutSystemConflict: "该快捷键已被 macOS 或其他应用占用。", .ok: "好",
            .editorTitle: "SnapSail 编辑器", .color: "颜色", .save: "保存…", .copy: "复制", .pin: "钉住",
            .closePinnedImage: "关闭钉图", .historyTitle: "截图历史", .clearHistoryQuestion: "清空截图历史？",
            .clear: "清空", .recentCaptures: "最近截图", .open: "打开", .clearHistory: "清空历史",
            .permissionTitle: "需要屏幕录制权限",
            .permissionBody: "SnapSail 需要屏幕录制权限才能截图。请前往“系统设置 → 隐私与安全性 → 屏幕录制”开启权限，然后重新启动 SnapSail。",
            .openSystemSettings: "打开系统设置", .captureFailed: "截图失败",
            .captureFailedBody: "SnapSail 无法截取此内容，请检查屏幕录制权限后重试。",
            .addText: "添加文字", .annotationPlaceholder: "输入标注文字", .add: "添加",
            .scrollUnavailable: "无法截图，请检查屏幕录制权限。",
            .scrollReady: "准备完成 — 请缓慢向下滚动 · %d px", .scrollStitching: "正在平滑拼接 · %d px",
            .scrollPaused: "已暂停 — 请放慢滚动速度 · 已保存 %d px",
            .scrollWaiting: "等待纵向滚动 · %d px", .scrollMaximum: "已达到最大高度 · %d px",
            .scrollDisplayChanged: "显示器发生变化 · 已保存 %d px",
            .startingCapture: "正在开始截图…", .live: "实时", .finish: "完成"
        ]
    ]
}
