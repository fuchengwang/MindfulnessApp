# 正念 (Mindfulness) App

一款简洁优雅的 iOS 正念冥想记录应用，帮助你追踪和管理每日的正念练习时间。

## ✨ 功能特性

### 📊 数据统计
- **今日统计**：直观显示当天正念总时长
- **每周趋势**：可视化七天正念数据变化
- **历史日历**：以日历热力图形式展示全年正念记录

### ⏱️ 记录方式
- **实时计时**：开始正念后自动计时，结束后保存
- **手动添加**：
  - 刚刚模式：快速记录刚完成的正念
  - 指定时间：选择特定日期时间添加历史记录

### 🏥 健康数据同步
- 自动同步数据到 Apple Health
- 与系统健康应用无缝集成

### 📱 小组件支持
- 主屏幕小组件快速查看今日进度
- 锁屏小组件一览当前状态

## 🛠️ 技术栈

- **SwiftUI** - 现代声明式 UI 框架
- **HealthKit** - Apple 健康数据集成
- **WidgetKit** - iOS 小组件开发
- **Combine** - 响应式数据流

## 📁 项目结构

```
MindfulnessApp/
├── Extensions/
│   ├── Views/           # 视图组件
│   │   ├── SummaryView.swift      # 主页统计视图
│   │   ├── SessionView.swift      # 计时会话视图
│   │   ├── ManualEntryView.swift  # 手动输入入口
│   │   ├── JustNowView.swift      # "刚刚"快捷输入
│   │   ├── SpecificTimeView.swift # 指定时间输入
│   │   ├── HistoryView.swift      # 历史记录视图
│   │   └── HistoryCalendarView.swift # 日历热力图
│   └── Color+Extensions.swift     # 颜色扩展
├── Managers/
│   ├── HealthKitManager.swift     # HealthKit 数据管理
│   └── MindfulnessViewModel.swift # 主视图模型
├── Models/
│   └── MindfulnessSession.swift   # 正念会话模型
└── Assets.xcassets/               # 资源文件
```

## 🚀 开始使用

1. 使用 Xcode 打开 `MindfulnessApp.xcodeproj`
2. 在真机上运行（HealthKit 需要真机测试）
3. 授权 HealthKit 正念数据读写权限
4. 开始记录你的正念练习！

## 📋 系统要求

- iOS 17.0+
- Xcode 15.0+
- 需要 Apple Developer 账号（用于 HealthKit 权限）

## 📄 许可证

MIT License
