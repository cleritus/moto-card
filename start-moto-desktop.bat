@echo off
rem Starts the local Moto-Card API (if not already listening on :3000) and then the Windows app.
set "ROOT=%~dp0"
set "EXE=%ROOT%mobile\build\windows\x64\runner\Release\moto_service_card.exe"
set /a tries=0

if not exist "%EXE%" goto noexe

netstat -ano | findstr /R /C:":3000 .*LISTENING" >nul
if not errorlevel 1 goto launch

echo Startuje API...
start "Moto-Card API" /min cmd /c "cd /d "%ROOT%api" && npm start"

:wait
timeout /t 1 /nobreak >nul
netstat -ano | findstr /R /C:":3000 .*LISTENING" >nul
if not errorlevel 1 goto launch
set /a tries+=1
if %tries% lss 60 goto wait
echo API nie wstalo w 60 s - sprawdz okno "Moto-Card API" i polaczenie z MongoDB Atlas.
pause
exit /b 1

:launch
start "" "%EXE%"
exit /b 0

:noexe
echo Brak %EXE%
echo Zbuduj appke: cd mobile ^&^& flutter build windows
pause
exit /b 1
