# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

[ -n "$PS2" ] && source ~/.bash_profile;

if [ -f ~/.profile ]; then
	source ~/.profile
fi

source ~/.prompt

GIT_PROMPT_END="\n\[$MAGENTA\]\A \[${BOLD}${BASE00}\]\u@\h > \[$RESET\]"
GIT_PROMPT_ONLY_IN_REPO=1
source ~/.git-bash-prompt/gitprompt.sh

