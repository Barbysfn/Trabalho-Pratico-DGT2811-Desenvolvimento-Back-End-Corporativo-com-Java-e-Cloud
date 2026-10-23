@echo off
rem Configura o NetBeans (servidor GlassFish, driver e conexao do SQL Server). Feche o NetBeans antes.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp003-configurar-netbeans.ps1"
