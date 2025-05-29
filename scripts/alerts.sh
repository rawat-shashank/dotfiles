#!/bin/bash

# Get today's date in YYYY-mm-dd format
JOURNAL_PATH="${HOME}/Documents/docs-vault/docs/Journal"
TODAY_DATE=$(date +%Y-%m-%d)
FILENAME="${JOURNAL_PATH}/${TODAY_DATE}.md"
HEADING="## Day planner"

# --- Dry Run Configuration ---
# Set to 'true' for dry runs (output to terminal AND audio alerts).
# Set to 'false' for live runs (ONLY audio alerts, no terminal output).
DRY_RUN=true
# --- End Dry Run Configuration ---

# --- Audio Alert Function ---
speak_alert() {
  local message="$1"
  local spd_options="-w"

  # --- CUSTOMIZE SPD-SAY OPTIONS HERE ---
  # spd_options+=" -l en-GB"
  # spd_options+=" -r -10"
  # spd_options+=" -V 90"
  # spd_options+=" -t important"
  # spd_options+=" -s female1"
  # --- END CUSTOMIZATION ---

  # Always attempt to speak unless spd-say is not found.
  # If spd-say is not found, a warning will be echoed ONLY during a dry run.
  if command -v spd-say &>/dev/null; then
    spd-say $spd_options "$message"
  else
    # Only echo this warning if in dry run mode
    if "$DRY_RUN"; then
      echo "Warning: 'spd-say' not found. Please install speech-dispatcher for audio alerts." >&2
    fi
  fi
}

# Function to echo messages to the terminal ONLY during a dry run
terminal_echo() {
  local message="$1"
  if "$DRY_RUN"; then
    echo "$message"
  fi
}


# Check if folder and file exist
if [ ! -f "$FILENAME" ]; then
  terminal_echo "Error: File '$FILENAME' not found."
  exit 1
fi

terminal_echo "--- Processing tasks for '$HEADING' in '$FILENAME' ---"

# Get current time in seconds since epoch for comparisons
CURRENT_DATE_EPOCH=$(date +%s)
CURRENT_HOUR=$(date +%H)
CURRENT_MINUTE=$(date +%M)

# Determine the start and end of the current 30-minute interval
# E.g., if 09:05, interval is 09:00 to 09:30. If 09:35, interval is 09:30 to 10:00.
if (( CURRENT_MINUTE < 30 )); then
  INTERVAL_START_HHMM="${CURRENT_HOUR}:00"
  INTERVAL_END_HHMM="${CURRENT_HOUR}:30"
else
  INTERVAL_START_HHMM="${CURRENT_HOUR}:30"
  # Handle end of day for the interval calculation
  if (( CURRENT_HOUR == 23 && CURRENT_MINUTE >= 30 )); then
    INTERVAL_END_HHMM="23:59" # Ensure it covers the full minute up to midnight
  else
    NEXT_HOUR=$(( CURRENT_HOUR + 1 ))
    printf -v NEXT_HOUR_PADDED "%02d" "$NEXT_HOUR"
    INTERVAL_END_HHMM="${NEXT_HOUR_PADDED}:00"
  fi
fi

INTERVAL_START_DATETIME_STRING="${TODAY_DATE} ${INTERVAL_START_HHMM}:00"
INTERVAL_END_DATETIME_STRING="${TODAY_DATE} ${INTERVAL_END_HHMM}:00"

# Convert interval times to seconds since epoch
INTERVAL_START_SECONDS=$(date -d "$INTERVAL_START_DATETIME_STRING" +%s 2>/dev/null)
if [[ "$INTERVAL_END_HHMM" == "23:59" ]]; then
  INTERVAL_END_SECONDS=$(date -d "${TODAY_DATE} 23:59:59" +%s 2>/dev/null)
else
  INTERVAL_END_SECONDS=$(date -d "$INTERVAL_END_DATETIME_STRING" +%s 2>/dev/null)
fi


# Initialize variables for output
DECLARE_STARTING_TASKS=()   # Tasks starting exactly at CURRENT_DATE_EPOCH
DECLARE_UPCOMING_TASKS=()   # Tasks starting after CURRENT_DATE_EPOCH but within current 30-min interval
DECLARE_ENDING_TASKS=()     # Tasks ending exactly at CURRENT_DATE_EPOCH

# Extract tasks under "## Day planner"
awk_script='
  /^## / { in_target_heading = 0 }
  $0 == "'"$HEADING"'" { in_target_heading = 1; next }
  in_target_heading { print }
'

