@echo off
setlocal enabledelayedexpansion

REM Set variables(cf output)
set "PARAMETER_ID=key-XXXXXXXXXXXXXXXXX"
set "INSTANCE_ID=i-XXXXXXXXXXXXXXXXX"
set "SECRET_KEY=ec2_secret_key.pem"
set "KEY_PREFIX=/ec2/keypair"
set "SSH_CONFIG=config"
set "SSH_CONFIG_DIR=%USERPROFILE%\.ssh"
set "SSH_CONFIG_PATH=%SSH_CONFIG_DIR%\%SSH_CONFIG%"
set "SECRET_KEY_PATH=%SSH_CONFIG_DIR%\%SECRET_KEY%"
set "HOST=ec2"
set "USER=ubuntu"

REM If not exist "%SSH_CONFIG_DIR%" mkdir "%SSH_CONFIG_DIR%"
if not exist "%SSH_CONFIG_DIR%" (
    echo Creating .ssh directory...
    mkdir "%SSH_CONFIG_DIR%"
)

REM Get key pair from parameter store and save to file
echo Retrieving and saving the secret key...
aws ssm get-parameter --name "%KEY_PREFIX%/%PARAMETER_ID%" --with-decryption --query "Parameter.Value" --output text > "%SECRET_KEY_PATH%"

REM Change permission
echo Setting file permissions...
icacls "%SECRET_KEY_PATH%" /inheritance:r
icacls "%SECRET_KEY_PATH%" /grant "%USERNAME%:F"

REM Postscript ssh config
echo Updating SSH configuration...
(
    echo host %HOST%
    echo    HostName %INSTANCE_ID%
    echo    Port 22
    echo    User %USER%
    echo    IdentityFile %SECRET_KEY_PATH%
    echo    ProxyCommand C:\Program Files\Amazon\AWSCLIV2\aws.exe ssm start-session --target %%h --document-name AWS-StartSSHSession --parameters "portNumber=%%p"
) >> "%SSH_CONFIG_PATH%"

echo Configuration complete.
endlocal
