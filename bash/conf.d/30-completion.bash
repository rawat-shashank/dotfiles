# Enable bash completion if available
if [[ -f /etc/bash_completion ]]; then
  source /etc/bash_completion
elif [[ -f /usr/share/bash-completion/bash_completion ]]; then
  source /usr/share/bash-completion/bash_completion
fi
