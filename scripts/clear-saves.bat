@echo off
setlocal
REM Clears local Godot user saves for frigid-digits (user://save_data.tres).

set "PROJECT_NAME=frigid-digits"
set "SAVE_DIR=%APPDATA%\Godot\app_userdata\%PROJECT_NAME%"
set "CLEARED=0"

if exist "%SAVE_DIR%" (
	echo Removing: %SAVE_DIR%
	rmdir /s /q "%SAVE_DIR%"
	set "CLEARED=1"
)

if "%CLEARED%"=="0" (
	echo No local saves found for '%PROJECT_NAME%'.
) else (
	echo Local saves cleared.
)

endlocal
