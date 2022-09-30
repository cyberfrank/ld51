@echo off
set name=ld49
7z a game.zip .\game\*
ren game.zip game.love
copy /b %LOVE_DIR%\love.exe+game.love %name%.exe && del game.love
7z a %name%.zip %LOVE_DIR%\*.dll %LOVE_DIR%\license.txt changelog.txt %name%.exe && del %name%.exe