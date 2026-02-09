# 正念应用设置指南

本项目包含了一个 iOS 正念应用的源代码。

## 前置条件
- Xcode 15+ (支持 iOS 17 SDK)
- Apple 开发者账号 (用于启用 HealthKit 和 小组件 功能)

## 设置步骤

1. **创建新建 Xcode 项目**:
   - 打开 Xcode 并创建一个新项目。
   - 选择 **App** 模板。
   - 项目名称 (Product Name): `MindfulnessApp`。
   - 界面 (Interface): **SwiftUI**。
   - 语言 (Language): **Swift**。

2. **添加文件**:
   - 将 `MindfulnessApp` 文件夹（包含 Models, Managers, Views 等子目录）拖入 Xcode 的项目导航栏中。
   - 确保勾选 "Copy items if needed" 以及选择 "Create groups"。
   - 删除 Xcode 默认生成的 `ContentView.swift` 和 `MindfulnessAppApp.swift`，使用本项目提供的同名文件。

3. **配置能力 (Capabilities)**:
   - 进入项目设置 -> Target `MindfulnessApp` -> **Signing & Capabilities**。
   - 点击 `+ Capability` 并添加 **HealthKit**。
   - 除非你打算扩展后台功能，否则通常不需要 `Background Modes`，但 **HealthKit** 是必需的。
   - 在 `Info.plist` 中添加以下键值对（用于权限申请说明）：
     - `NSHealthShareUsageDescription`: "我们需要访问您的正念数据以进行统计和展示。" (读取)
     - `NSHealthUpdateUsageDescription`: "我们需要将您的正念练习时长保存到健康应用中。" (写入)

4. **添加小组件扩展 (Widget Extension)**:
   - 在 Xcode 中，选择 File -> New -> Target... -> **Widget Extension**。
   - 项目名称: `MindfulnessWidget`。
   - 如果你想要一个简单的小组件，取消勾选 "Include Live Activity" 和 "Include Configuration App Intent"（本代码使用的是 `StaticConfiguration`）。
   - 将自动生成的 `MindfulnessWidget.swift` 内容替换为本项目 `MindfulnessApp/Widget/MindfulnessWidget.swift` 中的代码。
   - **重要提示**: 确保小组件 target 也添加了 **HealthKit** 能力。虽然数据通常通过 App Groups 或直接访问 HealthKit 共享，但在锁屏状态下访问可能有一定限制。

5. **编译与运行**:
   - 选择 `MindfulnessApp` 方案 (Scheme) 并在模拟器或真机上运行。
   - 当系统提示时，授予健康权限。
   - 尝试开始一次正念练习并结束，检查数据是否保存。
   - 在主屏幕添加小组件，查看今日正念时长的实时更新。

## 项目结构
- `Models/`: 数据模型 (`MindfulnessSession`)。
- `Managers/`: 逻辑控制器 (`HealthKitManager`, `MindfulnessViewModel`)。
- `Views/`: SwiftUI 视图界面。
- `Extensions/`: 辅助扩展。
- `Widget/`: 小组件实现代码。
