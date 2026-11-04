# VeriTTY Shell Integration (Bash & Zsh)
# Source this file in your ~/.bashrc or ~/.zshrc:
#   source /path/to/veritty/shell/veritty.sh

if [ -n "$VERITTY_SHELL_ACTIVE" ]; then
  return 0 2>/dev/null || exit 0
fi
export VERITTY_SHELL_ACTIVE=1

# Default alias
alias v="veritty"

# Set VeriTTY as default editor if CLI is on PATH
if command -v veritty >/dev/null 2>&1; then
  export EDITOR="veritty open"
  export VISUAL="veritty open"
fi

# OSC 7: Report current working directory on directory changes
__veritty_osc7() {
  printf "\033]7;file://%s%s\033\\" "$HOSTNAME" "$PWD"
}

# Attach to prompt hooks
if [ -n "${BASH_VERSION:-}" ]; then
  PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }__veritty_osc7"
elif [ -n "${ZSH_VERSION:-}" ]; then
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd __veritty_osc7
fi

# Helper functions
vdiff() {
  veritty diff "$@"
}

vdrawer() {
  veritty drawer "$@"
}

vscratch() {
  veritty scratch "$@"
}
