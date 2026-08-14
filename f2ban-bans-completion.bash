# Bash-Completion für f2ban-bans
#
# Installation:
#   sudo cp f2ban-bans-completion.bash /etc/bash_completion.d/f2ban-bans
#   source /etc/bash_completion.d/f2ban-bans   # oder neue Shell öffnen
#
# Danach vervollständigt TAB nach "-j " die aktuell aktiven Jail-Namen,
# z. B.:  f2ban-bans -j <TAB><TAB>

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
            COMPREPLY=( $(compgen -W "${jails}" -- "$cur") )
            return 0
            ;;
        -p|-u)
            # kein sinnvolles Vervollständigen für Muster/IP möglich
            return 0
            ;;
    esac

    COMPREPLY=( $(compgen -W "-p -j -c -l -u -h" -- "$cur") )
}

complete -F _f2ban_bans_completion f2ban-bans
