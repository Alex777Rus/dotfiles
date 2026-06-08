source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

export PATH=/home/alex/.local/bin:$PATH
eval "$(starship init zsh)"

[[ $- == *i* ]] && fastfetch
