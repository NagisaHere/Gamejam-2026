#!/usr/bin/env bash
# Deletes the project's .godot cache folder
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
GODOT_DIR="${PROJECT_ROOT}/.godot"

if [[ -d "$GODOT_DIR" ]]; then
	echo "Removing: $GODOT_DIR"
	rm -rf "$GODOT_DIR"
	echo ".godot folder deleted. Reopen the project in Godot to regenerate it."
else
	echo "No .godot folder found at: $GODOT_DIR"
fi
