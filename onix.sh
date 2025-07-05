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

# Run with progress bar and logs
success=0
fail=0
i=1
bar_width=30
total=$(echo "$TO_RUN" | wc -w)

# Check if we're running the sudo script
SUDO_SCRIPT_PRESENT=0
for script in $TO_RUN; do
  if [[ "$(basename "$script")" == "00-sudo.sh" ]]; then
    SUDO_SCRIPT_PRESENT=1
    break
  fi
done

# If sudo script is present, run it first separately
if [ $SUDO_SCRIPT_PRESENT -eq 1 ]; then
  clear
  printf "${CYAN}%s${NC}\n\n" "$LOGO"
  printf "${BLUE}Running sudo configuration first...${NC}\n\n"
  
  # Find the sudo script
  for script in $TO_RUN; do
    if [[ "$(basename "$script")" == "00-sudo.sh" ]]; then
      SUDO_SCRIPT="$script"
      break
    fi
  done
  
  # Try pkexec first (graphical sudo), then fall back to sudo
  if command -v pkexec >/dev/null; then
    if pkexec bash "$SUDO_SCRIPT"; then
      printf "${GREEN}Successfully configured sudo privileges${NC}\n"
      success=$((success+1))
    else
      printf "${RED}Failed to configure sudo privileges${NC}\n"
      fail=$((fail+1))
    fi
  else
    if sudo bash "$SUDO_SCRIPT"; then
      printf "${GREEN}Successfully configured sudo privileges${NC}\n"
      success=$((success+1))
    else
      printf "${RED}Failed to configure sudo privileges${NC}\n"
      fail=$((fail+1))
    fi
  fi
  
  printf "${YELLOW}Press Enter to continue with other scripts...${NC}\n"
  read dummy
fi

# Now run the remaining scripts
for script in $TO_RUN; do
  # Skip the sudo script if we already ran it
  [[ "$(basename "$script")" == "00-sudo.sh" ]] && continue
  
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
  
  # Run the script with sudo if it's not the sudo script
  if sudo -n true 2>/dev/null; then
    # We have sudo privileges, use them
    sudo bash "$script"
  else
    # Try without sudo
    bash "$script"
  fi
  
  if [ $? -eq 0 ]; then
    success=$((success+1))
  else
    fail=$((fail+1))
  fi
  
  printf "${YELLOW}Press Enter to continue...${NC}\n"
  read dummy
  i=$((i+1))
done

clear
printf "${CYAN}%s${NC}\n\n" "$LOGO"
printf "${GREEN}All scripts finished!${NC}\n"
printf "\nStatistics:\n"
printf "  Successful: ${GREEN}%d${NC}\n" "$success"
printf "  Failed:     ${RED}%d${NC}\n" "$fail"
printf "  Total:      ${CYAN}%d${NC}\n" "$total"