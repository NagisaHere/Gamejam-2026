#!/usr/bin/env bash
# Clears local Godot user saves for frigid-digits (user://save_data.tres).
set -euo pipefail

PROJECT_NAME="frigid-digits"
CLEARED=0

clear_dir() {
	local dir="$1"
	if [[ -d "$dir" ]]; then
		echo "Removing: $dir"
		sudo rm -rf "$dir"
		CLEARED=1
	fi
}

# Native Linux Godot userdata
clear_dir "${HOME}/.local/share/godot/app_userdata/${PROJECT_NAME}"

# macOS Godot userdata
clear_dir "${HOME}/Library/Application Support/Godot/app_userdata/${PROJECT_NAME}"

# Windows Godot userdata (native Windows path if set, or WSL mounts)
if [[ -n "${USERPROFILE:-}" ]]; then
	clear_dir "${USERPROFILE}/AppData/Roaming/Godot/app_userdata/${PROJECT_NAME}"
fi

if [[ -d /mnt/c/Users ]]; then
	shopt -s nullglob
	for candidate in /mnt/c/Users/*/AppData/Roaming/Godot/app_userdata/"${PROJECT_NAME}"; do
		clear_dir "$candidate"
	done
	shopt -u nullglob
fi

if [[ "$CLEARED" -eq 0 ]]; then
	echo "No local saves found for '${PROJECT_NAME}'."
else
	echo "Local saves cleared."
fi
