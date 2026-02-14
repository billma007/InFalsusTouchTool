#include <iostream>
#include <winsock2.h>
#include <windows.h>
#include <string>

#pragma comment(lib, "ws2_32.lib")

#define PORT 8888
#define BUFFER_SIZE 1024

// 获取屏幕宽度（主显示器）
int getScreenWidth() {
    return GetSystemMetrics(SM_CXSCREEN);
}

// 获取屏幕高度（主显示器）
int getScreenHeight() {
    return GetSystemMetrics(SM_CYSCREEN);
}

void moveMouseRelative(int dx, int dy) {
    INPUT inputs[1] = {};
    inputs[0].type = INPUT_MOUSE;
    inputs[0].mi.dx = dx;
    inputs[0].mi.dy = dy;
    inputs[0].mi.dwFlags = MOUSEEVENTF_MOVE;
    
    SendInput(1, inputs, sizeof(INPUT));
}

void moveMouseAbsoluteX(float normalizedX) {
    // 获取当前鼠标位置，为了保持 Y 不变
    POINT currentPos;
    if (GetCursorPos(&currentPos)) {
        // 使用 SendInput + MOUSEEVENTF_ABSOLUTE 替代 SetCursorPos
        // 很多游戏忽略 SetCursorPos，但会响应 SendInput 模拟的硬件消息
        
        // 获取主屏幕分辨率
        int screenHeight = getScreenHeight();
        if (screenHeight == 0) screenHeight = 1; // 防止除零

        // 计算绝对坐标 (0 - 65535)
        int absX = static_cast<int>(normalizedX * 65535);
        int absY = static_cast<int>((static_cast<double>(currentPos.y) / screenHeight) * 65535);

        INPUT inputs[1] = {};
        inputs[0].type = INPUT_MOUSE;
        inputs[0].mi.dx = absX;
        inputs[0].mi.dy = absY; // 保持 Y 轴相对不变
        inputs[0].mi.dwFlags = MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE;
        
        SendInput(1, inputs, sizeof(INPUT));
    }
}

void simulateKey(char key, bool down) {
    INPUT inputs[1] = {};
    inputs[0].type = INPUT_KEYBOARD;
    
    // 1. 获取虚拟键码 (VK)
    SHORT vk = VkKeyScan(key); 
    BYTE virtualKey = vk & 0xFF;

    // 2. 获取硬件扫描码 (Scan Code)
    // 很多 DirectX 游戏只响应扫描码，不响应虚拟键码
    UINT scanCode = MapVirtualKey(virtualKey, 0); // 0 = MAPVK_VK_TO_VSC

    inputs[0].ki.wVk = virtualKey;
    inputs[0].ki.wScan = scanCode;
    
    // 3. 设置标志位：启用扫描码模式
    inputs[0].ki.dwFlags = KEYEVENTF_SCANCODE;
    
    if (!down) {
        inputs[0].ki.dwFlags |= KEYEVENTF_KEYUP;
    }
    
    SendInput(1, inputs, sizeof(INPUT));
}

int main() {
    WSADATA wsaData;
    SOCKET sockfd;
    struct sockaddr_in serverAddr, clientAddr;
    int clientAddrLen = sizeof(clientAddr);
    char buffer[BUFFER_SIZE];

    // 初始化 Winsock
    if (WSAStartup(MAKEWORD(2, 2), &wsaData) != 0) {
        std::cerr << "WSAStartup 初始化失败。" << std::endl;
        return 1;
    }

    // 创建 UDP socket
    if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) == INVALID_SOCKET) {
        std::cerr << "Socket 创建失败。" << std::endl;
        WSACleanup();
        return 1;
    }

    // 可以在这里设置 socket 接收缓冲区大小，或者设置为非阻塞（如果需要）
    // 为了极低延迟，通常默认即可，或者使用 setsockopt 调整 SO_RCVBUF

    serverAddr.sin_family = AF_INET;
    serverAddr.sin_addr.s_addr = INADDR_ANY;
    serverAddr.sin_port = htons(PORT);

    // 绑定端口
    if (bind(sockfd, (struct sockaddr *)&serverAddr, sizeof(serverAddr)) == SOCKET_ERROR) {
        std::cerr << "端口绑定失败。" << std::endl;
        closesocket(sockfd);
        WSACleanup();
        return 1;
    }

    std::cout << "正在监听 UDP 端口 " << PORT << "..." << std::endl;
    std::cout << "按 Ctrl+C 退出。" << std::endl;

    while (true) {
        int rect = recvfrom(sockfd, buffer, BUFFER_SIZE - 1, 0, (struct sockaddr *)&clientAddr, &clientAddrLen);
        if (rect > 0) {
            buffer[rect] = '\0';
            try {
                // Determine if it is Absolute or Relative
                // Protocol: "A0.5" -> Absolute X at 50%
                //           "10.5" -> Relative X delta
                
                std::string msg(buffer);
                if (msg.empty()) continue;

                if (msg[0] == 'A') {
                    // Absolute Mode
                    std::string valStr = msg.substr(1);
                    float normalizedX = std::stof(valStr);
                    moveMouseAbsoluteX(normalizedX);
                    // std::cout << "Abs Move: " << normalizedX << std::endl;
                } else if (msg[0] == 'K') {
                    // Keyboard Event: "KDs" or "KUs"
                    if (msg.length() >= 3) {
                        bool down = (msg[1] == 'D'); // 'D' for Down
                        char key = msg[2];
                        simulateKey(key, down);
                         // std::cout << "Key " << key << (down ? " Down" : " Up") << std::endl;
                    }
                } else {
                    // Relative Mode (Original)
                    float deltaX = std::stof(buffer);
                    int moveX = static_cast<int>(deltaX);
                    
                    if (moveX != 0) {
                         moveMouseRelative(moveX, 0);
                    }
                }
               
            } catch (const std::exception& e) {
                // 忽略解析错误
            }
        }
    }

    closesocket(sockfd);
    WSACleanup();
    return 0;
}
