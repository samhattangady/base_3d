@echo off
set executable=zig-out\bin\basic_3d.exe
if exist %executable% (del %executable%)
echo building app
call timecmd zig build
goto :done

:done
