# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git)

source $ZSH/oh-my-zsh.sh

## User configuration

# export MANPATH="/usr/local/man:$MANPATH"
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
export PATH="/opt/homebrew/opt/node@16/bin:$PATH"
export PATH="/opt/homebrew/opt/mysql-client@8.4/bin:$PATH"

# Lazy-load nvm: only initializes when you first call nvm, node, npm, or npx
export NVM_DIR="$HOME/.nvm"
# Add default nvm node to PATH so p10k detects it without loading nvm
NVM_DEFAULT_ALIAS="$(cat "$NVM_DIR/alias/default" 2>/dev/null)"
if [[ -n "$NVM_DEFAULT_ALIAS" ]]; then
  DEFAULT_NODE_DIR=("$NVM_DIR/versions/node/v${NVM_DEFAULT_ALIAS}"*(N[1]))
  [[ -d "$DEFAULT_NODE_DIR/bin" ]] && export PATH="$DEFAULT_NODE_DIR/bin:$PATH"
fi
nvm() {
  unfunction nvm node npm npx 2>/dev/null
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
  nvm "$@"
}
node() { nvm --version >/dev/null 2>&1; unfunction node 2>/dev/null; command node "$@"; }
npm() { nvm --version >/dev/null 2>&1; unfunction npm 2>/dev/null; command npm "$@"; }
npx() { nvm --version >/dev/null 2>&1; unfunction npx 2>/dev/null; command npx "$@"; }


# The next line gives vim-style command line editing where you can press Esc to enter normal mode and use vim navigation commands
bindkey -v

# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=($HOME/.docker/completions $fpath)
autoload -Uz compinit
compinit

# pyenv configuration
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
export PATH="$HOME/.local/bin:$PATH"

# Google cloud sql proxy
[[ -f "/opt/homebrew/share/google-cloud-sdk/path.zsh.inc" ]] && source "/opt/homebrew/share/google-cloud-sdk/path.zsh.inc"