# Read tasks line by line from awk output
while IFS= read -r line; do
  # Check if the task is NOT completed
  if [[ "$line" =~ ^-\ \[\ \].* ]]; then
    # Extract times and description
    if [[ "$line" =~ ^-\ \[.\]\ ([0-9]{2}:[0-9]{2})\ -\ ([0-9]{2}:[0-9]{2})\ (.*) ]]; then
      TASK_START_TIME_HHMM="${BASH_REMATCH[1]}"
      TASK_END_TIME_HHMM="${BASH_REMATCH[2]}"
      TASK_DESCRIPTION_RAW="${BASH_REMATCH[3]}"

      # Construct full datetime strings for parsing
      TASK_START_DATETIME_STRING="${TODAY_DATE} ${TASK_START_TIME_HHMM}:00"
      TASK_END_DATETIME_STRING="${TODAY_DATE} ${TASK_END_TIME_HHMM}:00"

      # Convert task times to seconds since epoch
      if ! TASK_START_SECONDS=$(date -d "$TASK_START_DATETIME_STRING" +%s 2>/dev/null); then continue; fi
      if ! TASK_END_SECONDS=$(date -d "$TASK_END_DATETIME_STRING" +%s 2>/dev/null); then continue; fi

      # --- Process Task Conditions ---

      # 1. Task is STARTING exactly now (e.g., script runs at 09:00, task starts at 09:00)
      if (( TASK_START_SECONDS == CURRENT_DATE_EPOCH )); then
          DECLARE_STARTING_TASKS+=("$TASK_DESCRIPTION_RAW")
      fi

      # 2. Task is UPCOMING within the current 30-minute interval
      #    (e.g., script runs at 09:00, task starts at 09:20)
      #    - Must start AFTER the current time.
      #    - Must start AFTER or AT the calculated start of the current 30-min interval.
      #    - Must start BEFORE the calculated end of the current 30-min interval.
      if (( TASK_START_SECONDS > CURRENT_DATE_EPOCH )) && \
         (( TASK_START_SECONDS >= INTERVAL_START_SECONDS )) && \
         (( TASK_START_SECONDS < INTERVAL_END_SECONDS )); then
          DECLARE_UPCOMING_TASKS+=("$TASK_DESCRIPTION_RAW (upcoming at ${TASK_START_TIME_HHMM})")
      fi

      # 3. Task is ENDING exactly now (always announce endings)
      if (( TASK_END_SECONDS == CURRENT_DATE_EPOCH )); then
          DECLARE_ENDING_TASKS+=("$TASK_DESCRIPTION_RAW")
      fi

    fi
  fi
done < <(awk "$awk_script" "$FILENAME")


# --- Output Results and Audio Alerts ---

terminal_echo ""

# Tasks ending exactly now
if [ ${#DECLARE_ENDING_TASKS[@]} -gt 0 ]; then
    terminal_echo "--- Tasks Concluding at $(date -d "@$CURRENT_DATE_EPOCH" +%H:%M) ---"
    for task_desc in "${DECLARE_ENDING_TASKS[@]}"; do
        terminal_echo "  - [ ] ${task_desc} (ends now)"
        speak_alert "Task: ${task_desc} is concluding."
    done
fi

# Tasks starting exactly now
if [ ${#DECLARE_STARTING_TASKS[@]} -gt 0 ]; then
    terminal_echo "--- Tasks Beginning at $(date -d "@$CURRENT_DATE_EPOCH" +%H:%M) ---"
    for task_desc in "${DECLARE_STARTING_TASKS[@]}"; do
        terminal_echo "  - [ ] ${task_desc} (starts now)"
        speak_alert "Task: ${task_desc} is starting now."
    done
fi

# Upcoming tasks within the current 30-minute interval
if [ ${#DECLARE_UPCOMING_TASKS[@]} -gt 0 ]; then
    terminal_echo ""
    terminal_echo "--- Upcoming Tasks for this 30-minute interval ---"
    for task_desc in "${DECLARE_UPCOMING_TASKS[@]}"; do
        terminal_echo "  - [ ] ${task_desc}"
        speak_alert "Upcoming: ${task_desc}."
    done
fi


# Final message if no relevant tasks were found
if [ ${#DECLARE_STARTING_TASKS[@]} -eq 0 ] && \
   [ ${#DECLARE_ENDING_TASKS[@]} -eq 0 ] && \
   [ ${#DECLARE_UPCOMING_TASKS[@]} -eq 0 ]; then
    terminal_echo ""
    terminal_echo "No tasks found starting, ending, or upcoming within this 30-minute interval."
fi

terminal_echo "-------------------------------------"
