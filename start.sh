#!/bin/bash

# Цвета
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
WHITE='\033[1;37m'
NC='\033[0m'

clear
echo "╔══════════════════════════════════════╗"
echo "║    a1enka - AI Code Assistant        ║"
echo "╚══════════════════════════════════════╝"
echo ""

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SERVER_PATH="$SCRIPT_DIR/server"

# Проверка Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}[ОШИБКА]${NC} Node.js не найден!"
    echo "Запустите ./install.sh сначала"
    exit 1
fi

# Проверка зависимостей
if [ ! -d "$SERVER_PATH/node_modules" ]; then
    echo -e "${RED}[ОШИБКА]${NC} Зависимости не установлены!"
    echo "Запустите ./install.sh сначала"
    exit 1
fi

# Проверка Ollama
if ! command -v ollama &> /dev/null; then
    echo -e "${RED}[ОШИБКА]${NC} Ollama не найдена!"
    echo "Запустите ./install.sh сначала"
    exit 1
fi

# Запуск Ollama если не запущена
if ! pgrep -x "ollama" > /dev/null; then
    echo -e "${CYAN}[INFO]${NC} Запуск Ollama..."
    ollama serve &
    sleep 3
    if ! pgrep -x "ollama" > /dev/null; then
        echo -e "${RED}[ОШИБКА]${NC} Не удалось запустить Ollama!"
        exit 1
    fi
    echo -e "${GREEN}[OK]${NC} Ollama запущена"
fi

# Установка CORS
export OLLAMA_ORIGINS="*"

echo ""
echo -e "${GREEN}[OK]${NC} Запуск сервера a1enka на порту 3000..."
echo ""
echo "Не закрывайте это окно!"
echo "Для остановки нажмите Ctrl+C"
echo ""
echo "╔══════════════════════════════════════╗"
echo ""

cd "$SERVER_PATH"
node server.js