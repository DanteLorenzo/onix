#!/bin/bash

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

LOGO='
      ____    _____    _____      ____________ _____       _____ 
  ____\_  \__|\    \   \    \    /            \\    \     /    / 
 /     /     \\\    \   |    |  |\___/\  \\___/|\    |   |    /  
/     /\      |\\    \  |    |   \|____\  \___|/ \    \ /    /   
|     |  |     | \|    \ |    |         |  |       \    |    /    
|     |  |     |  |     \|    |    __  /   / __    /    |    \    
|     | /     /| /     /\      \  /  \/   /_/  |  /    /|\    \   
|\     \_____/ |/_____/ /______/||____________/| |____|/ \|____|  
| \_____\   | /|      | |     | ||           | / |    |   |    |  
 \ |    |___|/ |______|/|_____|/ |___________|/  |____|   |____|  
  \|____|                                                         
'

SCRIPTS_DIR="scripts"
mapfile -t SCRIPTS_ARR < <(find "$SCRIPTS_DIR" -maxdepth 1 -type f -perm +111 | sort)
SCRIPTS_COUNT=${#SCRIPTS_ARR[@]}
[ "$SCRIPTS_COUNT" -eq 0 ] && echo "No executable scripts found in $SCRIPTS_DIR" && exit 1

for ((i=0; i<SCRIPTS_COUNT; i++)); do
  SELECTED[$i]=0
done

CUR=0

draw() {
  clear
  printf "${CYAN}%s${NC}\n\n" "$LOGO"
  echo "Select scripts to run (arrows: move, space: select, enter: run):"
  # CheckAll пункт
  if [ "$CUR" -eq 0 ]; then
    printf "${YELLOW}>"
  else
    printf " "
  fi
  all_selected=1
  for idx in $(seq 0 $((SCRIPTS_COUNT-1))); do
    if [ "${SELECTED[$idx]}" -eq 0 ]; then
      all_selected=0
      break
    fi
  done
  if [ "$all_selected" -eq 1 ]; then
    printf "[${GREEN}x${NC}] "
  else
    printf "[ ] "
  fi
  printf "CheckAll\n"
  # Список скриптов
  for idx in $(seq 0 $((SCRIPTS_COUNT-1))); do
    if [ "$CUR" -eq $((idx+1)) ]; then
      printf "${YELLOW}>"
    else
      printf " "
    fi
    if [ "${SELECTED[$idx]}" -eq 1 ]; then
      printf "[${GREEN}x${NC}] "
    else
      printf "[ ] "
    fi
    script_name=$(basename "${SCRIPTS_ARR[$idx]}")
    printf "%s\n" "$script_name"
  done
}

# Чтение клавиш
while :; do
  draw
  read -rsn1 key
  if [ "$key" = $'\x1b' ]; then
    read -rsn2 -t 0.1 key2
    key="$key$key2"
    case "$key" in
      $'\x1b[A') # up
        CUR=$(( (CUR-1+SCRIPTS_COUNT+1)%(SCRIPTS_COUNT+1) ))
        ;;
      $'\x1b[B') # down
        CUR=$(( (CUR+1)%(SCRIPTS_COUNT+1) ))
        ;;
    esac
  elif [ "$key" = " " ]; then
    if [ "$CUR" -eq 0 ]; then
      # CheckAll
      all_selected=1
      for idx in $(seq 0 $((SCRIPTS_COUNT-1))); do
        if [ "${SELECTED[$idx]}" -eq 0 ]; then
          all_selected=0
          break
        fi
      done
      new_val=1
      [ "$all_selected" -eq 1 ] && new_val=0
      for idx in $(seq 0 $((SCRIPTS_COUNT-1))); do
        SELECTED[$idx]=$new_val
      done
    else
      SELECTED[$((CUR-1))]=$((1 - ${SELECTED[$((CUR-1))]}))
    fi
  elif [ "$key" = "" ]; then
    break
  fi
done

# Собираем выбранные
TO_RUN=""
for idx in $(seq 0 $((SCRIPTS_COUNT-1))); do
  if [ "${SELECTED[$idx]}" -eq 1 ]; then
    TO_RUN="$TO_RUN ${SCRIPTS_ARR[$idx]}"
  fi
done

[ -z "$TO_RUN" ] && echo "Nothing selected." && exit 0

# Запуск с прогресс-баром и логами
i=1
total=$(echo "$TO_RUN" | wc -w)
for script in $TO_RUN; do
  clear
  printf "${CYAN}%s${NC}\n\n" "$LOGO"
  printf "Progress: ["
  for j in $(seq 1 $total); do
    if [ "$j" -lt "$i" ]; then
      printf "${GREEN}#${NC}"
    elif [ "$j" -eq "$i" ]; then
      printf "${YELLOW}>${NC}"
    else
      printf " "
    fi
  done
  printf "] $i/$total\n"
  printf "${BLUE}Running: %s${NC}\n\n" "$script"
  sh "$script"
  i=$((i+1))
  printf "\n${CYAN}Press any key for next...${NC}"
  read -rsn1
done

clear
printf "${CYAN}%s${NC}\n\n" "$LOGO"
printf "${GREEN}All scripts finished!${NC}\n"
