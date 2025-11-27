# Android开发演示项目

这是一个使用Flutter开发的Android应用演示项目。

## 功能特性

- 🎨 Material Design 3 界面设计
- 📱 响应式布局，支持多种屏幕尺寸
- 🔢 交互式计数器功能
- 📋 平台选择下拉菜单
- 💬 Snackbar消息提示
- 🎯 网格布局按钮组

## 主要组件

### 1. 平台选择器
- 支持选择Android、iOS、Web、Windows平台
- 实时显示当前选择的平台

### 2. 计数器功能
- 增加计数
- 重置计数
- 翻倍计数
- 显示当前计数值

### 3. 交互组件
- 卡片布局设计
- 浮动操作按钮
- 网格按钮布局
- 消息提示功能

## 运行方式

### Web版本（推荐）
```bash
flutter run -d chrome
```

### Android版本
```bash
# 连接Android设备后运行
flutter run

# 或构建APK
flutter build apk --debug
```

## 开发环境要求

- Flutter SDK 3.24.5+
- Android SDK 34.0.0+
- Java 17+ (推荐使用Android Studio内置JDK)
- Chrome浏览器（用于Web开发）

## 项目结构

```
android_demo/
├── lib/
│   └── main.dart          # 主要应用代码
├── android/               # Android平台配置
├── web/                   # Web平台配置
└── README.md             # 项目说明
```

## 学习要点

1. **StatefulWidget使用** - 展示状态管理
2. **Material Design组件** - Card、DropdownButton、SnackBar等
3. **布局系统** - Column、GridView、Padding等
4. **事件处理** - 按钮点击、状态更新
5. **国际化支持** - 中文界面

## 扩展建议

- 添加页面导航功能
- 集成本地数据存储
- 添加网络请求功能
- 实现主题切换
- 添加动画效果

## 开发工具

推荐使用以下开发工具：
- **Android Studio** - 完整的IDE支持
- **VS Code** - 轻量级编辑器 + Flutter插件
- **Flutter DevTools** - 性能分析和调试

---

🚀 开始你的Flutter Android开发之旅吧！
