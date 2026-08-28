#!/bin/bash

CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${CYAN}Создание menu bar приложения a1enka...${NC}"

# Путь к проекту
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MENU_BAR_DIR="$PROJECT_DIR/a1enka-menu-bar"

# Создаём папку
mkdir -p "$MENU_BAR_DIR"

# Создаём Swift файл для menu bar приложения
cat > "$MENU_BAR_DIR/main.swift" << 'SWIFT'
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var serverProcess: Process?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Создаём иконку в menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Устанавливаем иконку (если есть)
        if let iconPath = Bundle.main.path(forResource: "icon16", ofType: "png") {
            statusItem.button?.image = NSImage(contentsOfFile: iconPath)
        } else {
            statusItem.button?.title = "a1enka"
        }
        
        statusItem.button?.toolTip = "a1enka - AI Code Assistant"
        
        // Создаём меню
        let menu = NSMenu()
        
        // Пункт: Статус сервера
        let statusItem_menu = NSMenuItem(title: "Статус: Не запущен", action: nil, keyEquivalent: "")
        statusItem_menu.tag = 1
        menu.addItem(statusItem_menu)
        
        menu.addItem(NSMenuItem.separator())
        
        // Пункт: Запустить сервер
        let startItem = NSMenuItem(title: "▶️ Запустить сервер", action: #selector(startServer), keyEquivalent: "")
        menu.addItem(startItem)
        
        // Пункт: Остановить сервер
        let stopItem = NSMenuItem(title: "⏹️ Остановить сервер", action: #selector(stopServer), keyEquivalent: "")
        menu.addItem(stopItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Пункт: Открыть Firefox
        let firefoxItem = NSMenuItem(title: "Открыть Firefox", action: #selector(openFirefox), keyEquivalent: "")
        menu.addItem(firefoxItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Пункт: О программе
        let aboutItem = NSMenuItem(title: "ℹ️ О программе", action: #selector(showAbout), keyEquivalent: "")
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Пункт: Выход
        let quitItem = NSMenuItem(title: "❌ Выход", action: #selector(quitApp), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    @objc func startServer() {
        if serverProcess != nil && serverProcess!.isRunning {
            showNotification("Сервер уже запущен", message: "a1enka работает на порту 3000")
            return
        }
        
        // Находим путь к server.js
        let appPath = Bundle.main.bundlePath
        let projectDir = (appPath as NSString).deletingLastPathComponent
            .replacingOccurrences(of: "/a1enka-menu-bar", with: "")
        
        let serverPath = projectDir + "/server/server.js"
        
        serverProcess = Process()
        serverProcess?.executableURL = URL(fileURLWithPath: "/usr/local/bin/node")
        serverProcess?.arguments = [serverPath]
        serverProcess?.environment = ["OLLAMA_ORIGINS": "*"]
        
        do {
            try serverProcess?.run()
            showNotification("Сервер запущен", message: "a1enka работает на порту 3000")
            updateStatus("Статус: ✅ Работает")
        } catch {
            showNotification("Ошибка", message: "Не удалось запустить сервер: \(error.localizedDescription)")
        }
    }
    
    @objc func stopServer() {
        if let process = serverProcess, process.isRunning {
            process.terminate()
            serverProcess = nil
            showNotification("Сервер остановлен", message: "a1enka остановлен")
            updateStatus("Статус: ⏹️ Остановлен")
        } else {
            showNotification("Сервер не запущен", message: "Нечего останавливать")
        }
    }
    
    @objc func openFirefox() {
        NSWorkspace.shared.open(URL(string: "about:debugging#/runtime/this-firefox")!)
    }
    
    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "a1enka"
        alert.informativeText = "AI Code Assistant v1.0\n\nЛокальный AI-помощник для редактирования кода.\n\nМодель: qwen2.5:1.5b\nПорт: 3000"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc func quitApp() {
        stopServer()
        NSApp.terminate(nil)
    }
    
    func updateStatus(_ text: String) {
        DispatchQueue.main.async {
            if let item = self.statusItem.menu?.item(withTag: 1) {
                item.title = text
            }
        }
    }
    
    func showNotification(_ title: String, message: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
SWIFT

# Создаём Info.plist для app bundle
cat > "$MENU_BAR_DIR/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>a1enkaMenuBar</string>
    <key>CFBundleName</key>
    <string>a1enka</string>
    <key>CFBundleIdentifier</key>
    <string>com.a1enka.menubar</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
PLIST

# Копируем иконку
if [ -f "$PROJECT_DIR/extension/icon16.png" ]; then
    cp "$PROJECT_DIR/extension/icon16.png" "$MENU_BAR_DIR/icon16.png"
fi

echo -e "${GREEN}✅ Файлы созданы в: $MENU_BAR_DIR${NC}"
echo ""
echo "Теперь скомпилируйте приложение:"
echo "  swiftc -o $MENU_BAR_DIR/a1enkaMenuBar $MENU_BAR_DIR/main.swift"
echo ""
echo "Или используйте готовый скрипт сборки:"
echo "  ./build-menu-bar.sh"
echo ""