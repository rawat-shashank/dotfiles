#!/bin/bash

# ----- Messages Functions -----
success_message() {
    echo -e "${GREEN}Success: $1${NC}"
}

warning_message() {
    echo -e "${YELLOW}Warning: $1${NC}"
}

error_message() {
    echo -e "${RED}Error: $1${NC}"
}

info_message() {
    echo -e "$1"
}

# ----- spinner Functions -----

CLEAR_LINE=$'\e[K'

start_spinner() {
    SPINNER_CHARS="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    SPINNER_PID=0
    MESSAGE="$1"
    
    spinner_func() {
        local i=0
        while true; do
            printf "\r${YELLOW}${SPINNER_CHARS:$i:1}${NC} $MESSAGE"
            i=$(((i + 1) % ${#SPINNER_CHARS}))
            sleep 0.1
        done
    }
    
    spinner_func &
    SPINNER_PID=$!
}

stop_spinner_success() {
    if [[ -n "$SPINNER_PID" ]]; then
        kill "$SPINNER_PID" 2>/dev/null
        printf "\r${GREEN}✔${NC} $1${CLEAR_LINE}\n"
        SPINNER_PID=0
    fi
}

stop_spinner_failure() {
    if [[ -n "$SPINNER_PID" ]]; then
        kill "$SPINNER_PID" 2>/dev/null
        printf "\r${RED}✘${NC} $1${CLEAR_LINE}\n"
        SPINNER_PID=0
    fi
}