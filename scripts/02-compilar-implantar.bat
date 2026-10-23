@echo off
rem Compila e implanta o CadastroEE no GlassFish e testa as URLs
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp002-compilar-implantar.ps1"
pause
