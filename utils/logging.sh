#!/bin/bash

# Цветовые коды
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для информационных сообщений
log_info() {
  echo -e "${CYAN}[INFO] $1${NC}"
}

# Функция для успешных операций
log_success() {
  echo -e "${GREEN}[SUCCESS] $1${NC}"
}

# Функция для ошибок
log_error() {
  echo -e "${RED}[ERROR] $1${NC}"
}

# Функция для предупреждений
log_warning() {
  echo -e "${YELLOW}[WARNING] $1${NC}"
}