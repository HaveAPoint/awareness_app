没问题，这份 Windows + WSL2 Flutter 真机调试速查表 是根据我们刚才排查成功的流程整理的。

你可以直接复制保存为 debug_guide.md，下次换新手机或重新连接时照着做就行。

Markdown

# 🚀 Windows (WSL2) + Flutter 真机调试速查指南

## 🛠️ 1. 首次环境准备 (仅需配置一次)

### Windows 端
以**管理员身份**打开 PowerShell，安装 USB 穿透工具：
```powershell
winget install --interactive --exact dorssel.usbipd-win
# 安装完成后建议重启电脑
WSL (Ubuntu) 端
安装 Android Platform Tools (ADB)：

Bash

sudo apt update
sudo apt install adb -y
🔗 2. 每次连接步骤 (日常开发流程)
第 1 步：物理连接 & Windows 挂载
手机通过 USB 连接电脑。

Windows PowerShell (管理员) 执行：

PowerShell

# 查看设备列表，找到手机的 BUSID (如 1-8)
usbipd list

# 首次连接新设备需绑定 (如果状态不是 Shared)
usbipd bind --busid <BUSID>

# 挂载设备到 WSL
usbipd attach --wsl --busid <BUSID>
注意：此时手机上若弹出“允许 USB 调试”，勾选“始终允许”并确认。

第 2 步：WSL 识别 & 提权
回到 WSL 终端：

检查硬件是否挂载成功：

Bash

lsusb
# 应显示 Google/Xiaomi/Samsung 等设备
⚡️ 关键步骤 (解决识别不到/无权限问题)： 如果 flutter devices 找不到手机，或者是 no permissions，执行以下“通脉”命令：

Bash

sudo adb kill-server
sudo adb start-server
sudo adb devices
(此时留意手机屏幕，再次确认授权)

第 3 步：启动项目
Bash

# -d 指定设备 ID (通过 flutter devices 获取，避免误跑 Web 端)
flutter run -d <设备ID>
📱 3. 小米 / Redmi 手机特别设置
如果连接不稳定或无法安装 APP，请检查手机设置：

开发者选项 -> 开启 USB 调试。

开发者选项 -> 开启 USB 调试（安全设置） (如果不开启，可能报错 Installation failed)。

注：开启此项通常需要插入 SIM 卡并登录小米账号。

开发者选项 -> 关闭 启用 MIUI 优化 (可选，仅在极度奇怪的报错时尝试)。

❓ 4. 常见问题排查
Q: Windows 提示 Device in error state?

A: 可能是 Windows 的 ADB 抢占了设备。

拔掉手机。

Windows 终端执行 adb kill-server。

插上手机，立刻执行 usbipd attach。

Q: WSL 里 lsusb 有设备，但 flutter devices 列表为空?

A: 权限问题。必杀技： sudo adb kill-server && sudo adb start-server

Q: 报错 sqlite3 ... Only JS interop members...?

A: 你的 Flutter 跑到了 Web 模式。请务必用 flutter run -d <手机ID> 强制指定跑在 Android 上。