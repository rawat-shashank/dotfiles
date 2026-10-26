#!/usr/bin/env bash

RESOLVED_PACKAGES=()
SKIPPED_CONFIGS=()
YES_TO_ALL=false

prompt_package() {
  local pkg_name="$1"

  if [[ "${YES_TO_ALL}" == true ]]; then
    return 0
  fi

  while true; do
    printf "${COLOR_WARN}Install package '%s'? [y/n/Y (yes to all)]: ${COLOR_RESET}" "${pkg_name}"
    read -r answer </dev/tty
    case "${answer}" in
    [Yy]*)
      if [[ "${answer}" == "Y" ]]; then
        YES_TO_ALL=true
        log_info "Accepting all remaining packages."
      fi
      return 0
      ;;
    [Nn]*)
      return 1
      ;;
    *)
      echo "Please answer y (yes), n (no), or Y (yes to all)."
      ;;
    esac
  done
}

load_and_process_packages() {
  local pkg_file="$1"

  if [[ ! -f "${pkg_file}" ]]; then
    die "Package list not found at: ${pkg_file}"
  fi

  log_info "Reading package list: ${pkg_file}"

  while IFS= read -r line || [[ -n "${line}" ]]; do
    local cleaned_line
    cleaned_line="$(echo "${line}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    if [[ -z "${cleaned_line}" || "${cleaned_line}" =~ ^# ]]; then
      continue
    fi

    # Resolve cross-distro package names
    IFS=':' read -r -a pkg_parts <<<"${cleaned_line}"
    local target_pkg=""

    if [[ ${#pkg_parts[@]} -ge 3 ]]; then
      case "${DISTRO_FAMILY}" in
      fedora) target_pkg="${pkg_parts[0]}" ;;
      ubuntu) target_pkg="${pkg_parts[1]}" ;;
      arch) target_pkg="${pkg_parts[2]}" ;;
      esac
    else
      target_pkg="${cleaned_line}"
    fi

    # Ask user before installation
    if prompt_package "${target_pkg}"; then
      RESOLVED_PACKAGES+=("${target_pkg}")
    else
      log_warn "Skipping package '${target_pkg}'"
      # Automatically infer skipped config folder (e.g. neovim -> nvim)
      SKIPPED_CONFIGS+=("${target_pkg}")
    fi
  done <"${pkg_file}"
}

install_packages() {
  if [[ ${#RESOLVED_PACKAGES[@]} -eq 0 ]]; then
    log_warn "No packages selected for installation."
    return 0
  fi

  log_info "Installing selected packages: ${RESOLVED_PACKAGES[*]}"

  case "${DISTRO_FAMILY}" in
  fedora)
    for pkg in "${RESOLVED_PACKAGES[@]}"; do
      if [[ "${pkg}" == *"/"* ]]; then
        # Package contains a user/repo format (e.g., varlad/yazi)
        local copr_repo="${pkg}"
        local binary_name
        binary_name="$(basename "${pkg}")"

        if [[ "${DRY_RUN}" == true ]]; then
          log_info "[DRY-RUN] Would run: sudo dnf copr enable -y ${copr_repo}"
          log_info "[DRY-RUN] Would run: sudo dnf install -y ${binary_name}"
        else
          log_info "Enabling Fedora COPR repository: ${copr_repo}"
          sudo dnf copr enable -y "${copr_repo}"
          sudo dnf install -y "${binary_name}"
        fi
      else
        # Standard Fedora package
        if [[ "${DRY_RUN}" == true ]]; then
          log_info "[DRY-RUN] Would run: sudo dnf install -y ${pkg}"
        else
          sudo dnf install -y "${pkg}"
        fi
      fi
    done
    ;;
  ubuntu)
    if [[ "${DRY_RUN}" == true ]]; then
      log_info "[DRY-RUN] Would run: sudo apt-get update && sudo apt-get install -y ${RESOLVED_PACKAGES[*]}"
    else
      sudo apt-get update && sudo apt-get install -y "${RESOLVED_PACKAGES[@]}"
    fi
    ;;
  arch)
    if [[ "${DRY_RUN}" == true ]]; then
      log_info "[DRY-RUN] Would run: sudo pacman -Syu --noconfirm ${RESOLVED_PACKAGES[*]}"
    else
      sudo pacman -Syu --noconfirm "${RESOLVED_PACKAGES[@]}"
    fi
    ;;
  esac

}
