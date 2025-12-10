#!/usr/bin/env bash
set -e

LOG_DIR="/path/to/logs"
cd "$LOG_DIR" || exit 1

# pattern: run_id=scheduled__2025-05-12T08:00:00+00:00
#          run_id=manual__2025-05-16T15:57:06.926101+00:00
PATTERN='^run_id=\(scheduled\|manual\)__.*$'

# Список директорий по маске
dirs=( $(find . -maxdepth 1 -type d -regextype posix-extended -regex "./${PATTERN}" | sed 's|^\./||') )

count=${#dirs[@]}
echo "Найдено директорий: $count"

# Если <=6 — ничего не делаем
if (( count <= 6 )); then
    echo "Директорий 6 или меньше — ничего не удаляем и не архивируем."
    exit 0
fi

echo "Обнаружены директории:"
printf '%s\n' "${dirs[@]}"

echo "Извлекаем даты…"

# Построим массив: timestamp|dirname
tempfile=$(mktemp)

for d in "${dirs[@]}"; do
    # вытащить дату после "__"
    date_part=$(echo "$d" | sed -E 's/^run_id=(scheduled|manual)__//')

    # нормализуем до понятного формата
    # BSD/GNU date отличаются, поэтому используем безопасный вариант
    ts=$(date -d "$date_part" +%s 2>/dev/null || \
         gdate -d "$date_part" +%s 2>/dev/null || \
         echo "")
    
    if [[ -z "$ts" ]]; then
        echo "⚠ Не удалось преобразовать дату: $d"
        continue
    fi

    echo "${ts}|${d}" >> "$tempfile"
done

echo "Сортируем по времени…"

sorted=($(sort -n "$tempfile"))
rm "$tempfile"

# Теперь отсортированные по дате директории
sorted_dirs=()
for item in "${sorted[@]}"; do
    sorted_dirs+=( "$(echo "$item" | cut -d'|' -f2)" )
done

echo "Отсортированные директории:"
printf '%s\n' "${sorted_dirs[@]}"

# Определяем группы:
#   последние 3   → оставить
#   предыдущие 3  → архивировать
#   остальные     → удалить

total=${#sorted_dirs[@]}

keep=("${sorted_dirs[@]: -3}")
archive=("${sorted_dirs[@]: -6:3}")
delete=("${sorted_dirs[@]:0: total-6}")

echo "--- Оставляем (последние 3):"
printf '%s\n' "${keep[@]}"

echo "--- Архивируем (предыдущие 3):"
printf '%s\n' "${archive[@]}"

echo "--- Удаляем (остальные):"
printf '%s\n' "${delete[@]}"

# Архивирование
archive_file="archived_$(date +%Y%m%d_%H%M%S).tar.gz"
if (( ${#archive[@]} > 0 )); then
    tar -czf "$archive_file" "${archive[@]}"
    echo "Создан архив: $archive_file"
fi

# Удаление
for d in "${delete[@]}"; do
    rm -rf "$d"
    echo "Удалено: $d"
done

echo "Готово."
