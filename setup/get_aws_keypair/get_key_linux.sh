#!/bin/bash

PARAMETER_ID="key-XXXXXXXXXXXXX"
OUTPUT_FILE="ec2_secret_key.pem"
KEY_PREFIX="/ec2/keypair"
OUTPUT_DIR="${HOME}/Develop/aws/secret"

# get key pair from parameter store and save to file
aws ssm get-parameter --name $KEY_PREFIX/$PARAMETER_ID --with-decryption --query "Parameter.Value" --output text >$OUTPUT_DIR/$OUTPUT_FILE

# change permission
chmod 600 $OUTPUT_DIR/$OUTPUT_FILE

echo finish
