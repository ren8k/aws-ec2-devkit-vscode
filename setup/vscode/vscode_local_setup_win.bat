@echo off
setlocal enabledelayedexpansion
cd %~dp0

@REM set git credential helper (if you need to clone repos from aws codecommit)
@REM git config --global credential.helper "!aws codecommit credential-helper $@"
@REM git config --global credential.UseHttpPath true

@REM  install vscode extension
code --install-extension ms-vscode-remote.vscode-remote-extensionpack &^
code --install-extension amazonwebservices.aws-toolkit-vscode &^
code --install-extension alefragnani.project-manager &^
code --install-extension pengzhanzhao.ec2-farm
echo finish
