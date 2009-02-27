@echo off

rem custom vars. change it for yourself
set checkhost=

rem settings for local send if external server down (blat)
set report_mail=admin@%checkhost%
set smtp_server=
set smtp_port=
set smtp_password=
set smtp_user=

if "%checkhost%"=="" (
 echo You need set vars before use it
 exit /b
)

if "%~1"=="install" (
 if not "%~2"=="" (
  if not exist "%~2" mkdir "%~2" || (pause & exit /b)
  pushd "%~2" || (popd & pause & exit /b)
  for %%a in (%~nx0 blat.exe wget.exe) do copy /y "%~dp0%%a" || (popd & pause & exit /b)
  call %~nx0 install
  popd
  exit /b
 )
 schtasks /query  | find /i "getip">nul && schtasks /delete /tn getip /f
 schtasks /create /ru system /sc hourly /tn getip /tr "%~dpnx0"
 schtasks /run /tn getip
 exit /b
)
if "%~1"=="untask" (
 schtasks /query  | find /i "getip">nul && schtasks /delete /tn getip /f
 exit /b
)


SETLOCAL ENABLEDELAYEDEXPANSION
rem set clientcomp=%computername%
set clientcomp=%computername%

pushd %~dp0
if "%~1"=="-s" 1 (
 set subj=%~2
) else (
 set subj=IP of %clientcomp%
)
if ("%~2"=="logon") (
 set subj=%username% logon
)
set ip_file=currentip.txt
set get_file=ip.txt
set post_file=%~ns0post.txt

set mail_cmd=blat -server %smtp_server% -portSMTP %smtp_port% -to %report_mail% -f ^
 %clientcomp%@%checkhost% -u %smtp_user% -pw %smtp_password% 

for %%a in (sendip startip) do if "%~1"=="%%a" (
(echo %date% %time%  %clientcomp%: & ipconfig /all ) | ^
%mail_cmd% -s "%subj%" -charset cp866
exit /b
)

if "%username%"=="" set username=system

rem set ddns ( http://freedns.afraid.org/ )
if exist %~dp0%clientcomp%.%checkhost%.bat call %~dp0%clientcomp%.%checkhost%.bat

set get_url=http://%username%:%clientcomp%@%checkhost%/ip.php?
set get_request=client=%clientcomp%

if exist "%get_file%" del /q "%get_file%"
if exist "%ip_file%" for /f %%i in ('type "%ip_file%"') do ( 
 set current_ip=%%i
 set get_request = %get_request%^&ip=%%i
)

rem collect current ipconfig
rem chcp 1251 >nul
set datatext=
for /f "usebackq delims==" %%a in (`ipconfig /all`) do (
 set datatext=!datatext!%%0D%%a
)
echo %get_request%^&data=%datatext% > %post_file%

rem chcp 866 >nul

for %%f in (%post_file%) do if %%~zf GTR 0 (
 set get_request=
 set post-cfg= --post-file=%post_file%
)
wget -O "%get_file%"  -t 3 -o get_page.txt %post-cfg% "%get_url%%get_request%" || ( 
(echo %date% %time%  %clientcomp%: & ipconfig /all ) | ^
%mail_cmd% -s "Error while get IP adress for %subj%" -charset cp866 -body "%date% %time% %clientcomp% at %computername% %username%" -attacht get_page.txt -attach %post_file% 
 exit /b -1
)

for /f %%a in ('findstr /R /i /b "[0-9]*\.[0-9]*\.[0-9]*\.[0-9].*" "%get_file%"') do (
 echo "%%a"=="%current_ip%" 
 if NOT "%%a"=="%current_ip%" (
  echo %%a>"%ip_file%"
 )
)
popd
ENDLOCAL