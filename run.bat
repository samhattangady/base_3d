@echo off
set executable=zig-out\bin\basic_3d.exe
call build
if exist %executable% (call %executable%)
goto :done

:done
