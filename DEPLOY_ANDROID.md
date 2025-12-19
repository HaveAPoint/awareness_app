# Awareness App - Android 部署指南

## 快速构建 APK

### 一键构建

```bash
# 在项目根目录执行
./build_apk.sh
```

### 手动构建

```bash
cd frontend
flutter pub get
flutter build apk --release
```

构建产物：`frontend/build/app/outputs/flutter-apk/app-release.apk`

---

## 安装到手机

### 方法 1: USB 连接
```bash
# 手机开启开发者选项和 USB 调试
flutter install

# 或使用 adb
adb install frontend/build/app/outputs/flutter-apk/app-release.apk
```

### 方法 2: 直接传输
1. 将 `app-release.apk` 传到手机（微信/QQ/蓝牙/云盘）
2. 在手机上打开文件管理器
3. 点击 APK 文件
4. 允许「安装未知来源应用」
5. 点击「安装」

---

## 构建不同版本

### Split APK（多架构，体积更小）
```bash
flutter build apk --split-per-abi
```
产物：
- `app-armeabi-v7a-release.apk` (32位 ARM)
- `app-arm64-v8a-release.apk` (64位 ARM，推荐)
- `app-x86_64-release.apk` (模拟器)

### App Bundle（Google Play 推荐格式）
```bash
flutter build appbundle --release
```
产物：`build/app/outputs/bundle/release/app-release.aab`

---

## 签名配置（发布到应用商店）

### 1. 生成密钥
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

### 2. 配置签名
创建 `frontend/android/key.properties`：
```properties
storePassword=你的密钥库密码
keyPassword=你的密钥密码
keyAlias=upload
storeFile=/home/你的用户名/upload-keystore.jks
```

### 3. 修改 `android/app/build.gradle.kts`
在 `android {}` 块前添加：
```kotlin
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

在 `buildTypes` 中修改 `release`：
```kotlin
signingConfig = signingConfigs.getByName("release")
```

在 `android {}` 块内添加：
```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = file(keystoreProperties["storeFile"] as String)
        storePassword = keystoreProperties["storePassword"] as String
    }
}
```

### 4. 重新构建
```bash
flutter build apk --release
```

---

## 应用信息配置

### 修改应用名称
`frontend/android/app/src/main/AndroidManifest.xml`：
```xml
<application
    android:label="觉知时间"
    ...>
```

### 修改包名
`frontend/android/app/build.gradle.kts`：
```kotlin
namespace = "com.yourcompany.awareness_app"
```

### 修改应用图标
替换以下目录的图标文件：
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`

或使用工具生成：
```bash
flutter pub run flutter_launcher_icons
```

---

## 数据说明

- 数据存储在手机本地 SQLite 数据库
- 路径：`/data/data/com.yourcompany.awareness_app/databases/`
- 卸载应用会清除数据
- 建议实现数据导出/导入功能

---

## 故障排查

### 构建失败
```bash
# 清理后重试
cd frontend
flutter clean
flutter pub get
flutter build apk --release
```

### 安装失败
```bash
# 卸载旧版本
adb uninstall com.yourcompany.awareness_app

# 重新安装
adb install -r app-release.apk
```

### 运行时崩溃
```bash
# 查看日志
adb logcat | grep flutter
```

---

## 性能优化

### 启用混淆（减小体积）
`android/app/build.gradle.kts`：
```kotlin
buildTypes {
    release {
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```

### 启用 R8（优化编译）
默认已启用（Gradle 3.4+）

---

## 分发方式

### 1. 直接分发 APK
- 适合内测、小范围使用
- 需要用户手动允许「安装未知来源」

### 2. 发布到应用商店
- **Google Play**: 需要开发者账号（$25一次性）
- **华为应用市场**: 需要企业认证
- **小米应用商店**: 个人开发者免费
- **酷安**: 需要实名认证

### 3. 托管到 GitHub Releases
```bash
# 上传 APK 到 GitHub Release
# 用户可直接下载安装
```

---

## 更新策略

### 版本号管理
`frontend/pubspec.yaml`：
```yaml
version: 1.0.0+1
#        ^ 版本名  ^ 版本号（递增）
```

### 自动检查更新
建议实现：
1. 启动时检查远端版本号
2. 提示用户下载新版本
3. 跳转到下载页面

---

## 技术栈
- **平台**: Android 5.0+ (API 21+)
- **数据库**: SQLite (Drift)
- **状态管理**: Provider / Riverpod
- **构建工具**: Gradle 8.x
- **最小 SDK**: 21
- **目标 SDK**: 34
