#!/bin/bash
# ./scripts/script.sh <каталог> <N_оставить_обычно> <N_заархивировать>
# Пример: ./scripts/script.sh ./test_dir/dag1 3 3
# Оставит 3 самых новых как есть + 3 следующих по новизне заархивирует, остальное удалит

source $4

dir="$1"
keep_plain="$2"   # сколько самых новых оставить как есть
keep_archived="$3" # сколько следующих по новизне заархивировать

if [ $# -lt 3 ] || [ $# -gt 4 ]; then
    echo "Использование: $0 <каталог> <N_обычно> <N_в_архив> </path/to/.env>"
    echo "Пример: $0 ./test_dir/dag1 3 3 /var/lib/script/.env"
    exit 1
fi

if ! [[ "$keep_plain" =~ ^[0-9]+$ ]] || [ "$keep_plain" -le 0 ] || \
   ! [[ "$keep_archived" =~ ^[0-9]+$ ]] || [ "$keep_archived" -le -1 ]; then
    echo "Ошибка: аргументы 2 и 3 — положительные числа"
    exit 1
fi

# Формируем список (самые старые — в начале, самые новые — в конце)
mapfile -t -d '' raw_items < <(
    find "$dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\0' \
    | grep -zE "$GREP_REGEXP" \
    | sed -zE "$SED1_REGEXP" \
    | sort -rzV \
    | sed -zE "$SED2_REGEXP"
)

printf -v KEEP_LIST '%s\n' "${raw_items[@]}"
KEEP_LIST=${KEEP_LIST%$'\n'}

mapfile -t items <<< "$KEEP_LIST"

total=${#items[@]}

if [ "$total" -eq 0 ]; then
    echo "В $dir нет подходящих файлов/папок"
    exit 0
fi

echo "В $dir найдено $total элементов"

needed=$((keep_plain + keep_archived))

if [ "$total" -le "$needed" ]; then
    echo "Элементы ($total) ≤ нужного ($needed) — ничего не трогаем"
    exit 0
fi

echo "Оставляем $keep_plain самых новых как есть + $keep_archived следующих заархивируем"
echo "Удаляем $((total - needed)) самых старых"

# Один цикл по всему массиву — удобно и читаемо
for (( i=0; i<total; i++ )); do
    item="$dir/${items[i]}"

    # Самые новые — оставляем как есть
    if [ "$i" -lt "$keep_plain" ]; then
        echo "Оставляю: $item"
        continue
    fi

    # Следующие N — архивируем (если ещё не заархивированы)
    if [ "$i" -lt $((keep_plain + keep_archived)) ]; then
        archive="$item.tar.gz"

        if [[ "${items[i]}" == *.tar.gz ]]; then
            echo "Пропускаю (уже заархивировано): $item"
        else
            echo "Архивирую: $item → $archive"
            tar -czf "$archive" -C "$dir" "${items[i]}" && \
                echo "Архивировано: $archive" || \
                echo "Ошибка архивации $item"

            # Удаляем исходник после успешной архивации
            rm -rf "$item"
        fi
        continue
    fi

    # Всё остальное — самые старые — удаляем
    echo "Удаляю (старое): $item"
    rm -rf "$item"
done

echo "Готово!"
