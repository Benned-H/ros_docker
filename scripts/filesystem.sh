#!/bin/bash

# Define filesystem-related utility functions to be imported by other scripts

# Check that the given directory exists. If not, error and exit
check_directory () {
	local dir_path="$1"
	
	if [ ! -d "$dir_path" ]; then
		echo "Error: Expected to find directory $dir_path"
		exit 1
	fi
}

# Check that the given file exists. If not, error and exit
check_file () {
	local filepath="$1"
	
	if [ ! -f "$filepath" ]; then
		echo "Error: Expected to find file $filepath"
		exit 1
	fi
}

# Check that the given directory exists and has the given Git URL. If not, error and exit
check_repo() {
	local dir_path="$1"
	local expected_repo_url="$2"

	check_directory "$dir_path"
	
	local working_dir=$(pwd)
	cd "$dir_path" || exit 1
	
	local repo_url=$(git config --get remote.origin.url)
	if [ "$expected_repo_url" != "$repo_url" ]; then
		echo "Error: Expected directory ${dir_path} to have remote URL '${expected_repo_url}' but instead found '${repo_url}'"
		exit 1
	else
		echo "Confirmed that directory ${dir_path} has remote URL '${repo_url}'"
	fi

	cd "$working_dir" || exit 1
}

# Delete the given file, if it exists
delete_file() {
    local filepath="$1"

    if [ -f "$filepath" ]; then
        rm "$filepath" || exit 1
    fi
}

# Delete the given directory (and its contents), if it exists
delete_directory() {
    local dir_path="$1"
	
	if [ -d "$dir_path" ]; then
        rm -rf "$dir_path" || exit 1
	fi
}