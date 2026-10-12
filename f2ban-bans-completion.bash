# Bash completion for f2ban-bans
#
# Installation:
#   sudo cp f2ban-bans-completion.bash /etc/bash_completion.d/f2ban-bans
#   source /etc/bash_completion.d/f2ban-bans   # or open a new shell
#
# After that, TAB after "-j " completes the currently active jail names,
# e.g.:  f2ban-bans -j <TAB><TAB>

_f2ban_bans_completion() {
    local cur prev jails
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "$prev" in
        -j)
            if command -v fail2ban-client >/dev/null 2>&1; then
                jails="$(fail2ban-client status 2>/dev/null | sed -n 's/^.*Jail list:[[:space:]]*//p' | tr ',' ' ')"
            fi
            mapfile -t COMPREPLY < <(compgen -W "${jails}" -- "$cur")
            return 0
            ;;
        -p|-u)
            # no sensible completion possible for pattern/IP
            return 0
            ;;
    esac

    mapfile -t COMPREPLY < <(compgen -W "-p -j -c -l -u -h" -- "$cur")
}

complete -F _f2ban_bans_completion f2ban-bans
