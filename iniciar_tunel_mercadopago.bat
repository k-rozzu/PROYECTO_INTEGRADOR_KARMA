@echo off
rem KARMA - Tunel HTTPS (ngrok) para que los avisos (Webhooks) de Mercado Pago lleguen al Apache local.
rem Lee NGROK_AUTHTOKEN y NGROK_DOMINIO del archivo .env y SOLO expone el Webhook (politica ngrok_mercadopago.yml).
rem El cobro con tarjeta funciona aunque el tunel este cerrado: la caja consulta el estado del pago por su cuenta.
setlocal
cd /d "%~dp0"
for /f "usebackq eol=# tokens=1,* delims==" %%A in (".env") do (
  if "%%A"=="NGROK_AUTHTOKEN" set "NGROK_AUTHTOKEN=%%B"
  if "%%A"=="NGROK_DOMINIO" set "NGROK_DOMINIO=%%B"
)
if "%NGROK_DOMINIO%"=="" (
  echo Falta NGROK_DOMINIO en el archivo .env
  pause
  exit /b 1
)
rem ngrok instalado con winget: si la consola no lo encuentra en el PATH, se usa el de la carpeta de winget
set "NGROK=ngrok"
where ngrok >nul 2>nul || for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\Ngrok.Ngrok_*") do set "NGROK=%%D\ngrok.exe"
echo Webhook: https://%NGROK_DOMINIO%/PROYECTO_INTEGRADOR_KARMA/PHP/PuntoDeVenta/mercadopago_webhook.php
"%NGROK%" http 80 --url=https://%NGROK_DOMINIO% --traffic-policy-file="%~dp0ngrok_mercadopago.yml"
pause
