#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LIB_DIR="${ROOT_DIR}/lib"
readonly CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"

PACKAGE_FILE="${ROOT_DIR}/packages.list"
CONFIG_DIR="${ROOT_DIR}/config"
BASH_DIR="${ROOT_DIR}/bash"
DRY_RUN=false

source "${LIB_DIR}/utils.sh"
source "${LIB_DIR}/os_detect.sh"
source "${LIB_DIR}/packages.sh"
source "${LIB_DIR}/dotfiles.sh"
source "${LIB_DIR}/bash.sh"
source "${LIB_DIR}/podman.sh"
source "${LIB_DIR}/devcontainer.sh"

show_help() {
  cat <<EOF
Development Environment Setup Script

Usage: $(basename "$0") [OPTIONS]

Options:
  -y, --yes   Automatically accept all prompts (Yes to all)
  --dry-run   Simulate execution without installing or creating links
  -h, --help  Display this help menu
EOF
}

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -y | --yes)
      YES_TO_ALL=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h | --help)
      show_help
      exit 0
      ;;
    *) die "Unknown option: $1" ;;
    esac
  done

  log_info "Starting environment setup..."

  # default packages installation
  detect_os
  load_and_process_packages "${PACKAGE_FILE}"
  install_packages

  # setup bash and bashrc
  setup_bash_config

  log_success "Setup complete!"
}

main "$@"
