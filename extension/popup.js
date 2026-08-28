// Функция для показа уведомления
function showToast(message, type = 'info') {
  const toast = document.getElementById('toast');
  toast.textContent = message;
  toast.className = `toast ${type} show`;
  
  setTimeout(() => {
    toast.classList.remove('show');
  }, 2500);
}

// Элементы экранов
const screen1 = document.getElementById('screen1');
const screen2 = document.getElementById('screen2');
const projectPathInput = document.getElementById('projectPath');
const targetFileInput = document.getElementById('targetFile');
const currentPathDisplay = document.getElementById('currentPathDisplay');

function showScreen(screenNumber) {
  if (screenNumber === 1) {
    screen1.classList.remove('hidden');
    screen2.classList.add('hidden');
  } else {
    screen1.classList.add('hidden');
    screen2.classList.remove('hidden');
  }
}

// Загрузка сохранённых данных
const savedProjectPath = localStorage.getItem('projectPath') || '';
const savedTargetFile = localStorage.getItem('targetFile') || '';

// Восстанавливаем значение поля "путь к файлу"
if (savedTargetFile) {
  targetFileInput.value = savedTargetFile;
}

if (savedProjectPath) {
  currentPathDisplay.textContent = `📁 ${savedProjectPath}`;
  showScreen(2);
} else {
  showScreen(1);
}

// Сохранение значения targetFile при каждом изменении
targetFileInput.addEventListener('input', () => {
  localStorage.setItem('targetFile', targetFileInput.value);
});

// Подтверждение пути проекта
document.getElementById('confirmPathBtn').addEventListener('click', () => {
  const path = projectPathInput.value.trim();
  
  if (!path) {
    showToast('Введите путь к проекту!', 'error');
    return;
  }
  
  const normalizedPath = path.replace(/\\+$/, '').replace(/\/+$/, '');
  
  localStorage.setItem('projectPath', normalizedPath);
  currentPathDisplay.textContent = `📁 ${normalizedPath}`;
  
  showToast('Путь к проекту сохранён!', 'success');
  showScreen(2);
});

// Кнопка "Назад"
document.getElementById('backBtn').addEventListener('click', () => {
  projectPathInput.value = localStorage.getItem('projectPath') || '';
  showScreen(1);
  showToast('Изменение пути проекта', 'info');
});

// Отправка буфера в ИИ
document.getElementById('sendBtn').addEventListener('click', async () => {
  const targetFile = targetFileInput.value.trim();
  const projectPath = localStorage.getItem('projectPath');
  
  if (!targetFile) {
    showToast('Введите путь к файлу!', 'error');
    return;
  }
  
  showToast('Читаю буфер обмена...', 'info');
  
  try {
    const text = await navigator.clipboard.readText();
    
    if (!text) {
      showToast('Буфер обмена пуст!', 'error');
      return;
    }
    
    showToast('Отправка в ИИ...', 'info');
    
    const response = await fetch('http://localhost:3000/process', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text, targetFile, projectPath })
    });
    
    const data = await response.json();
    
    if (data.success) {
      showToast(`Записано в ${data.file}`, 'success');
    } else {
      showToast(`Ошибка: ${data.error}`, 'error');
    }
    
  } catch (error) {
    showToast(`Ошибка: ${error.message}`, 'error');
  }
});

// Очистка буфера обмена
document.getElementById('clearBtn').addEventListener('click', async () => {
  try {
    await navigator.clipboard.writeText('');
    showToast('Буфер обмена очищен!', 'success');
  } catch (error) {
    showToast(`Ошибка: ${error.message}`, 'error');
  }
});

// Переключение темы
const themeBtn = document.getElementById('themeBtn');
const body = document.body;

const savedTheme = localStorage.getItem('theme') || 'dark-theme';
body.className = savedTheme;
updateThemeIcon();

themeBtn.addEventListener('click', () => {
  if (body.classList.contains('dark-theme')) {
    body.classList.remove('dark-theme');
    body.classList.add('light-theme');
    localStorage.setItem('theme', 'light-theme');
  } else {
    body.classList.remove('light-theme');
    body.classList.add('dark-theme');
    localStorage.setItem('theme', 'dark-theme');
  }
  updateThemeIcon();
});

function updateThemeIcon() {
  if (body.classList.contains('dark-theme')) {
    themeBtn.textContent = '☀️';
    themeBtn.title = 'Переключить на светлую тему';
  } else {
    themeBtn.textContent = '🌚';
    themeBtn.title = 'Переключить на тёмную тему';
  }
}