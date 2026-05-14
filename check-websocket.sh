#!/bin/bash

# Скрипт для проверки работоспособности WebSocket синхронизации

echo "🚀 Проверка работоспособности WebSocket синхронизации"
echo "=================================================="
echo ""

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Проверка 1: Backend доступен
echo "📋 Проверка 1: Backend доступен на localhost:5001"
if curl -s http://localhost:5001/auth/login -X POST -H "Content-Type: application/json" -d '{"email":"test@test.com","password":"test"}' > /dev/null; then
    echo -e "${GREEN}✅ Backend работает${NC}"
else
    echo -e "${RED}❌ Backend не доступен${NC}"
    echo "   Запустите: docker compose up -d"
    exit 1
fi
echo ""

# Проверка 2: Frontend доступен
echo "📋 Проверка 2: Frontend доступен на localhost:8080"
if curl -s http://localhost:8080 | grep -q "Project" > /dev/null; then
    echo -e "${GREEN}✅ Frontend работает${NC}"
else
    echo -e "${RED}❌ Frontend не доступен${NC}"
    echo "   Запустите: docker compose up -d"
    exit 1
fi
echo ""

# Проверка 3: PostgreSQL доступна
echo "📋 Проверка 3: PostgreSQL доступна"
if docker exec lab5-6-postgres-1 pg_isready -U postgres > /dev/null 2>&1; then
    echo -e "${GREEN}✅ PostgreSQL работает${NC}"
else
    echo -e "${RED}❌ PostgreSQL не доступна${NC}"
    echo "   Запустите: docker compose up -d postgres"
    exit 1
fi
echo ""

# Проверка 4: Регистрация нового пользователя
echo "📋 Проверка 4: Регистрация нового пользователя"
REGISTER_RESPONSE=$(curl -s http://localhost:5001/auth/register \
    -X POST \
    -H "Content-Type: application/json" \
    -d '{
        "username":"testuser_'$(date +%s)'",
        "email":"test_'$(date +%s)'@example.com",
        "password":"password123"
    }')

TOKEN=$(echo $REGISTER_RESPONSE | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -n "$TOKEN" ]; then
    echo -e "${GREEN}✅ Регистрация работает${NC}"
    echo "   Токен: ${TOKEN:0:20}..."
else
    echo -e "${RED}❌ Регистрация не работает${NC}"
    echo "   Ответ: $REGISTER_RESPONSE"
    exit 1
fi
echo ""

# Проверка 5: Создание задачи через API
echo "📋 Проверка 5: Создание задачи через API"
TASK_RESPONSE=$(curl -s http://localhost:5001/tasks \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "title":"Тестовая задача",
        "description":"Задача для проверки WebSocket",
        "priority":"medium"
    }')

TASK_ID=$(echo $TASK_RESPONSE | grep -o '"id":[0-9]*' | cut -d':' -f2)

if [ -n "$TASK_ID" ]; then
    echo -e "${GREEN}✅ Создание задачи работает${NC}"
    echo "   Задача ID: $TASK_ID"
else
    echo -e "${RED}❌ Создание задачи не работает${NC}"
    echo "   Ответ: $TASK_RESPONSE"
    exit 1
fi
echo ""

# Проверка 6: Получение списка задач
echo "📋 Проверка 6: Получение списка задач"
TASKS=$(curl -s http://localhost:5001/tasks \
    -H "Authorization: Bearer $TOKEN" \
    | grep -o '"title"' | wc -l)

if [ $TASKS -gt 0 ]; then
    echo -e "${GREEN}✅ Получение задач работает${NC}"
    echo "   Всего задач: $TASKS"
else
    echo -e "${RED}❌ Получение задач не работает${NC}"
    exit 1
fi
echo ""

# Проверка 7: Обновление задачи
echo "📋 Проверка 7: Обновление задачи"
UPDATE_RESPONSE=$(curl -s http://localhost:5001/tasks/$TASK_ID \
    -X PUT \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "title":"Обновленная задача",
        "done":false
    }')

if echo $UPDATE_RESPONSE | grep -q "Updated\|message"; then
    echo -e "${GREEN}✅ Обновление задачи работает${NC}"
else
    echo -e "${RED}❌ Обновление задачи не работает${NC}"
    echo "   Ответ: $UPDATE_RESPONSE"
    exit 1
fi
echo ""

# Проверка 8: Удаление задачи
echo "📋 Проверка 8: Удаление задачи"
DELETE_RESPONSE=$(curl -s http://localhost:5001/tasks/$TASK_ID \
    -X DELETE \
    -H "Authorization: Bearer $TOKEN")

if echo $DELETE_RESPONSE | grep -q "Deleted\|message"; then
    echo -e "${GREEN}✅ Удаление задачи работает${NC}"
else
    echo -e "${RED}❌ Удаление задачи не работает${NC}"
    echo "   Ответ: $DELETE_RESPONSE"
    exit 1
fi
echo ""

# Финальное резюме
echo "=================================================="
echo -e "${GREEN}✅ ВСЕ ПРОВЕРКИ ПРОЙДЕНЫ!${NC}"
echo ""
echo "🎯 Дальнейшие действия:"
echo "1. Откройте два браузера с http://localhost:8080"
echo "2. Войдите в один и тот же аккаунт"
echo "3. Создавайте задачи в одном браузере"
echo "4. Наблюдайте как они синхронизируются на втором"
echo ""
echo "📝 Для полного тестирования смотрите TESTING_GUIDE.md"
echo ""
