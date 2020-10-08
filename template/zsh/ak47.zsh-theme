#!/bin/bash
# @Author: cnak47
# @Date: 2018-04-30 23:59:11
# @LastEditors: cnak47
# @LastEditTime: 2020-01-08 10:56:38
# @Description: 
# #
#local ret_status="%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ )"
# make some aliases for the colours: (coud use normal escap.seq's too)
  for color in RED GREEN YELLOW BLUE MAGENTA CYAN WHITE; do
    eval PR_$color='%{$fg[${(L)color}]%}'
  done
  PR_NO_COLOR="%{$terminfo[sgr0]%}"

if [[ $UID -eq 0 ]]; then #root
   eval PR_USER='${PR_RED}%n${PR_NO_COLOR}'
   eval PR_USER_OP='${PR_RED}%#${PR_NO_COLOR}'
else   #normal user
   eval PR_USER='${PR_GREEN}%n${PR_NO_COLOR}'
   eval PR_USER_OP='${PR_GREEN}%#${PR_NO_COLOR}'
fi
  # Check if we are on SSH or not
  if [[ -n "$SSH_CLIENT"  ||  -n "$SSH2_CLIENT" ]]; then
     eval PR_HOST='${PR_YELLOW}%M${PR_NO_COLOR}' #SSH
  else
  eval PR_HOST='${PR_GREEN}%M${PR_NO_COLOR}' # no SSH
  fi

PROMPT=$'${PR_CYAN}[${PR_USER}${PR_CYAN}@${PR_HOST}${PR_CYAN}][${PR_BLUE}%~${PR_CYAN}] $(git_prompt_info)${PR_USER_OP} '
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}git:(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}) %{$fg[yellow]%}✗"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})"
