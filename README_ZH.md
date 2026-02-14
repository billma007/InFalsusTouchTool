# InfalsusTouch (中文版)

InfalsusTouch 是一个跨平台远程控制应用，它将你的 Android 或 iOS 设备变成一个强大的触摸板和键盘。该应用使用高性能的 UDP 协议进行低延迟通信，非常适合游戏或生产力场景。

## 项目结构

本仓库包含三个主要组件：

- **`android/`**: Android 客户端应用程序 (Kotlin)。
- **`ios/`**: iOS 客户端应用程序 (SwiftUI)。
- **`pc/`**: 服务端接收程序 (C++)。

## 功能特性

- **多点触控支持**: 使用手机/平板屏幕作为触控板。
- **低延迟**: 通过局域网 (Wi-Fi) 进行 UDP 直连。
- **跨平台**: 支持 Android 和 iOS 设备。
- **自定义协议**: 简单的基于文本的协议，用于移动和按键操作。
- **决定与相对输入**: 支持绝对坐标定位（屏幕到屏幕的映射）和相对鼠标移动。

## 开始使用

### 1. PC 接收端 (Windows)

接收端运行在 Windows 电脑上，将接收到的网络数据包转换为鼠标/键盘输入。

**先决条件:**
- MinGW (g++) 编译器。

**编译:**
在 `pc/` 目录下运行以下命令进行静态编译（确保在不同 Windows 机器上的兼容性）：

```bash
g++ receiver.cpp -o receiver.exe -lws2_32 -static
```

**使用:**
1. 运行 `receiver.exe`。
2. 如果防火墙提示拦截，请允许通过。
3. 接收端将监听 UDP 端口 **8888**。

### 2. Android 客户端

**先决条件:**
- Android Studio 或 Gradle。
- JDK 17 (现代 Android 构建已包含)。

**构建:**
在 Android Studio 中打开 `android/` 目录并构建项目。`build.gradle` 中包含已配置的发布版签名 `release.jks`。

**使用:**
1. 将生成的 APK 安装到 Android 设备。
2. 输入 PC 的局域网 IP 地址并连接。

### 3. iOS 客户端

**先决条件:**
- 安装了 Xcode 的 macOS 电脑。

**构建:**
1. 在 Xcode 中打开 `ios/InfalsusTouch.xcodeproj`。
2. 选择目标设备（模拟器或真机 iPad/iPhone）。
3. 使用 `Cmd + R` 构建并运行。

**使用:**
1. 在 iPhone 或 iPad 上启动应用。
2. 在设置字段中输入目标 PC 的 IP 地址。

## 协议详情

应用程序使用简单的 UDP 字符串消息进行通信：

- **相对鼠标移动**: `X` (float) -> 例如: `10.5` (X轴移动10像素)。
- **绝对鼠标移动**: `A` + `0.0-1.0` -> 例如: `A0.5` (X轴移动至屏幕宽度50%处)。
- **键盘事件**: `K` + `D/U` (按下/抬起) + `Char` -> 例如: `KDw` (按下 'w' 键)。

## 许可证

[MIT License]
