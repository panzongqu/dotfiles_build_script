#!/bin/bash
###########################################################################
#  Project: github.com/panzongqu                                          #
#  File:    dotfiles.sh                                                   #
#  Author:  Epanda.pan                                                    #
#  Date:    8/17/2018                                                     #
#                                                                         #
#  Purpose:                                                               #
#    This script creates a git repository                                 #
#    contained the $HOME dotfiles in the $HOME direcory.                  #
#                                                                         #
#  Lisence: WTFPL.                                                        #
###########################################################################

VERSION=1.0.0
DOT_DIR=$HOME/dotfiles
SCRIPT_NAME=`basename "$0"`
COMMAND=""

GIT_USER_EMAIL="panzongqu@163.com"
GIT_USER_NAME="Epanda.pan"
GIT_REMOTE_URL="https://github.com/panzongqu/dotfiles.git"
FRIST_COMMINT_MESSAGE="My first dotfiles commit"

#set -x
usage(){
	echo "Usage:"
	echo "  $0 COMMAND [OPTIONS] [ARG...]"
	echo ""
	echo "Commands:"
	echo "  backup      Backup the dotfiles to $HOME or specified directory"
	echo "  restore     Restore the dotfiles from $DOT_DIR or specified directory"
	echo "  help        Display this help and exit"
	echo "  version     Output version information and exit"
	echo ""
	echo "Options:"
	echo "  -R, -r      Set the specified directory"
	echo "              (path/to/dotfiles)"
	echo "              (default $HOME)"
	echo ""
	echo "Command line examples:"
	echo "  $0 backup     Backup the dotfiles to default directory: $HOME/dotfiles"
	echo "  $0 restore    Restore the dotfiles from directory: $HOME/dotfiles"
	echo ""
	echo "  $0 backup -r /path/to/dotfiles     Backup the dotfiles to directory: /path/to/dotfiles"
	echo "  $0 restore -r /path/to/dotfiles    Restore the dotfiles from directory: /path/to/dotfiles"
	echo ""
}

prepare_files(){
	#prepare directory
	mkdir -p $DOT_DIR
	#echo "Dotfiles repository directory: $DOT_DIR

	FLIES=$(ls -a $HOME | grep '^\.''\w')

	for file in $FLIES;do
		if [ -h "$file" ]; then
			# skip symlinks file
			#echo "skip symlinks file: $file
			continue;
		fi

		#file name without dot
		NAME=$(echo $file | sed s/^\.//)

		echo >&2 "  Move $HOME/$file to $DOT_DIR/$NAME"
		mv $HOME/$file $DOT_DIR/$NAME
		echo >&2 "  Create symlinks: $HOME/$file"
		ln -s $DOT_DIR/$NAME $HOME/$file
	done;

	#try to copy this script
	if [ ! -e "$DOT_DIR/$SCRIPT_NAME" ]; then
		echo " Copy $SCRIPT_NAME to $DOT_DIR"
		cp $SCRIPT_NAME $DOT_DIR/$SCRIPT_NAME  > /dev/null 2>&1
	fi
	echo ""
}

#creat git repository
creat_repository(){
	#check git
	if ! dpkg -l git > /dev/null; then
		echo "Try to install git"
		if sudo apt-get install -y --no-install-recommends git; then
			echo "Install git successfully"
		else	
			echo "Install git failed"
			return 1
		fi
	fi
	#check git-extras
	if ! dpkg -l git-extras > /dev/null; then
		echo "Try to install git-extras"
		if sudo apt-get install -y --no-install-recommends git-extras; then
			echo "Install git-extras successfully"
		else	
			echo "Install git-extras failed"
			return 1
		fi
	fi

	cd $DOT_DIR
	if ! git show-ref > /dev/null 2>&1; then

		git init
		git config user.email $GIT_USER_EMAIL
  		git config user.name $GIT_USER_NAME
		git remote add origin $GIT_REMOTE_URL

		touch .gitignore		
		#ignore some files and directory
		git ignore ssh/ cache/ local/share/Trash/ z zcomp*
		echo ""
		git add --no-warn-embedded-repo --all
		git commit -m "$FRIST_COMMINT_MESSAGE"
		echo "Creat repository successfully"
	else
		echo "Git repository already existed"
	fi
}

do_backup(){
	echo "Prepare files"
	prepare_files
	echo "Prepare git repository"
	creat_repository
	if [ $? = 1 ]; then		
		echo "Creat repository failed"
	fi
}

do_restore(){
	cd $DOT_DIR
	if [ $? = 1 ]; then
		echo "$DOT_DIR not existed"
		return
	fi

	echo "Git repository check"
	FRIST_COMMINT_ID=$(git rev-list --max-parents=0 HEAD)
	if [ $? != 0 ]; then
		echo "No git repository existed"
		return
	fi

	COMMIT_LOG=$(git log $FRIST_COMMINT_ID | sed '1,/^$/d;s/^[ \t]*//')
	if [ "$COMMIT_LOG" != "$FRIST_COMMINT_MESSAGE" ]; then
		echo "Dotfiles repository check failed"
		return
	fi

	echo "Do restore:"
	for file in *; do
		if [ -f "$HOME/.$file" ]; then
			if [ ! -h "$HOME/.$file" ]; then
				DATE=$(date "+%Y-%m-%d_%T")
				mv "$HOME/.$file" "$HOME/$file.$DATE.bak"
				echo "Backup $file to $file.$DATE.bak"
			fi
		fi
		echo "  Link $HOME/.$file" to $DOT_DIR/$file
		ln -sf $DOT_DIR/$file "$HOME/.$file"
	done;
}

version(){
	echo "Dotfiles script version: $VERSION"
}

while [ "$#" -gt 0 ]
do
    case $1 in
        "help" | "HELP" | "-?" | "-h" | "?")
            usage
            exit
            ;;

        "backup" | "BACKUO")
			COMMAND="backup"
            ;;

        "restore" | "RESTORE")
			COMMAND="restore"
            ;;

        "-r" | "-R")
            shift
            export DOT_DIR="$1"
            ;;

        "version")
			version
			exit
            ;;
        *)
            usage
            exit
            ;;
    esac
    shift
done

case $COMMAND in
    "backup")
		do_backup
        ;;

    "restore")
		do_restore
        ;;
    *)
        usage
        exit
        ;;
esac
