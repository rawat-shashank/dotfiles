#!/usr/bin/env bash

detect_os() {
  log_info "Detecting operating system..."

  if [[ ! -f /etc/os-release ]]; then
    die "Cannot detect OS: /etc/os-release missing."
  fi

  # Read OS release variables
  source /etc/os-release

  # only added (fedora, ubuntu and arch) bases
  case "${ID:-}" in
  fedora | rhel | centos) DISTRO_FAMILY="fedora" ;;
  ubuntu | debian | pop | mint) DISTRO_FAMILY="ubuntu" ;;
  arch | manjaro | endeavouros) DISTRO_FAMILY="arch" ;;
  *)
    if [[ "${ID_LIKE:-}" =~ fedora ]]; then
      DISTRO_FAMILY="fedora"
    elif [[ "${ID_LIKE:-}" =~ (ubuntu|debian) ]]; then
      DISTRO_FAMILY="ubuntu"
    elif [[ "${ID_LIKE:-}" =~ arch ]]; then
      DISTRO_FAMILY="arch"
    else
      die "Unsupported distribution: ${NAME:-Unknown}"
    fi
    ;;
  esac

  log_success "Detected OS Family: ${DISTRO_FAMILY}"
}
