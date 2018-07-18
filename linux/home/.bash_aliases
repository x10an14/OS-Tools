#!/usr/bin/env bash

export PATH="${HOME}/.local/bin:${PATH}"

export VISUAL=vim
export EDITOR=$VISUAL


PROMPT_COMMAND=__prompt_command
__prompt_command() {
	# https://stackoverflow.com/a/16715681
	local returnCode="$?"
	local debian_chroot
	PS1='[\D{%F %T}] '	# Current time: [YYYY-MM-DD HH:MM:SS]

	# local rCol='\[\033[00m\]'
	# local Red='\[\033[0;31m\]'
	# local Gre='\[\033[0;32m\]'
	# local Blu='\[\033[0;33m\]'
	# local Pur='\[\033[0;35m\]'

	if [ $returnCode != 0 ]; then
		PS1+='\[\033[0;31m\]'
		PS1+="${returnCode}"
		PS1+='\[\033[00m\] '
	else
		PS1+="${returnCode} "
	fi

	# set variable identifying the chroot you work in (used in the prompt below)
	if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
		debian_chroot=$(cat /etc/debian_chroot)
		PS1+='${debian_chroot:+($debian_chroot)}'
	fi

	if [ "$(whoami)" == 'root' ]; then
		# Red username if root
		PS1+='\[\033[0;31m\]\u\[\033[00m\]'
	else
		# Purple username
		PS1+='\[\033[01;35m\]\u\[\033[00m\]'
	fi

	PS1+='@'
	PS1+='\[\033[01;32m\]\h\[\033[00m\]'	# Green hostname
	PS1+=':'
	PS1+='\[\033[01;34m\]\w\[\033[00m\]'	# Blue cwd
	PS1+=' \$ '								# $ or # depending on sudo
}


alias la='ls -lahF'
alias reload_bash='source ~/.bashrc'
