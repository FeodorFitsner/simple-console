SimpleConsole\bin\debug\SimpleConsole.exe -1073741819
set LASTERROR=%ERRORLEVEL%
IF %LASTERROR% NEQ 0 (
  echo not equal to 0
  IF %LASTERROR% NEQ -1073741819 EXIT /B %LASTERROR%
)

rem SimpleConsole\bin\debug\SimpleConsole.exe -2 || IF %ERRORLEVEL% NEQ -1073741819 EXIT /B %ERRORLEVEL%
