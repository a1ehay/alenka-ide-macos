#!/bin/bash

# Получаем путь к папке, где лежит этот скрипт
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Функция для системных уведомлений macOS
notify() {
    osascript -e "display notification \"$2\" with title \"$1\""
}

notify "a1enka" "Начинаю установку... Это может занять несколько минут."

# 1. Homebrew
if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ "$(uname -m)" = "arm64" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# 2. Node.js
if ! command -v node &> /dev/null; then
    brew install node
fi

# 3. Ollama
if ! command -v ollama &> /dev/null; then
    brew install ollama
    # Запускаем ollama в фоне, чтобы она была готова
    ollama serve &
    sleep 5
fi

# 4. Модель
if ! ollama list 2>/dev/null | grep -q "qwen2.5:1.5b"; then
    notify "a1enka" "Скачиваю нейросеть (около 1 ГБ)..."
    ollama pull qwen2.5:1.5b
fi

# 5. Зависимости сервера
cd "$SCRIPT_DIR/server" || exit
npm install
cd "$SCRIPT_DIR" || exit

# 6. Настройка CORS
if ! grep -q "OLLAMA_ORIGINS" "$HOME/.zshrc" 2>/dev/null; then
    echo 'export OLLAMA_ORIGINS="*"' >> "$HOME/.zshrc"
fi
export OLLAMA_ORIGINS="*"

# 7. Сборка Menu Bar App
MENU_BAR_DIR="$SCRIPT_DIR/a1enka-menu-bar"
APP_PATH="$MENU_BAR_DIR/a1enkaMenuBar.app"

if [ -d "$MENU_BAR_DIR" ]; then
    notify "a1enka" "Создаю приложение для строки меню..."
    
    # Устанавливаем Xcode tools если нет swiftc
    if ! command -v swiftc &> /dev/null; then
        xcode-select --install
        # Ждем, пока пользователь нажмет "Установить" в системном окне (грубая оценка времени)
        sleep 10 
    fi

    mkdir -p "$APP_PATH/Contents/MacOS"
    mkdir -p "$APP_PATH/Contents/Resources"
    
    # Компиляция
    swiftc -o "$APP_PATH/Contents/MacOS/a1enkaMenuBar" "$MENU_BAR_DIR/main.swift" 2>/dev/null
    
    # Копирование ресурсов
    cp "$MENU_BAR_DIR/Info.plist" "$APP_PATH/Contents/Info.plist"
    if [ -f "$MENU_BAR_DIR/icon16.png" ]; then
        cp "$MENU_BAR_DIR/icon16.png" "$APP_PATH/Contents/Resources/icon16.png"
    fi
    
    # Запись пути к проекту внутрь приложения
    echo "$SCRIPT_DIR" > "$APP_PATH/Contents/Resources/project_path.txt"
    
    # Копируем готовое приложение на Рабочий стол
    DESKTOP_DIR="$HOME/Desktop"
    cp -R "$APP_PATH" "$DESKTOP_DIR/"
    
    notify "a1enka" "✅ Установка завершена! Приложение a1enka появилось на Рабочем столе."
else
    notify "Ошибка a1enka" "Папка a1enka-menu-bar не найдена. Проверьте целостность архива."
fi