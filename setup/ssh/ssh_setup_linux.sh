#!/bin/bash

# Set variables(cf output)
PARAMETER_ID="key-XXXXXXXXXXXXXXXXX"
INSTANCE_ID="i-XXXXXXXXXXXXXXXXX"
SECRET_KEY="ec2_secret_key.pem"
KEY_PREFIX="/ec2/keypair"
SSH_CONFIG="config"
SSH_CONFIG_DIR="${HOME}/.ssh"
SSH_CONFIG_PATH="${SSH_CONFIG_DIR}/${SSH_CONFIG}"
SECRET_KEY_PATH="${SSH_CONFIG_DIR}/${SECRET_KEY}"
HOST="ec2"
USER="ubuntu"

echo "Checking and creating .ssh directory if necessary..."
if [ ! -d $SSH_CONFIG_DIR ]; then
    echo "Creating .ssh directory..."
    mkdir -p $SSH_CONFIG_DIR
    chmod 700 $SSH_CONFIG_DIR
fi

echo "Retrieving and saving the secret key..."
aws ssm get-parameter --name $KEY_PREFIX/$PARAMETER_ID --with-decryption --query "Parameter.Value" --output text >$SECRET_KEY_PATH

echo "Setting permissions for the secret key..."
chmod 600 $SECRET_KEY_PATH

echo "Updating SSH configuration..."
cat <<EOF >>$SSH_CONFIG_PATH
host $HOST
    HostName $INSTANCE_ID
    Port 22
    User $USER
    IdentityFile $SECRET_KEY_PATH
    ProxyCommand bash -c "aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'"
EOF

echo "Configuration complete."
