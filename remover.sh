#!/bin/bash

BASE_DIR="/path/to/your/dir"

# Ищем все директории формата run_id=*
DIRS=($(find "$BASE_DIR" -maxdepth 1 -type d -name "run_id=*" | sort))

COUNT=${#DIRS[@]}

echo "Найдено директорий: $COUNT"

# Если директорий <= 6, ничего не делаем
if [ "$COUNT" -le 6 ]; then
    echo "Директорий 6 или меньше — ничего удалять/архивировать не будем."
    exit 0
fi

echo "Полный список:"
printf "%s\n" "${DIRS[@]}"

echo
echo "Сортируем директории по дате…"

# Извлекаем timestamps и сортируем
SORTED_DIRS=$(for d in "${DIRS[@]}"; do
    TS=$(echo "$d" | sed 's/.*__//')   # часть после __ (дата)
    echo "$TS $d"
done | sort | awk '{print $2}')

echo "Отсортированный список:"
echo "$SORTED_DIRS"

# Преобразуем обратно в массив
mapfile -t SORTED <<< "$SORTED_DIRS"

# Старые директории (которые нужно удалить), сохраняем первые N-6
TO_DELETE=("${SORTED[@]:0:$((${#SORTED[@]} - 6))}")

echo
echo "Будут удалены:"
printf "%s\n" "${TO_DELETE[@]}"

# Удаление (раскомментируй после проверки)
# for d in "${TO_DELETE[@]}"; do
#     rm -rf "$d"
# done

echo "Готово."
