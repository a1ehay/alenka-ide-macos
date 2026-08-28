const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 3000;
const MODEL = 'qwen2.5:1.5b'; // Лёгкая модель для слабых Mac

console.log('🚀 Запуск сервера a1enka...');
console.log(`📦 Модель: ${MODEL} (оптимизирована для macOS)`);

const server = http.createServer(async (req, res) => {
  console.log(`\n📥 Запрос: ${req.method} ${req.url}`);
  
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  if (req.method === 'POST' && req.url === '/process') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', async () => {
      try {
        console.log('📝 Получены данные');
        const { text, targetFile, projectPath } = JSON.parse(body);
        
        console.log(`📁 Проект: ${projectPath}`);
        console.log(`📄 Файл: ${targetFile}`);

        if (!projectPath || !targetFile) {
          throw new Error('Не указан projectPath или targetFile');
        }

        if (!fs.existsSync(projectPath)) {
          throw new Error(`Папка не существует: ${projectPath}`);
        }

        const filePath = path.join(projectPath, targetFile);
        const fileExists = fs.existsSync(filePath);
        
        let existingCode = '';
        if (fileExists) {
          existingCode = fs.readFileSync(filePath, 'utf8');
          console.log(`📖 Файл прочитан (${existingCode.length} символов)`);
        } else {
          console.log('📄 Файл будет создан');
        }

        console.log('🤖 Отправка в Ollama...');
        
        // Оптимизированный промпт для лёгкой модели
        const prompt = fileExists 
          ? `Обнови код файла. Если есть функция с таким же именем — замени её. Если нет — добавь в конец. Сохрани весь остальной код. Верни полный файл.

<existing>
${existingCode}
</existing>

<new>
${text}
</new>`
          : `Улучши код:

${text}`;

        const ollamaResponse = await fetch('http://localhost:11434/api/generate', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            model: MODEL,
            prompt: prompt,
            stream: false,
            options: { 
              num_ctx: 4096,        // Меньший контекст для скорости
              temperature: 0.3,     // Более предсказуемые результаты
              repeat_penalty: 1.1
            }
          })
        });

        if (!ollamaResponse.ok) {
          throw new Error(`Ollama ошибка: ${ollamaResponse.status}`);
        }

        const ollamaData = await ollamaResponse.json();
        let refinedCode = ollamaData.response.trim();
        
        // Удаляем markdown-обёртки
        refinedCode = refinedCode
          .replace(/^```[a-z]*\n?/i, '')
          .replace(/\n?```$/i, '')
          .trim();
        
        console.log(`✅ Ответ получен (${refinedCode.length} символов)`);

        const dir = path.dirname(filePath);
        if (!fs.existsSync(dir)) {
          fs.mkdirSync(dir, { recursive: true });
        }
        
        fs.writeFileSync(filePath, refinedCode, 'utf8');
        console.log('✅ Файл обновлён!');

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ 
          success: true, 
          file: targetFile,
          fileExisted: fileExists
        }));

      } catch (error) {
        console.error('❌ Ошибка:', error.message);
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: error.message }));
      }
    });
  } else {
    res.writeHead(404);
    res.end('Not Found');
  }
});

server.listen(PORT, () => {
  console.log(`✅ Сервер на http://localhost:${PORT}`);
  console.log('⏹️  Ctrl+C для остановки\n');
});