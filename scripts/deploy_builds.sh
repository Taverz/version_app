#!/bin/bash

# Дайте права на выполнение:
# chmod +x deploy_builds.sh
# Запустите скрипт:
# ./deploy_builds.sh
# ./deploy_builds.sh -p 123 -v 1.2.3 -s http://your-server
# sh deploy_builds.sh -p 123 -v 1.2.3 -s http://127.0.0.1:8923

LOG_FILE="deploy_$(date +%Y-%m-%d_%H-%M-%S).log"
exec &> >(tee -a "$LOG_FILE")
echo "Логирование в файл: $LOG_FILE и вывод в консоль"

while getopts ":p:v:s:" opt; do
  case $opt in
    p) PROJECT_ID="$OPTARG" ;;
    v) VERSION_NAME="$OPTARG" ;;
    s) SERVER_URL="$OPTARG" ;;
    \?) echo "Неверный аргумент: -$OPTARG" >&2; exit 1 ;;
  esac
done

# Конфигурация
SERVER_URL="http://127.0.0.1:8923"  # Замените на ваш URL сервера
PROJECT_ID="1"         # ID вашего проекта
VERSION_NAME="1.0.2"                 # Версия сборки
BUILD_DIR="../build"                    # Папка с билдами

# Функция для отправки файла на сервер
upload_build() {
  local file_path=$1
  local platform=$2
  
  if [ ! -f "$file_path" ]; then
    echo "⚠️ Файл не найден: $file_path"
    return 1
  fi

  echo "📤 Загружаем $platform сборку: $file_path"

  # Определяем MIME-тип
  if [[ "$file_path" == *.apk ]]; then
    mime_type="application/vnd.android.package-archive"
  elif [[ "$file_path" == *.zip ]]; then
    mime_type="application/zip"
  else
    mime_type="application/octet-stream"
  fi

  # Отправка файла с помощью curl
  response=$(curl -s -X POST \
    -H "Content-Type: multipart/form-data" \
    -F "projectId=$PROJECT_ID" \
    -F "versionName=$VERSION_NAME-$platform" \
    -F "platforms=$platform" \
    -F "file=@$file_path;type=$mime_type" \
    "$SERVER_URL/versions")

  # Проверяем наличие поля id в ответе вместо status
  if echo "$response" | grep -q '"id":'; then
    download_url=$(echo "$response" | grep -o '"downloadURL":"[^"]*"' | cut -d'"' -f4)
    echo "✅ Успешно загружено!"
    echo "🔗 URL: $download_url"
  else
    echo "❌ Ошибка загрузки: $response"
  fi
}

# Поиск Android сборки
find_android_build() {
  local apk_file=$(find "$BUILD_DIR/app/outputs/flutter-apk" -name "*.apk" -print -quit)
  if [ -n "$apk_file" ]; then
    upload_build "$apk_file" "android"
  else
    echo "⚠️ Android сборка не найдена"
  fi
}

# Создание и отправка Web сборки
prepare_web_build() {
  local web_dir="$BUILD_DIR/web"
  local zip_file="$BUILD_DIR/web_$VERSION_NAME.zip"
  
  if [ ! -d "$web_dir" ]; then
    echo "⚠️ Web сборка не найдена"
    return
  fi

  echo "📦 Архивируем web сборку..."
  if command -v zip &> /dev/null; then
    (cd "$web_dir" && zip -r "../web_$VERSION_NAME.zip" .)
    upload_build "$zip_file" "web"
    rm "$zip_file"
  else
    echo "❌ Команда 'zip' не найдена, не могу создать архив"
  fi
}

# Основной скрипт
echo "🚀 Начинаем загрузку сборок на сервер"
echo "🔍 Ищем сборки в папке $BUILD_DIR"

find_android_build
prepare_web_build

echo "✅ Готово!"