#!/bin/bash

# Define commandline-related utility functions to be imported by other scripts

# Check if the given command exists. If not, provide the command to install it
check_command () {
	local the_command="$1"
	local how_to_install="$2" # e.g. "sudo apt install tmux"
    
	if ! command -v "$the_command" &>/dev/null; then
		echo "Command '${the_command}' not found, but can be installed with:"
		echo "$how_to_install"
		exit 1
	fi
}