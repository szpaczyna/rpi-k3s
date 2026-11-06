# Jump to directories using frecency, as tracked by zoxide.
#
# Replaces zsh-z, which needed an alias to take over `z` and could not be
# renamed through ZSHZ_CMD because it reads that variable when sourced.
#
# The database lives under ~/.zsh/cache so it survives a dotfiles sync.

if (( ! $+commands[zoxide] )); then
  return
fi

# Must be exported: zoxide reads _ZO_DATA_DIR in the child process, and a
# plain typeset -g would leave the database in the default location under
# ~/Library/Application Support.
export _ZO_DATA_DIR="${_ZO_DATA_DIR:-$HOME/.zsh/cache/zoxide}"

# $HOME has to stay in the list because setting this replaces the default.
# The rest keeps directories that only end up in the database because something
# touches them incidentally: brew shellenv and Homebrew's own bin dirs, /usr/local,
# and the Applications folder that Spotlight and open commands visit.
export _ZO_EXCLUDE_DIRS="${_ZO_EXCLUDE_DIRS:-$HOME:/opt/homebrew:/opt/homebrew/*:/usr/local:/usr/local/*:$HOME/Applications}"

# --hook prompt records a visit on every prompt, not just on explicit cd.
eval "$(zoxide init zsh --hook prompt)"

# zoxide's own completion opens the frecency picker only from the third word
# on, so "z <tab>" and even "z api<tab>" fall through to "_cd -/" and list
# local directories instead. Redirect both to the picker; keep path completion
# for an explicit "./" prefix, where the user is naming a local directory.
function __zoxide_z_complete() {
    # Only complete when the cursor is at the end of the line.
    [[ "${#words[@]}" -eq "${CURRENT}" ]] || return 0

    if [[ "${words[2]}" != ./* ]]; then
        __zoxide_result="$(\command zoxide query --exclude "$(__zoxide_pwd || \builtin true)" --interactive -- ${words[2,-1]} 2>/dev/null)" || __zoxide_result=''

        # Set a result so completion does not re-run and fall through to _cd.
        compadd -Q -S "" -- ""

        # The picker answers on the device status report; bind the handler for it.
        \builtin bindkey '\e[0n' '__zoxide_z_complete_helper'
        \builtin printf '\e[5n'

        return 0
    fi

    _cd -/
}

# fzf has to be on PATH for the interactive query; the Homebrew fzf formula
# provides it, and zi relies on the same path.
