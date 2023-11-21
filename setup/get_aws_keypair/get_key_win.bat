@echo off
setlocal

set "PARAMETER_ID=key-XXXXXXXXXXXXX"
set "KEY_PREFIX=/ec2/keypair"
set "OUTPUT_DIR=%USERPROFILE%\Develop\aws\secret"
set "OUTPUT_FILE=ec2_secret_key.pem"

REM if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

REM get secret key and save to file
aws ssm get-parameter --name "%KEY_PREFIX%/%PARAMETER_ID%" --with-decryption --query "Parameter.Value" --output text > "%OUTPUT_DIR%\%OUTPUT_FILE%"

REM set permission
icacls "%OUTPUT_DIR%\%OUTPUT_FILE%" /inheritance:r
icacls "%OUTPUT_DIR%\%OUTPUT_FILE%" /grant "%USERNAME%:F"

echo finish

REM finish
endlocal
