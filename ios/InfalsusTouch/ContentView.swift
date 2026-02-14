import SwiftUI
import UIKit

// 定义操作模式
enum ControlMode: Int, CaseIterable, Identifiable {
    case relative = 0
    case absolute = 1
    case fullMapping = 2 // 新增全映射模式
    
    var id: Int { self.rawValue }
    
    var description: String {
        switch self {
        case .relative: return "相对触控"
        case .absolute: return "绝对映射"
        case .fullMapping: return "全映射模式"
        }
    }
}

struct ContentView: View {
    @StateObject var networkManager = NetworkManager()
    @State private var inputIP: String = "192.168.1.100"
    @State private var selectedMode: ControlMode = .relative // 改用枚举
    
    var body: some View {
        ZStack {
            // 背景色
            Color.black.edgesIgnoringSafeArea(.all)
            
            if networkManager.isConnected {
                // 连接成功后的界面
                if selectedMode == .fullMapping {
                     // 全映射游戏模式
                     FullMappingGameView(networkManager: networkManager)
                         .edgesIgnoringSafeArea(.all)
                } else {
                     // 之前的相对/绝对触控板界面
                    VStack {
                        ZStack {
                            // 传入模式状态
                            MultiTouchPad(networkManager: networkManager, mode: $selectedMode)
                                .edgesIgnoringSafeArea(.all)
                            
                            // 界面提示文字
                            VStack {
                                Text("触控区已激活")
                                    .foregroundColor(.gray)
                                    .padding(.top, 50)
                                
                                Text("当前模式: \(selectedMode.description)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.top, 10)

                                Text(selectedMode == .absolute ? "点击位置直接映射屏幕水平坐标" : "使用双指水平滑动控制")
                                    .font(.caption)
                                    .foregroundColor(.gray.opacity(0.5))
                                
                                Spacer()
                                
                                // 断开连接按钮
                                Button(action: {
                                    networkManager.disconnect()
                                }) {
                                    Text("断开连接")
                                        .padding()
                                        .background(Color.red.opacity(0.8))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                .padding(.bottom, 20)
                            }
                        }
                    }
                }
            } else {
                // 连接设置界面
                VStack(spacing: 25) {
                    Spacer()
                    
                    Text("In Falsus 助手")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("输入 PC IP 地址")
                            .foregroundColor(.gray)
                            .font(.headline)
                        
                        TextField("192.168.x.x", text: $inputIP)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                            .textContentType(.none)
                            .frame(maxWidth: 300)
                            .multilineTextAlignment(.center)
                    }
                    
                    // 模式选择
                    HStack {
                        Text("操作模式:")
                            .foregroundColor(.gray)
                            .font(.headline)
                        
                        Picker(selection: $selectedMode, label: Text("模式")) {
                            Text("相对模式").tag(ControlMode.relative)
                            Text("绝对模式").tag(ControlMode.absolute)
                            Text("全映射").tag(ControlMode.fullMapping)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 300)
                    }
                    .padding(.vertical, 5)
                    
                    Button(action: {
                        networkManager.connect(to: inputIP)
                    }) {
                        Text("连接")
                            .font(.headline)
                            .frame(width: 200, height: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    if !networkManager.errorMsg.isEmpty {
                        Text(networkManager.errorMsg)
                            .foregroundColor(.red)
                            .font(.callout)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("使用说明:")
                            .foregroundColor(.white)
                            .font(.headline)
                            .padding(.bottom, 5)
                        Text("1. 请在电脑上运行接收端程序 (receiver.exe)。")
                            .foregroundColor(.gray)
                            .font(.caption)
                        Text("2. 在上方输入电脑的局域网 IP 地址。")
                            .foregroundColor(.gray)
                            .font(.caption)
                        Text("3. 连接后使用双指滑动或点击控制光标。")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .frame(maxWidth: 320)

                    Spacer()
                    
                    // 作者信息
                    VStack(spacing: 5) {
                        Text("作者: billma007")
                        Text("邮箱: ma237103015@126.com")
                        Text("QQ: 36937975")
                    }
                    .foregroundColor(.gray)
                    .font(.footnote)
                    .padding(.bottom, 20)
                }
                .padding()
            }
        }
        .statusBar(hidden: true) // 隐藏状态栏沉浸式体验
    }
}

// 全映射游戏模式视图
struct FullMappingGameView: View {
    @ObservedObject var networkManager: NetworkManager
    // 键位设置 [按键字符]
    let leftKeys: [Character] = ["s", "d", "f"]
    let rightKeys: [Character] = ["j", "k", "l"]
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                // 0. 防误触背景层 (Palm Rejection Layer)
                // 捕获所有落在空白区域的触摸，防止系统多任务手势干扰或触摸穿透
                PalmRestView()
                    .edgesIgnoringSafeArea(.all)
                
                // 1. 按键区域 Trigger Keys
                // 布局调整：高度20%，距边10%，中间间隔拉大，按键宽度保持原比例(约32.5%)
                
                let sideMargin = width * 0.10 // 距离iPad最边上10%
                // 调整：按键高度增加，保持底部位置不变 (Bottom = Top + Height = 0.30 + 0.35 = 0.65, same as old 0.40+0.25)
                let keyAreaHeight = height * 0.35 // 高度拉高 (之前25%)
                let keyTopMargin = height * 0.30 // 顶部上移以保持底座不变 (之前40%)
                
                // 保持按键群组的宽度不变 (Previously approx 32.5% of total width)
                let groupWidth = width * 0.325
                let keyWidth = groupWidth / 3.0
                
                // 左侧键盘组 (S D F)
                HStack(spacing: 0) {
                    ForEach(leftKeys, id: \.self) { key in
                        KeyButton(char: key, networkManager: networkManager)
                            .frame(width: keyWidth, height: keyAreaHeight)
                            //.border(Color.gray, width: 1)
                    }
                }
                .position(x: sideMargin + groupWidth / 2.0, y: keyTopMargin + keyAreaHeight / 2.0)
                
                // 右侧键盘组 (J K L)
                HStack(spacing: 0) {
                    ForEach(rightKeys, id: \.self) { key in
                        KeyButton(char: key, networkManager: networkManager)
                            .frame(width: keyWidth, height: keyAreaHeight)
                            //.border(Color.gray, width: 1)
                    }
                }
                .position(x: width - (sideMargin + groupWidth / 2.0), y: keyTopMargin + keyAreaHeight / 2.0)
                
                // 2. 鼠标控制区域 (Relative Touch)
                // 布局调整：降到iPad最底部，高度增加，保持底座不变
                let padWidth = width * 0.85
                let padHeight = height * 0.25 // 高度增加 (之前15%)
                let padBottomMargin = height * 0.05 // 离底部留一点空隙 (5%) - 保持底座位置不变
                let padY = height - padBottomMargin - (padHeight / 2.0)
                
                ZStack {
                     // 背景框
                    Rectangle()
                        .fill(Color.blue.opacity(0.15))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                        )
                    
                    Text("光标 (相对)")
                        .foregroundColor(.blue.opacity(0.7))
                        .font(.caption)
                    
                    // 仅在此区域响应的相对触控板
                    MultiTouchPad(networkManager: networkManager, mode: .constant(.relative))
                }
                .frame(width: padWidth, height: padHeight)
                .position(x: width / 2.0, y: padY)
                
                // 3. 断开连接按钮 (放在最底部中间或角落)
                VStack {
                    Spacer()
                    Button(action: {
                        networkManager.disconnect()
                    }) {
                        Text("退出模式")
                            .font(.caption)
                            .padding(8)
                            .background(Color.red.opacity(0.4))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

// 防误触背景视图
struct PalmRestView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isMultipleTouchEnabled = true
        // 关键：不独占触摸，允许其他视图（如上面的按键）接收触摸
        // 但如果触摸落在空地上，它会吞掉，防止系统手势
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// 独立的按键视图，处理按下和抬起
struct KeyButton: UIViewRepresentable {
    var char: Character
    var networkManager: NetworkManager
    
    func makeUIView(context: Context) -> KeyUIView {
        let view = KeyUIView()
        view.char = char
        view.networkManager = networkManager
        view.isMultipleTouchEnabled = true // 必须开启多点触控
        view.backgroundColor = .darkGray.withAlphaComponent(0.3)
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 5
        
        let label = UILabel()
        label.text = String(char).uppercased()
        label.textColor = .white
        label.font = .systemFont(ofSize: 30, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: KeyUIView, context: Context) {
        // No updates needed
    }
    
    class KeyUIView: UIView {
        var char: Character = " "
        weak var networkManager: NetworkManager?
        private var activeTouch: UITouch? // 跟踪触发这个键的 specific touch
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            // 如果还没被触发，就认领第一个触摸点
            for touch in touches {
                 // 简单的防误触：如果接触面积过大（手掌），则忽略
                if touch.majorRadius > 60 {
                    continue
                }
                
                if activeTouch == nil {
                    activeTouch = touch
                    backgroundColor = .white.withAlphaComponent(0.6) // 高亮
                    networkManager?.sendKeyDown(char)
                    // 只接受一个触摸作为触发源
                    break 
                }
            }
        }
        
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            // 只有当是认领的那个触摸点结束时，才释放
            if let touch = activeTouch, touches.contains(touch) {
                releaseKey()
            }
        }
        
        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
             if let touch = activeTouch, touches.contains(touch) {
                releaseKey()
            }
        }
        
        private func releaseKey() {
            activeTouch = nil
            backgroundColor = .darkGray.withAlphaComponent(0.3)
            networkManager?.sendKeyUp(char)
        }
    }
}

// 使用 UIKit 处理多点触控，比 SwiftUI 的 DragGesture 更灵敏且支持多指
struct MultiTouchPad: UIViewRepresentable {
    var networkManager: NetworkManager
    @Binding var mode: ControlMode
    
    func makeUIView(context: Context) -> TouchPadUIView {
        let view = TouchPadUIView()
        view.networkManager = networkManager
        view.parentStruct = self // Pass reference to access state
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .darkGray // 稍微浅一点的黑色以便区分
        return view
    }
    
    func updateUIView(_ uiView: TouchPadUIView, context: Context) {
        uiView.parentStruct = self
    }
    
    class TouchPadUIView: UIView {
        weak var networkManager: NetworkManager?
        var parentStruct: MultiTouchPad?
        private var previousTouchLocations: [UITouch: CGPoint] = [:]
        private var ignoredTouches: Set<UITouch> = [] // 严格防误触黑名单
        
        // 灵敏度系数，可以在App内调节，或者硬编码。
        // PC端鼠标移动 1px 对应 iPad 移动多少 point
        let sensitivity: CGFloat = 2.0 
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            for touch in touches {
                // 记录初始位置
                previousTouchLocations[touch] = touch.location(in: self)

                // 简单的防误触：如果接触面积过大 (>60)，视为手掌忽略
                // 不再使用“黑名单”锁定，允许恢复
                if touch.majorRadius > 60 {
                    continue
                }
                
                // Absolute Mode: Trigger updates immediately on touch down
                if let parent = parentStruct, parent.mode == .absolute {
                    handleAbsoluteInput(touch: touch)
                }
            }
        }
        
        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            for touch in touches {
                let currentLocation = touch.location(in: self)
                
                // 获取上一次的位置 (可能是上一帧刚刚更新的，也可能是 began 时的)
                let previousLocation = previousTouchLocations[touch]
                
                // 始终更新位置！这是解决“跳跃”的关键。
                // 无论这次是不是手掌，我们都更新 "上一帧位置" 为 "当前位置"。
                // 这样下一次如果变回手指，delta 就是从当前位置开始算的微小距离，而不是从很久以前的位置算的巨大跳跃。
                previousTouchLocations[touch] = currentLocation

                // 如果是大面积触控，这次不发送数据，但位置已经更新了
                if touch.majorRadius > 60 {
                    continue
                }
                
                // Check mode
                if let parent = parentStruct, parent.mode == .absolute {
                     handleAbsoluteInput(touch: touch)
                } else {
                    // Relative Mode
                    if let prev = previousLocation {
                        let deltaX = currentLocation.x - prev.x
                        let deltaY = currentLocation.y - prev.y
                        
                        // 过滤微小抖动
                        if abs(deltaX) > 0.1 || abs(deltaY) > 0.1 { // Added Y check just in case, though logic was X only
                             // 发送数据
                             networkManager?.sendDelta(dx: Float(deltaX * sensitivity))
                        }
                    }
                }
            }
        }
        
        private func handleAbsoluteInput(touch: UITouch) {
            let location = touch.location(in: self)
            let width = self.bounds.width
            if width > 0 {
                // Calculate normalized X (0.0 to 1.0)
                let ratio = location.x / width
                networkManager?.sendAbsoluteX(ratio: Float(ratio))
            }
        }
        
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            for touch in touches {
                previousTouchLocations.removeValue(forKey: touch)
            }
        }
        
        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            touchesEnded(touches, with: event)
        }
    }
}
