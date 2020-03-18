#!/usr/bin/env bash

set -euo pipefail
# -e exit if any command returns non-zero status code
# -u prevent using undefined variables
# -o pipefail force pipelines to fail on first non-zero status code

FAIL=$(echo -en '\033[01;31m')
PASS=$(echo -en '\033[01;32m')
NC=$(echo -en '\033[0m')
INFO=$(echo -en '\033[01;35m')
WARN=$(echo -en '\033[1;33m')

IFS=$'\n'

function install_tools {

	echo -e "\n${INFO}[*]${NC} Installing XCode Tools"
	echo "-------------------------------------------------------------------------------"

	if xcode-select --install  2> /dev/null | grep -q 'install requested'; then
		echo "XCode Tools must be installed. Please follow the opened dialog and then re-run on completion."
		exit 1
	fi

	if ! [[ "$(command -v brew)" > /dev/null ]] ; then

		echo -e "\n${INFO}[*]${NC} Installing Homebrew"
		echo "-------------------------------------------------------------------------------"
		if ! /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" ; then

			echo "${FAIL}[-]${NC} Failed to install Homebrew..."
			exit 1
		fi
	fi

	echo -e "\n${INFO}[*]${NC} Installing Tools Using Homebrew"
	echo "-------------------------------------------------------------------------------"

	echo "Updating Homebrew..."
	brew update >> /dev/null

	echo "Upgrading Homebrew..."
	brew upgrade >> /dev/null

	echo "Installing tools using brewfile..."
	brew bundle --file Brewfile


}

function main {
	
	var=${1:-"usage"}

	case "${var}" in
		collect ) 
			shift

			while getopts ":hdnu" opt; do
				case ${opt} in
					h ) usage
						;;

					d ) echo "collect disk" 
						echo "${WARN}[!]${NC} Sudo permissions required..."
						sudo ./collect.sh -d
						;;

					n ) local ipPort=${2:-"none"}; 
						if ! [ "${ipPort}" == "none" ] ; then

							ip=$(echo "${ipPort}" | awk -F ":" ' { print $1 } ')
							port=$(echo "${ipPort}" | awk -F ":" ' { print $2 } ')

							IFS="."

							read -r -a ipArray <<< "$ip"

							if [[ ${ipArray[0]} -le 255 ]] &&  [[ ${ipArray[1]} -le 255 ]] && [[ ${ipArray[2]} -le 255 ]] && [[ ${ipArray[3]} -le 255 ]] && [[ ${port} -le 65365 ]]; then

								echo "${WARN}[!]${NC} Sudo permissions required..."
								sudo ./collect.sh -n "${ipPort}"
							else
								echo "${FAIL}[-]${NC} Please provide a valid IP address and port. Exiting..."
								exit 1
							fi
						else 
							echo "${FAIL}[-]${NC} Please provide a disk name. Exiting..."
							exit 1
						fi
						;;

					u ) local disk=${2:-"none"};

						if ! [ "${disk}" == "none" ] ; then

							if [[ -e /Volumes/"${disk}" ]] ; then
								echo "${WARN}[!]${NC} Sudo permissions required..."
								sudo ./collect.sh -u "${disk}"
							else
								echo "${FAIL}[-]${NC} Provided disk does not exist. Exiting..."
								exit 1
							fi
						else 
							echo "${FAIL}[-]${NC} Please provide a disk name. Exiting..."
							exit 1
						fi
						;;

					\?) echo "Invalid option -- $OPTARG "
						usage
						;;

					* ) usage
						;;
				esac
			done
			;;

		analysis ) 
			shift 

			while getopts ":hdnui" opt; do
				case ${opt} in
					h ) usage
						;;
					d ) local diskImage=${2:-"none"};

						if ! [ "${diskImage}" == "none" ] ; then
							install_tools
							echo "${WARN}[!]${NC} Sudo permissions required..."
							sudo ./analysis -d "${diskImage}"
						else
							echo "${FAIL}[-]${NC} Please provide a disk name. Exiting..."
						fi
						;;

					n ) local port=${2:-"none"};

						if ! [ "${port}" == "none" ] ; then
							install_tools
							echo "${WARN}[!]${NC} Sudo permissions required..."
							sudo ./analysis.sh -n "${port}"
						else
							echo "${FAIL}[-]${NC} Please provide a port. Exiting..."
						fi
						;;

					u ) local disk=${2:-"none"};

						if ! [ "${disk}" == "none" ] ; then

							if [[ -e /Volumes/"${disk}" ]] ; then
								install_tools
								echo "${WARN}[!]${NC} Sudo permissions required..."
								sudo ./analysis.sh -u "${disk}"
							else
								echo "${FAIL}[-]${NC} Provided disk does not exist. Exiting..."
								exit 1
							fi
						else 
							echo "${FAIL}[-]${NC} Please provide a disk name. Exiting..."
							exit 1
						fi
						;;

					i ) install_tools
						;;

					\?) echo "Invalid option -- $OPTARG "
						usage
						;;

					* ) usage
						;;
				esac
			done 
			;;

		tools ) install_tools
			;;

		* ) usage
			;;
	esac
}

main "$@"