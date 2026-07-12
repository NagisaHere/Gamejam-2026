@echo off
setlocal
REM Deletes the project's .godot cache folder (useful after switching branches).

set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%.."
set "GODOT_DIR=%PROJECT_ROOT%\.godot"

if exist "%GODOT_DIR%" (
	echo Removing: %GODOT_DIR%
	rmdir /s /q "%GODOT_DIR%"
	echo .godot folder deleted. Reopen the project in Godot to regenerate it.
) else (
	echo No .godot folder found at: %GODOT_DIR%
)

endlocal
