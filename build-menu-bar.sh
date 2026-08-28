#!/bin/bash

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}🔨 Сборка a1enka Menu Bar App...${NC}"

# Определяем абсолютный путь к текущей папке проекта
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MENU_BAR_DIR="$PROJECT_DIR/a1enka-menu-bar"
APP_PATH="$MENU_BAR_DIR/a1enkaMenuBar.app"

# 1. Проверяем наличие Swift
if ! command -v swiftc &> /dev/null; then
    echo -e "${RED}❌ Swift не найден! Установите Xcode Command Line Tools:${NC}"
    echo "  xcode-select --install"
    exit 1
fi

# 2. Создаем структуру .app
echo "Создание структуры приложения..."
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

# 3. Компилируем Swift код
echo "Компиляция Swift кода..."
swiftc -o "$APP_PATH/Contents/MacOS/a1enkaMenuBar" "$MENU_BAR_DIR/main.swift"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Ошибка компиляции Swift.${NC}"
    exit 1
fi

# 4. Копируем конфигурационные файлы
cp "$MENU_BAR_DIR/Info.plist" "$APP_PATH/Contents/Info.plist"

if [ -f "$MENU_BAR_DIR/icon16.png" ]; then
    cp "$MENU_BAR_DIR/icon16.png" "$APP_PATH/Contents/Resources/icon16.png"
else
    echo -e "${RED}⚠️ Иконка icon16.png не найдена!${NC}"
fi

# 5. ГЛАВНЫЙ ТРЮК: Записываем абсолютный путь к проекту внутрь приложения
echo "$PROJECT_DIR" > "$APP_PATH/Contents/Resources/project_path.txt"
echo -e "${GREEN}✅ Путь к проекту сохранен внутри приложения.${NC}"

echo ""
echo -e "${GREEN}🎉 Сборка успешно завершена!${NC}"
echo "Приложение находится здесь: $APP_PATH"
echo ""
echo "Теперь вы можете:"
echo "  1. Перетащить a1enkaMenuBar.app на Рабочий стол или в Программы."
echo "  2. Запустить его двойным кликом."
echo "  3. Найти иконку a1enka в верхней строке меню (возле часов)."
echo ""

# Спрашиваем, открыть ли
read -p "Открыть приложение сейчас? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "$APP_PATH"
fi