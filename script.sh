#!/bin/bash

DEFAULTPATH='etc/scriptbuilder/default'
STRUCTUREFILE='etc/scriptbuilder/default/structure'

#Causes the script to exit if a variable doesn't exist.
set -o nounset

#Allocating flags for debug and verbose modes.
vValue=0
xValue=0

#Checks if the script is currently in verbose mode, then the script will print every action performed.
vFlag() {
	if [ "${vValue}" -eq 1 ]
	then
		echo "${1}"
	fi
}

#Checks if the script is currently in debug mode, then the script will display which changes would be made without actually modifying or creating files.
xFlag() {
	if [ "${xValue}" -eq 1 ]
	then
		return 1
	else
		return 0
	fi
}

#Task created in order to validate whether a file/folder exists or not.
checkExistence() {
	vFlag "Validating if the folder exists already..."
	
	if [ -e "${1}" ]
	then
		return 1
	else
		return 0
	fi
}

#Task created in order to validate whether the directory is owned by the current user or not.
checkFileOwnership() {
	vFlag "Validating if the user owns the current directory and can write into it..."

	if [ -O "${1}" ]
	then
		return 1
	else
		return 0
	fi
}

#Validates if the project folder exists and the current user is allowed to write in the current directory
validateBeforeStarting() {
	checkExistence "${1}/${2}"
	isExisting="$?"

	checkFileOwnership "${1}"
	isOwnedByUser="$?"

	if [ "${isExisting}" -eq 1 ]
	then
		echo "Process can't be run because the given directory does exist."
		exit
	fi

	if [ "${isOwnedByUser}" -eq 0 ]
	then
		echo "Process can't be run because you don't have permission to take any actions with the file."
		exit
	fi 
}

#Default creation of projects task
defaultCreation() {
	xFlag
	isDebugged="$?"
	file="${STRUCTUREFILE}"

	if [ "$isDebugged" -eq 1 ]
	then
		echo "Project ${projectName} would be created."

		while read line
		do
			echo "${line} file would be created."
		done < $file
	else
		vFlag "Creating project directory called ${projectName}."

		mkdir "/home/anuar/${projectName}"

		while read line
		do
			vFlag "Creating ${line} directory."

			mkdir "${projectDirectory}/${line}"
		done < $file
		
		vFlag "Project structure of ${projectName} created succesfully."
	fi
}

#Sets new file of project structure
sFlag() {
	vFlag "Setting new structure according to the given file in arguments..."
	
	xFlag
	isDebugged="$?"
	
	if [ "$isDebugged" -eq 1 ]
	then
		echo "${1} would be the new structure file."
	else
		cp "$1" "${DEFAULTPATH}"
	fi
}

#Sets new content folder structure
dFlag() {	
	vFlag "Setting new contents directory according to the given directory in arguments..."
	
	xFlag
	isDebugged="$?"
	
	if [ "$isDebugged" -eq 1 ]
	then
		echo "Contents folder would be replaced."
	else
		sudo rm -rf "${DEFAULTPATH}/contents/"
		sudo cp -a "$1/" "${DEFAULTPATH}/"
	fi
}

#Compares a given directory with the project structure in order to look for missing files
cFlag() {
	file='${STRUCTUREFILE}'

	while read line
	do
		vFlag "Checking if ${line} is missing..."

		if [ ! -e "${1}/${line}" ]
		then
			echo "--- ${line} directory is missing in ${1} ---"
		fi 

	done < $file

	exit
}

#Prints the content project structure into a given file
pFlag() {
	xFlag
	isDebugged="$?"

	cd "${DEFAULTPATH}/contents"
	
	if [ "$isDebugged" -eq 1 ]
	then
		echo "The following structure would be printed into a structure file"
		ls
	else 
		ls > "/home/anuar/$1"
	fi

	exit
}

#Receives arguments provided by user in command prompt
while getopts 'xcdpsv' flag
do
	case "${flag}" in
		c) cFlag "${2}";;
		d) dFlag "${2}";;
		p) pFlag "${2}";;
		s) sFlag "${2}";;
		v) vValue=1
		   echo "Verbose mode active" ;;
		x) xValue=1
		   echo "Debugged mode active" ;;
		*) echo "Please, enter a valid flag."
	esac
done

echo "Enter the name of the project: "
read projectName

projectDirectory="/home/anuar/${projectName}"
validateBeforeStarting "/home/anuar" "${projectName}"
defaultCreation
