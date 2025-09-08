confirm_action() {
  local prompt_message="$1"
  local response

  # Prompt the user with the provided message
  read -p "$prompt_message (y/N): " response

  # Convert response to lowercase for case-insensitive comparison
  response=$(echo "$response" | tr '[:upper:]' '[:lower:]')

  # Check the response
  if [[ "$response" == "y" || "$response" == "yes" ]]; then
    # User confirmed, return 0 (success)
    return 0
  else
    # User did not confirm, print a message and return 1 (failure)
    echo "Operation cancelled."
    return 1
  fi
}
