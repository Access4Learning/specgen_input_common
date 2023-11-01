@echo off &setlocal

set "textfile=%1"
set "search=%2"
set "replace="
set "newfile=Output.txt"

echo Input File: %1
echo String to Remove: %2

(for /f "delims=" %%i in (%textfile%) do (
    set "line=%%i"
    setlocal enabledelayedexpansion
    set "line=!line:%search%=%replace%!"
    echo(!line!
    endlocal
))>"%newfile%"
del %textfile%
rename %newfile%  %textfile%
