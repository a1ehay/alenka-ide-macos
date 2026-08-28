#!/usr/bin/env node

const { exec } = require('child_process');
const path = require('path');

// Запускаем сервер в фоне
const serverPath = path.join(__dirname, 'server', 'server.js');
exec(`node "${serverPath}" > /dev/null 2>&1 &`, (error, stdout, stderr) => {
    if (error) {
        console.error(`Ошибка: ${error.message}`);
        return;
    }
});

console.log('a1enka запущен в фоновом режиме');
console.log('Для остановки нажмите Ctrl+C или закройте Terminal');