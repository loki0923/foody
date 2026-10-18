@echo off
title Servidor Foody Venezuela
cd /d "%~dp0"
echo ========================================================
echo   INICIANDO FOODY MARKETPLACE VENEZUELA
echo ========================================================
echo.
echo   Directorio: %~dp0
echo   URL Local:  http://localhost:3000
echo.
echo   Presione Ctrl + C para detener el servidor.
echo ========================================================
echo.
npm.cmd run dev
pause
