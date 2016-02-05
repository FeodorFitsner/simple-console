SimpleConsole\bin\debug\SimpleConsole.exe -1073741819
IF %ERRORLEVEL% NEQ 0 (
  echo not equal to 0
  IF %ERRORLEVEL% NEQ -1073741819 EXIT /B %ERRORLEVEL%
)

rem SimpleConsole\bin\debug\SimpleConsole.exe -2 || IF %ERRORLEVEL% NEQ -1073741819 EXIT /B %ERRORLEVEL%
