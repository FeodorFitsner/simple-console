SimpleConsole\bin\debug\SimpleConsole.exe -1073741819 || IF %ERRORLEVEL% NEQ -1073741819 EXIT /B 1
SimpleConsole\bin\debug\SimpleConsole.exe -2 || IF %ERRORLEVEL% NEQ -1073741819 EXIT /B %ERRORLEVEL%
