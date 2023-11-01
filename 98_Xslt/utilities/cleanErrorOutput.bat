@echo off
set fileName=%1

set textToRemove=[90m
call remove.bat %fileName% %textToRemove%

set textToRemove=[39m
call remove.bat %fileName% %textToRemove%

set textToRemove=[41m
call remove.bat %fileName% %textToRemove%

set textToRemove=[49
call remove.bat %fileName% %textToRemove%

set textToRemove=[31m
call remove.bat %fileName% %textToRemove%

set textToRemove=[34m
call remove.bat %fileName% %textToRemove%

set textToRemove=[43m
call remove.bat %fileName% %textToRemove%

set textToRemove=[30
call remove.bat %fileName% %textToRemove%

