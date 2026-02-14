import Foundation
import Network
import Combine

class NetworkManager: ObservableObject {
    var connection: NWConnection?
    var host: NWEndpoint.Host?
    var port: NWEndpoint.Port = 8888 // 默认端口，PC端需监听此端口
    
    @Published var isConnected: Bool = false
    @Published var errorMsg: String = ""

    func connect(to ip: String) {
        let host = NWEndpoint.Host(ip)
        self.host = host
        // 使用 UDP 协议，以此获得最低延迟
        let params = NWParameters.udp
        // 这一步是设置不需要建立连接确认，即发即走，虽不可靠但速度最快
        params.allowFastOpen = true
        
        self.connection = NWConnection(host: host, port: port, using: params)
        
        self.connection?.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self?.isConnected = true
                    print("已连接到 \(ip)")
                case .failed(let error):
                    self?.isConnected = false
                    self?.errorMsg = "连接失败: \(error.localizedDescription)"
                    print("连接失败: \(error)")
                case .waiting(let error):
                    print("等待连接: \(error)")
                case .cancelled:
                    self?.isConnected = false
                    print("连接已取消")
                default:
                    break
                }
            }
        }
        
        self.connection?.start(queue: .global(qos: .userInteractive))
    }
    
    func disconnect() {
        self.connection?.cancel()
        self.connection = nil
        self.isConnected = false
    }
    
    // 发送通用消息（底层实现）
    private func send(data: Data) {
        guard let connection = connection, connection.state == .ready else { return }
        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("发送错误: \(error)")
            }
        })
    }

    // 发送位移增量 (Relative Mode)
    func sendDelta(dx: Float) {
        let message = "\(dx)"
        if let data = message.data(using: .utf8) {
            send(data: data)
        }
    }
    
    // 发送绝对坐标 (Absolute Mode)
    // ratio: 0.0 ~ 1.0
    func sendAbsoluteX(ratio: Float) {
        let message = "A\(ratio)"
        if let data = message.data(using: .utf8) {
            send(data: data)
        }
    }
    
    // 发送按键按下
    func sendKeyDown(_ key: Character) {
        let message = "KD\(key)"
        if let data = message.data(using: .utf8) {
            send(data: data)
        }
    }
    
    // 发送按键抬起
    func sendKeyUp(_ key: Character) {
        let message = "KU\(key)"
        if let data = message.data(using: .utf8) {
            send(data: data)
        }
    }
}
