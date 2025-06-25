#!/bin/bash

# Colors
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
# Make all files in scripts executable
chmod -f +x "$SCRIPTS_DIR"/* 2>/dev/null
mapfile -t SCRIPTS_ARR < <(find "$SCRIPTS_DIR" -maxdepth 1 -type f -perm /111 | sort)
SCRIPTS_COUNT=${#SCRIPTS_ARR[@]}
[ "$SCRIPTS_COUNT" -eq 0 ] && echo "No executable scripts found in $SCRIPTS_DIR" && exit 1

# Initialize selection array
for ((i=0; i<SCRIPTS_COUNT; i++)); do
  SELECTED[$i]=0
done

CUR=0

# Initial clear
clear

# Draw the UI

draw() {
  printf "\033[H"
  printf "${CYAN}%s${NC}\n\n" "$LOGO"
  echo "Select scripts to run (arrows: move, space: select, enter: run):"
  # CheckAll item
  if [ "$CUR" -eq 0 ]; then
    printf "${YELLOW}>${NC}"
  else
    printf " "
  fi
  all_selected=1
  for idx in "${!SELECTED[@]}"; do
    if [[ ${SELECTED[$idx]} -eq 0 ]]; then
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
  # Script list
  for idx in "${!SCRIPTS_ARR[@]}"; do
    if [ "$CUR" -eq $((idx+1)) ]; then
      printf "${YELLOW}>${NC}"
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

# Keyboard input loop
while :; do
  draw
  IFS= read -rsn1 key
  if [[ $key == $'\x1b' ]]; then
    read -rsn2 -t 0.1 key2
    key="$key$key2"
    case "$key" in
      $'\x1b[A') CUR=$(( (CUR-1+SCRIPTS_COUNT+1)%(SCRIPTS_COUNT+1) )) ;;
      $'\x1b[B') CUR=$(( (CUR+1)%(SCRIPTS_COUNT+1) )) ;;
    esac
  elif [[ $key == " " ]]; then
    if (( CUR == 0 )); then
      # Toggle all
      all_selected=1
      for idx in "${!SELECTED[@]}"; do
        if [[ ${SELECTED[$idx]} -eq 0 ]]; then
          all_selected=0
          break
        fi
      done
      new_val=$((1-all_selected))
      for idx in "${!SELECTED[@]}"; do
        SELECTED[$idx]=$new_val
      done
    elif (( CUR > 0 )); then
      # Toggle single
      idx=$((CUR-1))
      SELECTED[$idx]=$((1 - ${SELECTED[$idx]}))
    fi
  elif [[ $key == "" ]]; then
    break
  fi
done

# Collect selected scripts
TO_RUN=""
for idx in "${!SCRIPTS_ARR[@]}"; do
  if [ "${SELECTED[$idx]}" -eq 1 ]; then
    if [ -z "$TO_RUN" ]; then
      TO_RUN="${SCRIPTS_ARR[$idx]}"
    else
      TO_RUN="$TO_RUN ${SCRIPTS_ARR[$idx]}"
    fi
  fi
done

[ -z "$TO_RUN" ] && echo "Nothing selected." && exit 0

# After script selection, prompt for sudo password and cache it
sudo -v || { echo "Sudo authentication failed."; exit 1; }
# Start background process to keep sudo session alive
while true; do sudo -n true; sleep 60; done 2>/dev/null &
SUDO_PID=$!

# Run with progress bar and logs
success=0
fail=0
i=1
bar_width=30
total=$(echo "$TO_RUN" | wc -w)
for script in $TO_RUN; do
  clear
  printf "${CYAN}%s${NC}\n\n" "$LOGO"
  # Progress bar
  printf "Progress: ["
  filled=$(( (i-1)*bar_width/total ))
  for j in $(seq 1 $bar_width); do
    if [ "$j" -le "$filled" ]; then
      printf "${GREEN}#${NC}"
    elif [ "$j" -eq $((filled+1)) ]; then
      printf "${YELLOW}>${NC}"
    else
      printf " "
    fi
  done
  printf "] $i/$total\n"
  printf "${BLUE}Running: %s${NC}\n\n" "$script"
  read -p "Press Enter to start this script..." dummy
  sh "$script"
  if [ $? -eq 0 ]; then
    success=$((success+1))
  else
    fail=$((fail+1))
  fi
  i=$((i+1))
done

# Kill the background sudo keeper
kill $SUDO_PID

clear
printf "${CYAN}%s${NC}\n\n" "$LOGO"
printf "${GREEN}All scripts finished!${NC}\n"
printf "\nStatistics:\n"
printf "  Successful: ${GREEN}%d${NC}\n" "$success"
printf "  Failed:     ${RED}%d${NC}\n" "$fail"
printf "  Total:      ${CYAN}%d${NC}\n" "$total"
