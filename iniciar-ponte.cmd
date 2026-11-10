@echo off
rem Read-only fork: opens the bridge in a visible window, for the QR code pairing.
rem The Romanova's Protocolo Alpha opens it hidden on its own; this is for when you want to see it.
cd /d "%~dp0whatsapp-bridge"
set WEBHOOK_ENABLED=false
set WHATSAPP_DEVICE_NAME=Claude (somente leitura)
whatsapp-bridge.exe %*
pause
