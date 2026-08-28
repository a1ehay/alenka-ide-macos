#!/bin/bash

# Цвета
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Функции
write_step() { echo -e "\n${CYAN}[==>]${NC} ${WHITE}$1${NC}"; }
write_ok() { echo -e "${GREEN}[OK]${NC} ${WHITE}$1${NC}"; }
write_err() { echo -e "${RED}[!!]${NC} ${WHITE}$1${NC}"; }
write_warn() { echo -e "${YELLOW}[?]${NC} ${WHITE}$1${NC}"; }

clear
echo "══════════════════════════════════════════╗"
echo "║        a1enka - AI Code Assistant        ║"
echo "║        Автоматическая установка          ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Проверка прав
if [ "$EUID" -eq 0 ]; then 
    write_err "Не запускайте от root! Скрипт сам запросит пароль при необходимости."
    exit 1
fi

# ============================================
# ШАГ 1: Node.js
# ============================================
write_step "Проверка Node.js..."

if command -v node &> /dev/null; then
    node_version=$(node --version)
    write_ok "Node.js уже установлен: $node_version"
else
    write_warn "Node.js не найден. Устанавливаю..."
    
    # Проверяем Homebrew
    if ! command -v brew &> /dev/null; then
        write_warn "Homebrew не найден. Устанавливаю Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Добавляем brew в PATH для Apple Silicon
        if [ "$(uname -m)" = "arm64" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
    
    write_ok "Homebrew готов"
    write_host "  Устанавливаю Node.js через Homebrew..."
    brew install node
    write_ok "Node.js установлен"
fi

# ============================================
# ШАГ 2: Ollama
# ============================================
write_step "Проверка Ollama..."

if command -v ollama &> /dev/null; then
    ollama_version=$(ollama --version)
    write_ok "Ollama уже установлен: $ollama_version"
else
    write_warn "Ollama не найден. Устанавливаю..."
    
    # Проверяем Homebrew
    if ! command -v brew &> /dev/null; then
        write_warn "Homebrew не найден. Устанавливаю Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        if [ "$(uname -m)" = "arm64" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
    
    write_ok "Homebrew готов"
    write_host "  Устанавливаю Ollama..."
    brew install ollama
    write_ok "Ollama установлен"
    
    # Запускаем Ollama
    write_host "  Запускаю Ollama..."
    ollama serve &
    sleep 3
fi

# ============================================
# ШАГ 3: Лёгкая модель (qwen2.5:1.5b)
# ============================================
write_step "Проверка модели qwen2.5:1.5b..."

if ollama list 2>/dev/null | grep -q "qwen2.5:1.5b"; then
    write_ok "Модель уже скачана"
else
    write_warn "Скачиваю модель qwen2.5:1.5b (~1 ГБ)..."
    write_host "  Это займёт 2-5 минут..."
    
    # Убедимся, что Ollama запущена
    if ! pgrep -x "ollama" > /dev/null; then
        ollama serve &
        sleep 3
    fi
    
    ollama pull qwen2.5:1.5b
    
    if [ $? -eq 0 ]; then
        write_ok "Модель скачана"
    else
        write_err "Не удалось скачать модель"
        write_host "Запустите вручную: ollama pull qwen2.5:1.5b"
    fi
fi

# ============================================
# ШАГ 4: Зависимости сервера
# ============================================
write_step "Установка зависимостей сервера..."

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SERVER_PATH="$SCRIPT_DIR/server"

if [ ! -d "$SERVER_PATH" ]; then
    write_err "Папка server не найдена!"
    exit 1
fi

cd "$SERVER_PATH"
npm install

if [ $? -eq 0 ]; then
    write_ok "Зависимости установлены"
else
    write_err "Ошибка установки зависимостей"
    exit 1
fi

cd "$SCRIPT_DIR"

# ============================================
# ШАГ 5: Настройка CORS
# ============================================
write_step "Настройка Ollama для работы с браузером..."

# Добавляем переменную окружения в ~/.zshrc или ~/.bash_profile
SHELL_RC="$HOME/.zshrc"
if [ ! -f "$SHELL_RC" ]; then
    SHELL_RC="$HOME/.bash_profile"
fi

if ! grep -q "OLLAMA_ORIGINS" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# a1enka - Ollama CORS" >> "$SHELL_RC"
    echo "export OLLAMA_ORIGINS=\"*\"" >> "$SHELL_RC"
    write_ok "Переменная OLLAMA_ORIGINS добавлена в $SHELL_RC"
else
    write_ok "OLLAMA_ORIGINS уже настроена"
fi

# Устанавливаем для текущей сессии
export OLLAMA_ORIGINS="*"

# ============================================
# ШАГ 6: Создание alias для быстрого запуска
# ============================================
write_step "Создание alias для быстрого запуска..."

ALIAS_NAME="a1enka"
ALIAS_CMD="cd \"$SCRIPT_DIR\" && ./start.sh"

if ! grep -q "alias $ALIAS_NAME=" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# a1enka alias" >> "$SHELL_RC"
    echo "alias $ALIAS_NAME='$ALIAS_CMD'" >> "$SHELL_RC"
    write_ok "Alias '$ALIAS_NAME' добавлен в $SHELL_RC"
    write_host "  Теперь можно запустить командой: $ALIAS_NAME"
else
    write_ok "Alias уже существует"
fi

# ============================================
# ФИНАЛ
# ============================================
write_host ""
write_host "╔══════════════════════════════════════════╗"
write_host "║         УСТАНОВКА ЗАВЕРШЕНА!             ║"
write_host "╚══════════════════════════════════════════╝"
write_host ""
write_host "Осталось установить расширение в Firefox:"
write_host ""
write_host "  1. Откройте Firefox"
write_host "  2. Перейдите: about:debugging#/runtime/this-firefox"
write_host "  3. Нажмите 'Загрузить временное дополнение'"
write_host "  4. Выберите: extension/manifest.json"
write_host ""
write_host "После этого запускайте a1enka командой: ${GREEN}a1enka${NC}"
write_host "Или через файл: ${GREEN}./start.sh${NC}"
write_host ""

# Перезагружаем shell config
source "$SHELL_RC" 2>/dev/null || true

# Спрашиваем, открыть ли Firefox
read -p "Открыть Firefox для установки расширения? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open -a Firefox "about:debugging#/runtime/this-firefox" 2>/dev/null || open -a "Firefox" 2>/dev/null || echo "Firefox не найден. Установите Firefox."
fi

echo ""
write_ok "Готово! Приятной работы с a1enka 🚀"
echo ""