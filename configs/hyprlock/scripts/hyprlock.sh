#!/bin/bash

# Путь до временного конфига hyprpaper
HYPRPAPER_CONF="$HOME/.config/hyprpaper/tmp.conf"

# Путь до конфигурации Hyprlock
HYPRLOCK_CONF="$HOME/.config/hyprlock/hyprlock.conf"

# Папка конфигурации
CONFIG_DIR="$HOME/.config/hyprlock"
BLURBOX="$CONFIG_DIR/blurbox.png"

# Получаем путь к обоям из hyprpaper config
WALLPAPER=$(grep -m1 '^wallpaper' "$HYPRPAPER_CONF" | cut -d',' -f2)

# Проверка на существование файла обоев
if [ ! -f "$WALLPAPER" ]; then
  echo "❌ Обои не найдены: $WALLPAPER"
  exit 1
fi

# Генерация размытого квадрата
magick convert "$WALLPAPER" \
    -resize 1920x1080 \
    -gravity center \
    -crop 900x900+0+0 +repage \
    -blur 0x8 \
    -fill white -colorize 10% \
    "$BLURBOX"

# Автоматически подменяем путь к background.path в hyprlock.conf
# (на случай если ты хочешь, чтобы фон тоже совпадал с текущими обоями)
sed -i "s|^\(path *= *\).*|\\1$WALLPAPER|" "$HYPRLOCK_CONF"

# Запуск hyprlock с конфигом
hyprlock -c "$HYPRLOCK_CONF"
