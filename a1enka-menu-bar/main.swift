import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var serverProcess: Process?
    var projectPath: String = ""
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Читаем путь к проекту из конфигурационного файла
        if let configPath = Bundle.main.path(forResource: "project_path", ofType: "txt") {
            do {
                projectPath = try String(contentsOfFile: configPath, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
            } catch {
                showNotification("Ошибка", message: "Не удалось найти путь к проекту.")
                NSApp.terminate(nil)
                return
            }
        } else {
            showNotification("Ошибка", message: "Файл project_path.txt не найден. Переустановите приложение.")
            NSApp.terminate(nil)
            return
        }
        
        // 2. Создаем иконку в строке меню
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let iconPath = Bundle.main.path(forResource: "icon16", ofType: "png") {
            let image = NSImage(contentsOfFile: iconPath)
            image?.isTemplate = true // Делает иконку адаптивной (белой/черной в зависимости от темы)
            statusItem.button?.image = image
        } else {
            statusItem.button?.title = "a1enka"
        }
        
        statusItem.button?.toolTip = "a1enka - AI Code Assistant"
        
        // 3. Создаем меню
        let menu = NSMenu()
        
        let statusMenuItem = NSMenuItem(title: "Статус: ⏹️ Остановлен", action: nil, keyEquivalent: "")
        statusMenuItem.tag = 1
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "▶️ Запустить сервер", action: #selector(startServer), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "⏹️ Остановить сервер", action: #selector(stopServer), keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "🦊 Открыть Firefox", action: #selector(openFirefox), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "ℹ️ О программе", action: #selector(showAbout), keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "❌ Выход", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc func startServer() {
        if serverProcess != nil && serverProcess!.isRunning {
            showNotification("Уже работает", message: "Сервер a1enka уже запущен на порту 3000.")
            return
        }
        
        let serverScriptPath = projectPath + "/server/server.js"
        
        // Ищем исполняемый файл node (поддержка и Intel, и Apple Silicon)
        let fileManager = FileManager.default
        var nodePath = "/usr/local/bin/node" // Intel Mac
        if fileManager.fileExists(atPath: "/opt/homebrew/bin/node") {
            nodePath = "/opt/homebrew/bin/node" // Apple Silicon Mac
        }
        
        serverProcess = Process()
        serverProcess?.executableURL = URL(fileURLWithPath: nodePath)
        serverProcess?.arguments = [serverScriptPath]
        
        // Передаем переменные окружения
        var env = ProcessInfo.processInfo.environment
        env["OLLAMA_ORIGINS"] = "*"
        env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:" + (env["PATH"] ?? "")
        serverProcess?.environment = env
        
        do {
            try serverProcess?.run()
            showNotification("Сервер запущен", message: "a1enka готов к работе (порт 3000).")
            updateStatus("Статус: ✅ Работает")
        } catch {
            showNotification("Ошибка запуска", message: "Не удалось запустить сервер: \(error.localizedDescription)")
        }
    }
    
    @objc func stopServer() {
        if let process = serverProcess, process.isRunning {
            process.terminate()
            serverProcess = nil
            showNotification("Сервер остановлен", message: "a1enka успешно остановлен.")
            updateStatus("Статус: ⏹️ Остановлен")
        } else {
            showNotification("Информация", message: "Сервер не был запущен.")
        }
    }
    
    @objc func openFirefox() {
        NSWorkspace.shared.open(URL(string: "about:debugging#/runtime/this-firefox")!)
    }
    
    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "a1enka"
        alert.informativeText = "Локальный AI-помощник для редактирования кода.\n\nВерсия: 1.0\nМодель: qwen2.5:1.5b\nПорт: 3000"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc func quitApp() {
        stopServer()
        NSApp.terminate(nil)
    }
    
    // Вспомогательные функции
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