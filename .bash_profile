# Add `~/bin` to the `$PATH`
#export PATH="$HOME/bin:$PATH";

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,bash_prompt,exports,aliases,functions,extra,proxy}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob;

# Append to the Bash history file, rather than overwriting it
shopt -s histappend;

# Autocorrect typos in path names when using `cd`
shopt -s cdspell;

# Enable some Bash 4 features when possible:
# * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
# * Recursive globbing, e.g. `echo **/*.txt`
for option in autocd globstar; do
	shopt -s "$option" 2> /dev/null;
done;

# load boxen environment
[ -f /opt/boxen/env.sh ] && source /opt/boxen/env.sh

# Add tab completion for many Bash commands

if [ "$OSTYPE" == "darwin15" ]; then
	if which brew > /dev/null && [ -f "$(brew --prefix)/etc/bash_completion" ]; then
		source "$(brew --prefix)/etc/bash_completion";
	elif [ -f /etc/bash_completion ]; then
		source /etc/bash_completion;
	fi;
fi

# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2 | tr ' ' '\n')" scp sftp ssh;

# Add tab completion for `defaults read|write NSGlobalDomain`
# You could just use `-g` instead, but I like being explicit

if [ "$OSTYPE" == "darwin15" ]; then
	complete -W "NSGlobalDomain" defaults;

	# Add `killall` tab completion for common apps
	complete -o "nospace" -W "Contacts Calendar Dock Finder Mail Safari iTunes SystemUIServer Terminal Twitter" killall;

	eval "$(jenv init -)"
	[[ -s `brew --prefix`/etc/autojump.sh ]] && . `brew --prefix`/etc/autojump.sh

	# Docker machine stuff
	#eval "$(docker-machine env docker-vm)"
	#MACHINE=docker-vm
	#KEYFILE="$HOME/.docker/machine/machines/$MACHINE/id_rsa"

	export HOMEBREW_GITHUB_API_TOKEN=93669ef6bde9262050c085742b6887e501ad12fb
	#export DOCKER_MACHINE_NAME=docker-vm
fi

DISTRO=`cat /etc/*-release | grep DISTRIB_ID | cut -d '=' -f 2`
if [ "$DISTRO" == "Ubuntu" ]; then 
	. /usr/share/autojump/autojump.sh
fi


