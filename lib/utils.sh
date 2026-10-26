#!/usr/bin/env bash

# Terminal Colors
readonly COLOR_RESET="\033[0m"
readonly COLOR_INFO="\033[0;34m"
readonly COLOR_SUCCESS="\033[0;32m"
readonly COLOR_WARN="\033[0;33m"
readonly COLOR_ERROR="\033[0;31m"

log_info() { printf "${COLOR_INFO}[INFO] %s${COLOR_RESET}\n" "$*"; }
log_success() { printf "${COLOR_SUCCESS}[OK] %s${COLOR_RESET}\n" "$*"; }
log_warn() { printf "${COLOR_WARN}[WARN] %s${COLOR_RESET}\n" "$*"; }
log_error() { printf "${COLOR_ERROR}[ERROR] %s${COLOR_RESET}\n" "$*" >&2; }

die() {
  log_error "$*"
  exit 1
}
