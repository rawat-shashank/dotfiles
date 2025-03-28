# ----- Color Functions -----
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export NC='\033[0m' # No Color

# Define the list of packages to install
# declare -a packages=("zsh" "neovim" "tmux" "oh-my-posh")
declare -a packages=(
    "zsh"
    "oh-my-posh"
    "tmux"
    "neovim"
)
export packages

# ----- Constants -----
export SUDO_PASSWORD=""
export DRY_RUN="false"
export ALL_YES="false"
export DOTFILE_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../" && pwd )"