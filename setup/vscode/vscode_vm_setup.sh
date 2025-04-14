#!/bin/bash
# prompt for name and email
read -p "Enter your name: " NAME
read -p "Enter your email: " MAIL

# git
git config --global user.name "$NAME"
git config --global user.email "$MAIL"
git config --global core.editor vim

# codecommit credential
git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true

# install vscode extension
## python
code --install-extension ms-python.python
code --install-extension ms-python.vscode-pylance
code --install-extension ms-python.mypy-type-checker
code --install-extension charliermarsh.ruff
code --install-extension donjayamanne.python-extension-pack
## docker
code --install-extension ms-azuretools.vscode-docker
## jupyter
code --install-extension ms-toolsai.jupyter
code --install-extension ms-toolsai.jupyter-keymap
code --install-extension ms-toolsai.jupyter-renderers
## git
code --install-extension mhutchie.git-graph
code --install-extension eamodio.gitlens
code --install-extension donjayamanne.git-extension-pack
## markdown
code --install-extension yzhang.markdown-all-in-one
code --install-extension shd101wyy.markdown-preview-enhanced
code --install-extension esbenp.prettier-vscode
## shell
code --install-extension mads-hartmann.bash-ide-vscode
code --install-extension timonwong.shellcheck
code --install-extension foxundermoon.shell-format
## visibility
code --install-extension mechatroner.rainbow-csv
code --install-extension GrapeCity.gc-excelviewer
code --install-extension janisdd.vscode-edit-csv
code --install-extension monokai.theme-monokai-pro-vscode
code --install-extension vscode-icons-team.vscode-icons
code --install-extension MS-CEINTL.vscode-language-pack-ja
## other
code --install-extension github.copilot
code --install-extension github.copilot-chat
code --install-extension amazonwebservices.aws-toolkit-vscode
code --install-extension amazonwebservices.amazon-q-vscode
code --install-extension saoudrizwan.claude-dev

# vscode settings
cp vscode_settings.json ~/.vscode-server/data/Machine/settings.json

echo finish
