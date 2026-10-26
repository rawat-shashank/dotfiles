#!/usr/bin/env bash

is_config_skipped() {
  local config_name="$1"
  for skipped in "${SKIPPED_CONFIGS[@]}"; do
    if [[ "${skipped}" == "${config_name}" ]]; then
      return 0
    fi
  done
  return 1
}

deploy_config_item() {
  local src="$1"
  local config_name
  config_name="$(basename "${src}")"

  # Skip configuration if user pressed 'n' for its package
  if is_config_skipped "${config_name}"; then
    log_warn "Skipping '${config_name}' config (package was skipped)"
    return 0
  fi

  local dest="${CONFIG_HOME}/${config_name}"

  # Ensure ~/.config exists
  mkdir -p "${CONFIG_HOME}"

  # Backup existing config if present and not already symlinked to src
  if [[ -e "${dest}" || -L "${dest}" ]]; then
    if [[ -L "${dest}" && "$(readlink -f "${dest}")" == "$(readlink -f "${src}")" ]]; then
      log_info "Already linked: ${dest}"
      return 0
    fi

    local backup_path="${dest}.bak.$(date +%Y%m%d%H%M%S)"
    log_warn "Backing up existing config: ${dest} -> ${backup_path}"
    if [[ "${DRY_RUN}" == false ]]; then
      mv "${dest}" "${backup_path}"
    fi
  fi

  # Create symlinks for directory or file
  if [[ "${DRY_RUN}" == true ]]; then
    log_info "[DRY-RUN] Would link: ${src} -> ${dest}"
  else
    ln -s "${src}" "${dest}"
    log_success "Linked: ${src} -> ${dest}"
  fi
}

deploy_dotfiles() {
  log_info "Deploying configurations from ${CONFIG_DIR} to ${CONFIG_HOME}..."

  if [[ ! -d "${CONFIG_DIR}" ]]; then
    log_warn "No config directory found at ${CONFIG_DIR} (skipping configuration deployment)"
    return 0
  fi

  # Iterate over all files and directories inside config/
  for item in "${CONFIG_DIR}"/*; do
    [[ -e "${item}" ]] || continue
    deploy_config_item "${item}"
  done
}
