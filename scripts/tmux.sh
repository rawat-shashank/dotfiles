#!/bin/bash

# Script to open a tmux session with a split window, both starting in a specified path.
# The right pane will automatically open nvim.
# Checks if the session exists and attaches if it does.

# Default split size (percentage of window width)
DEFAULT_SPLIT_SIZE="80"

# Check if a path argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <path> [split_size]"
  echo "  <path>: The directory to start the tmux session in."
  echo "  [split_size]: Optional. Percentage width for the left pane (default: $DEFAULT_SPLIT_SIZE)."
  exit 1
fi

TARGET_PATH="$1"
SPLIT_SIZE="${2:-$DEFAULT_SPLIT_SIZE}"

echo $SPLIT_SIZE
# Check if the target path exists and is a directory
if [ ! -d "$TARGET_PATH" ]; then
  echo "Error: Directory '$TARGET_PATH' does not exist."
  exit 1
fi

# Extract the folder name for the session name
SESSION_NAME=$(basename "$TARGET_PATH")

# Check if the session already exists
if tmux has-session -t "$SESSION_NAME" 2> /dev/null; then
  echo "Tmux session '$SESSION_NAME' already exists. Attaching to it."
  tmux attach-session -t "$SESSION_NAME"
else
  echo "Creating new tmux session '$SESSION_NAME'."
  # Start a new detached tmux session with the initial path
  tmux new-session -d -s "$SESSION_NAME" -c "$TARGET_PATH"

  # Split the initial window horizontally
  tmux split-window -h -l "$SPLIT_SIZE" -c "$TARGET_PATH"

  # Ensure nvim is in the system's PATH and can be executed
  if command -v nvim &> /dev/null; then
    # Send the command to open nvim in the right pane (index 0.1) with a small delay
    sleep 1
    tmux send-keys -t "$SESSION_NAME":1 "nvim" Enter
  else
    echo "Warning: 'nvim' command not found in your system's PATH."
    echo "The right pane will be opened in the specified directory."
  fi

  # Attach to the new session
  tmux attach-session -t "$SESSION_NAME"
fi
