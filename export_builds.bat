set godot_path=C:\Program Files (x86)\GodotSteam\godotsteam.441.editor.windows.64.exe
set project_path=C:\Users\morai\Documents\Godot4Projects\gmtk2025
set date=%date:~-4%-%date:~3,2%-%date:~0,2%  %time:~0,2%-%time:~3,2%-%time:~6,2%

set base_export_path=C:\Users\morai\Documents\Godot4Projects\Executables\SisyphusIsABug\Steam\%date%\

set game_name=SisyphusIsABug

set base_path=%CD%

set general_export_path=General\
set pck_name=%game_name%.pck

set windows_build_name=windows
set windows_export_path=Windows\
set windows_exec_name=%game_name%.exe
set windows_dll_path=C:\Program Files (x86)\GodotSteam\steam_api64.dll

set linux_build_name=linux
set linux_export_path=Linux\
set linux_exec_name=%game_name%.x86_64
set linux_dll_path=C:\Program Files (x86)\GodotSteam\
set linux_dll_name=libsteam_api.so

:: Create Windows export
mkdir "%base_export_path%%windows_export_path%"
"%godot_path%" --headless --path "%project_path%" --export-release %windows_build_name% "%base_export_path%%windows_export_path%%windows_exec_name%"
copy "%windows_dll_path%%windows_dll_name%" "%base_export_path%%windows_export_path%%windows_dll_name%"

:: Place shared content
mkdir "%base_export_path%%general_export_path%"
move "%base_export_path%%windows_export_path%%pck_name%" "%base_export_path%%general_export_path%%pck_name%"

:: Create Linux export
mkdir "%base_export_path%%linux_export_path%"
"%godot_path%" --headless --path "%project_path%" --export-release %linux_build_name% "%base_export_path%%linux_export_path%%linux_exec_name%"
copy "%linux_dll_path%%linux_dll_name%" "%base_export_path%%linux_export_path%%linux_dll_name%"

del "%base_export_path%%linux_export_path%%pck_name%"

:: Zip files
cd /d "%base_export_path%%windows_export_path%"
tar.exe -a -c -f "..\%windows_build_name%.zip" *

cd /d "%base_export_path%%linux_export_path%"
tar.exe -a -c -f "..\%linux_build_name%.zip" *

cd /d "%base_export_path%%general_export_path%"
tar.exe -a -c -f "..\general.zip" *

cd /d "%base_path%"

:: Delete folders
del /F /Q "%base_export_path%%windows_export_path%"
rmdir "%base_export_path%%windows_export_path%"
del /F /Q "%base_export_path%%linux_export_path%"
rmdir "%base_export_path%%linux_export_path%"
del /F /Q "%base_export_path%%general_export_path%"
rmdir "%base_export_path%%general_export_path%"
