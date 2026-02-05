#!/bin/bash
# ./scripts/script.sh <каталог> <N_оставить_директорий> <N_оставить_архивов>
# Пример: ./scripts/script.sh ./test_dir/dag1 3 7
# Оставит 3 самых новых директории + заархивирует старейшие директории, затем оставит всего 7 архивов (удалив старейшие архивы если нужно)

source "$4"

dir="$1"
keep_plain="$2"
keep_archived="$3"

if [ $# -lt 3 ] || [ $# -gt 4 ]; then
  echo "Использование: $0 <каталог> <N_директорий> <N_архивов> </path/to/.env>"
  echo "Пример: $0 ./test_dir/dag1 3 7 /var/lib/script/.env"
  exit 1
fi
if ! [[ "$keep_plain" =~ ^[0-9]+$ ]] || [ "$keep_plain" -le 0 ] || \
   ! [[ "$keep_archived" =~ ^[0-9]+$ ]] || [ "$keep_archived" -le -1 ]; then
  echo "Ошибка: аргументы 2 и 3 — положительные числа"
  exit 1
fi

# Функция для формирования отсортированного списка (новые в начале, старые в конце)
get_sorted_list() {
  local type_filter="$1"  # '-type d' или '-type f'
  mapfile -t -d '' raw_items < <(
    find "$dir" -mindepth 1 -maxdepth 1 $type_filter -printf '%f\0' |
    grep -zE "$GREP_REGEXP" |
    sed -zE "$SED1_REGEXP" |
    sort -rzV -k1,1 |
    sed -zE "$SED2_REGEXP"
  )
  printf -v LIST '%s\n' "${raw_items[@]}"
  LIST=${LIST%$'\n'}
  mapfile -t items <<< "$LIST"
  echo "${items[@]}"
}

# Сначала обрабатываем директории
echo "Анализируем директории..."
dirs=($(get_sorted_list "-type d"))  # Новые в начале
dirs_total=${#dirs[@]}
if [ "$dirs_total" -eq 0 ]; then
  echo "Нет директорий в $dir"
else
  echo "Найдено $dirs_total директорий"
  if [ "$dirs_total" -gt "$keep_plain" ]; then
    num_to_archive=$((dirs_total - keep_plain))
    echo "Оставляем $keep_plain самых новых директорий, архивируем $num_to_archive старейших"
    for (( i=0; i<keep_plain; i++ )); do
      item="$dir/${dirs[i]}"
      echo "Оставляю директорию: $item"
    done
    for (( i=keep_plain; i<dirs_total; i++ )); do
      item="$dir/${dirs[i]}"
      archive="$item.tar.gz"
      echo "Архивирую старую директорию: $item → $archive"
      tar -czf "$archive" -C "$dir" "${dirs[i]}" && \
      echo "Архивировано: $archive" || \
      echo "Ошибка архивации $item"
      rm -rf "$item"
    done
  else
    echo "Директорий ($dirs_total) ≤ нужного ($keep_plain) — ничего не архивируем"
  fi
fi

# Теперь обрабатываем архивы (включая новые от архивации)
echo "Анализируем архивы..."
archives=($(get_sorted_list "-type f"))  # Новые в начале, после возможной архивации выше
archives_total=${#archives[@]}
if [ "$archives_total" -eq 0 ]; then
  echo "Нет архивов в $dir"
else
  echo "Найдено $archives_total архивов"
  if [ "$archives_total" -gt "$keep_archived" ]; then
    num_to_delete=$((archives_total - keep_archived))
    echo "Оставляем $keep_archived самых новых архивов, удаляем $num_to_delete старейших"
    for (( i=0; i<keep_archived; i++ )); do
      item="$dir/${archives[i]}"
      echo "Оставляю архив: $item"
    done
    for (( i=keep_archived; i<archives_total; i++ )); do
      item="$dir/${archives[i]}"
      echo "Удаляю старый архив: $item"
      rm -f "$item"
    done
  else
    echo "Архивов ($archives_total) ≤ нужного ($keep_archived) — ничего не удаляем"
  fi
fi

# Финальный подсчёт
final_dirs=$(find "$dir" -mindepth 1 -maxdepth 1 -type d | wc -l)
final_archives=$(find "$dir" -mindepth 1 -maxdepth 1 -type f | wc -l)
echo "Готово! Итого: $final_dirs директорий + $final_archives архивов = $((final_dirs + final_archives)) сущностей"
