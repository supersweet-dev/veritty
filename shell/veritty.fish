# VeriTTY Shell Integration (Fish)
# Source this file in your ~/.config/fish/config.fish:
#   source /path/to/veritty/shell/veritty.fish

if set -q VERITTY_SHELL_ACTIVE
    exit 0
end
set -gx VERITTY_SHELL_ACTIVE 1

# Default alias
alias v="veritty"

# Set VeriTTY as default editor if CLI is on PATH
if type -q veritty
    set -gx EDITOR "veritty open"
    set -gx VISUAL "veritty open"
end

# OSC 7: Report current working directory on directory changes
function __veritty_osc7 --on-variable PWD
    printf "\e]7;file://%s%s\e\\" (hostname) (string escape --style=url $PWD)
end

# Helper functions
function vdiff
    veritty diff $argv
end

function vdrawer
    veritty drawer $argv
end

function vscratch
    veritty scratch $argv
end
