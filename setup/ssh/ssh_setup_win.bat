@echo off
setlocal

REM set variables(cf output)
set "PARAMETER_ID=key-XXXXXXXXXXXXX"
set "INSTANCE_ID=i-XXXXXXXXXXXXX"

set "OUTPUT_FILE=ec2_secret_key.pem"
set "KEY_PREFIX=/ec2/keypair"
set "OUTPUT_DIR=%USERPROFILE%\Develop\aws\secret"
set "SSH_CONFIG=%USERPROFILE%\.ssh\config"
set "HOST=ec2"

REM if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

REM get key pair from parameter store and save to file
aws ssm get-parameter --name "%KEY_PREFIX%/%PARAMETER_ID%" --with-decryption --query "Parameter.Value" --output text > "%OUTPUT_DIR%\%OUTPUT_FILE%"

REM change permission
icacls "%OUTPUT_DIR%\%OUTPUT_FILE%" /inheritance:r
icacls "%OUTPUT_DIR%\%OUTPUT_FILE%" /grant "%USERNAME%:F"

REM postscript ssh config
echo host %HOST%>> "%SSH_CONFIG%"
echo    HostName %INSTANCE_ID%>> "%SSH_CONFIG%"
echo    Port 22>> "%SSH_CONFIG%"
echo    User ubuntu>> "%SSH_CONFIG%"
echo    IdentityFile %OUTPUT_DIR%\%OUTPUT_FILE%>> "%SSH_CONFIG%"
echo    ProxyCommand C:\Program Files\Amazon\AWSCLIV2\aws.exe ssm start-session --target %h --document-name AWS-StartSSHSession --parameters "portNumber=%p" >> "%SSH_CONFIG%"

echo finish
endlocal
