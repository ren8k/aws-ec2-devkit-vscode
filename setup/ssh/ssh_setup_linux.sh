#!/bin/bash

# set variables(cf output)
PARAMETER_ID="key-XXXXXXXXXXXXX"
INSTANCE_ID="i-XXXXXXXXXXXXX"

OUTPUT_FILE="ec2_secret_key.pem"
KEY_PREFIX="/ec2/keypair"
OUTPUT_DIR="${HOME}/Develop/aws/secret"
SSH_CONFIG="${HOME}/.ssh/config"
HOST="ec2"

# get key pair from parameter store and save to file
aws ssm get-parameter --name $KEY_PREFIX/$PARAMETER_ID --with-decryption --query "Parameter.Value" --output text >$OUTPUT_DIR/$OUTPUT_FILE

# change permission
chmod 600 $OUTPUT_DIR/$OUTPUT_FILE

# postscript ssh config
cat <<EOF >>$SSH_CONFIG
host $HOST
    HostName $INSTANCE_ID
    Port 22
    User ubuntu
    IdentityFile $OUTPUT_DIR/$OUTPUT_FILE
    ProxyCommand bash -c "aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'"
EOF

echo "finish"
