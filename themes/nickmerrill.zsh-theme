# vim:ft=zsh ts=2 sw=2 sts=2
#
# Based on agnoster's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#

CURRENT_BG='NONE'
SEGMENT_SEPARATOR=''

ONLINE='%{%F{green}%}⦿'
OFFLINE='%{%F{red}%}⦿'

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg%F{$CURRENT_BG}%}%{$fg%}"
    echo -n "$SEGMENT_SEPARATOR"
    echo -n "%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%}"
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n "$3"
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  local who id_who id
  who=`who am i | sed -e 's/ .*//'`
  id_who=`id -u $who`
  id=`id -u`
  if [ "$SSH_CLIENT" ] || [[ $id != $id_who ]]; then
    echo -n "%F{blue}%n%f@%F{blue}%m%f"
    [ "$SSH_CLIENT" ] && echo -n "☁ "
  else
    # At home
    echo -n "%F{blue} ⌘ %f"
  fi
}


# Git: branch/detached head, dirty status
prompt_git() {
  local ref dirty ahead behind clean staged
  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    ZSH_THEME_GIT_PROMPT_DIRTY='±'
    dirty=$(parse_git_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git show-ref --head -s --abbrev |head -n1 2> /dev/null)"
    gitStatus=$(git status)
    if [[ $gitStatus =~ Changes\ to\ be\ committed ]]; then
      staged="⊛" else staged=""
    fi
    if [[ $staged != "" ]]; then
      prompt_segment magenta black
    elif [[ -n $dirty ]]; then
      prompt_segment yellow black
    else
      prompt_segment green black
    fi
    if [[ $gitStatus =~ ahead ]]; then
      ahead=true else ahead=false
    fi
    if [[ $gitStatus =~ behind ]]; then
      behind=true else behind=false
    fi
    if $ahead && $behind; then
      sync="⇅ "
    elif $ahead; then
      sync="⬆ "
    elif $behind; then
      sync="⬇ "
    fi
    if [[ $gitStatus =~ nothing\ to\ commit ]]; then
      clean=" ✔" else clean=""
    fi
    echo -n "$sync${ref/refs\/heads\//}$clean$dirty$staged"
  fi
}

function prompt_online() {
  if [[ -f ~/bin/online-check.sh ]]; then
    if [[ -f ~/.offline ]]; then
      echo -n $OFFLINE
    else
      echo -n $ONLINE
    fi
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment blue white '%~'
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}✘"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}⚡"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{blue}%}⚙"

  [[ -n "$symbols" ]] && prompt_segment black default "$symbols"
}

function battery_charge {
  if [[ -e ~/bin/batcharge.py ]]; then
      echo -n `~/bin/batcharge.py`
  fi
}

## Main prompt
build_prompt() {
  RETVAL=$?
  prompt_context
  prompt_status
  prompt_git
  prompt_dir
  prompt_end
}

RPROMPT='$(battery_charge) $(prompt_online)'

PROMPT='%{%f%b%k%}$(build_prompt) 
%F{red}➥%f '
