#source /usr/share/cachyos-fish-config/cachyos-config.fish
if status is-interactive
    set -g fish_greeting ""
    pokemon-colorscripts -r
    alias ls='lsd'
    alias l='ls -l'
    alias la='ls -a'
    alias lla='ls -la'
    alias lt='ls --tree'
    alias cat='bat'
    zoxide init fish | source
end
# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end
