@echo off
cls
echo.
echo Press 1 for Grand Theft Auto
echo Press 2 for GTA: London 1969
echo Press 3 to Quit
echo.
choice /C:123 /N Please Choose:

If errorlevel=3 goto quit
If errorlevel=2 goto london
If errorlevel=1 goto gta

:gta
cd gta
cls
call gtados
goto quit

:london
cd gta
cls
call london
goto quit

:quit