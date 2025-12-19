# Awareness App

一款基于"觉知哲学"的时间管理与自我觉察应用，帮助你保持专注、捕捉杂念、诚实复盘。

## 核心理念
- **真实重于完美**: 如实记录状态，不强迫高效
- **保护心流**: 最小化干扰的交互设计
- **诚实复盘**: 无论表现好坏，记录本身就是胜利

## 功能特性
- ⏱️ **番茄钟**: 工作/休息循环，支持自定义时长
- 💡 **快速捕捉**: 专注时异步记录杂念，不中断心流
- 📊 **诚实镜像**: 查看时间轨迹，批量评分复盘
- 🗂️ **沉淀池**: 处理捕捉的杂念与灵感

## 技术栈
- **前端**: Flutter 3.24+ (Dart)
- **数据库**: Drift (SQLite)
- **架构**: MVVM + Repository 模式

## 快速开始

### 开发环境
```bash
# 安装依赖
cd frontend
flutter pub get

# 运行（默认 Chrome）
flutter run -d chrome

# 运行 Android
flutter run -d android
```

### 构建 Android APK
```bash
# 一键构建
./build_apk.sh

# 或手动构建
cd frontend
flutter build apk --release
```

产物：`frontend/build/app/outputs/flutter-apk/app-release.apk`

详见 [Android 部署指南](DEPLOY_ANDROID.md)

## 项目结构
```
frontend/
├── lib/
│   ├── main.dart              # 应用入口
│   ├── data/                  # 数据层
│   │   ├── database/          # Drift 数据库
│   │   └── repositories/      # 数据仓库（待实现）
│   ├── logic/                 # 业务逻辑层
│   │   └── timer/             # 番茄钟控制器
│   └── ui/                    # 表现层
│       ├── screens/           # 页面
│       │   ├── dashboard/     # 导航中心
│       │   ├── focus/         # 专注页（番茄钟）
│       │   └── journal/       # 每日容器（待重构）
│       └── common/            # 通用组件
├── android/                   # Android 配置
├── pubspec.yaml               # 依赖配置
└── analysis_options.yaml      # 代码规范
```

## 架构文档
- [ARCHITECTURE.md](frontend/ARCHITECTURE.md) - 数据流与架构设计
- [MVP_SPEC.md](frontend/MVP_SPEC.md) - MVP 需求规范
- [REFACTOR_SUMMARY.md](REFACTOR_SUMMARY.md) - 重构总结

## 开发计划
- [x] 数据库架构设计
- [x] 番茄钟核心逻辑
- [x] 快速捕捉功能
- [ ] 分支二重构（发射台+镜像+沉淀池）
- [ ] 复盘评分系统
- [ ] 数据导出/导入
- [ ] OKR 目标管理

## 贡献指南
1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交改动 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 许可证
MIT License

## 联系方式
- Issues: [GitHub Issues](https://github.com/你的用户名/awareness_app/issues)
